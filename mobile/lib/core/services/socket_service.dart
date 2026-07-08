import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collegebus/core/utils/app_logger.dart';

class SocketService extends ChangeNotifier {
  io.Socket? _socket;
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _currentUrl;
  String? _token;
  String? _lastJoinedCollegeId;
  String? _errorMessage;
  final List<Map<String, dynamic>> _eventQueue = [];
  Timer? _heartbeatTimer;

  /// Max number of location events kept in the offline queue.
  /// Older entries are dropped to avoid replaying stale GPS positions.
  static const int _maxLocationQueueSize = 30;

  /// Callback for REST fallback when socket is disconnected
  Future<void> Function(Map<String, dynamic>)? onFallbackUpdate;

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String? get token => _token;
  String? get errorMessage => _errorMessage;

  Stream<Map<String, dynamic>> get locationUpdateStream =>
      _locationUpdateController.stream;
  Stream<Map<String, dynamic>> get busUpdateStream =>
      _busUpdateController.stream;
  Stream<void> get busListUpdateStream => _busListUpdateController.stream;
  Stream<void> get routeListUpdateStream => _routeListUpdateController.stream;
  Stream<void> get userListUpdateStream => _userListUpdateController.stream;
  Stream<Map<String, dynamic>> get driverStatusStream =>
      _driverStatusController.stream;
  Stream<Map<String, dynamic>> get sosAlertStream => _sosAlertController.stream;
  Stream<Map<String, dynamic>> get sosResolvedStream =>
      _sosResolvedController.stream;
  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationController.stream;
  Stream<Map<String, dynamic>> get notificationDeletedStream =>
      _notificationDeletedController.stream;
  Stream<Map<String, dynamic>> get notificationReadStream =>
      _notificationReadController.stream;
  Stream<Map<String, dynamic>> get notificationReadAllStream =>
      _notificationReadAllController.stream;
  Stream<String?> get errorStream => _errorController.stream;
  Stream<Map<String, dynamic>> get newAuditLogStream =>
      _newAuditLogController.stream;
  /// Fired when the driver arrives within 50 m of a route stop point.
  /// Payload: { busId, collegeId, stopId, stopName, timestamp }
  Stream<Map<String, dynamic>> get stopReachedStream =>
      _stopReachedController.stream;

  SocketService() {
    _locationUpdateController =
        StreamController<Map<String, dynamic>>.broadcast();
    _busUpdateController = StreamController<Map<String, dynamic>>.broadcast();
    _busListUpdateController = StreamController<void>.broadcast();
    _routeListUpdateController = StreamController<void>.broadcast();
    _userListUpdateController = StreamController<void>.broadcast();
    _driverStatusController =
        StreamController<Map<String, dynamic>>.broadcast();
    _sosAlertController = StreamController<Map<String, dynamic>>.broadcast();
    _sosResolvedController = StreamController<Map<String, dynamic>>.broadcast();
    _notificationController =
        StreamController<Map<String, dynamic>>.broadcast();
    _notificationDeletedController =
        StreamController<Map<String, dynamic>>.broadcast();
    _notificationReadController =
        StreamController<Map<String, dynamic>>.broadcast();
    _notificationReadAllController =
        StreamController<Map<String, dynamic>>.broadcast();
    _errorController = StreamController<String?>.broadcast();
    _newAuditLogController =
        StreamController<Map<String, dynamic>>.broadcast();
    _stopReachedController =
        StreamController<Map<String, dynamic>>.broadcast();
  }

  late final StreamController<Map<String, dynamic>> _locationUpdateController;
  late final StreamController<Map<String, dynamic>> _busUpdateController;
  late final StreamController<void> _busListUpdateController;
  late final StreamController<void> _routeListUpdateController;
  late final StreamController<void> _userListUpdateController;
  late final StreamController<Map<String, dynamic>> _driverStatusController;
  late final StreamController<Map<String, dynamic>> _sosAlertController;
  late final StreamController<Map<String, dynamic>> _sosResolvedController;
  late final StreamController<Map<String, dynamic>> _notificationController;
  late final StreamController<Map<String, dynamic>>
  _notificationDeletedController;
  late final StreamController<Map<String, dynamic>> _notificationReadController;
  late final StreamController<Map<String, dynamic>>
  _notificationReadAllController;
  late final StreamController<String?> _errorController;
  late final StreamController<Map<String, dynamic>> _newAuditLogController;
  late final StreamController<Map<String, dynamic>> _stopReachedController;

  Future<void> init(String url, {String? token}) async {
    _currentUrl = url;
    _token = token;
    await _loadQueue();
    _connect();
  }

  void updateAuth(String? token, {String? url}) {
    if (_token == token) return;
    _token = token;

    if (_token == null) {
      // User logged out, just disconnect
      _socket?.disconnect();
      _socket?.dispose();
      _socket = null;
      _isConnected = false;
      _isConnecting = false;
      _errorMessage = null;
      _errorController.add(null);
      notifyListeners();
      if (kDebugMode) {
        AppLogger.i('[SocketService] Logged out: Disconnected and cleaned up.');
      }
    } else {
      if (_currentUrl == null && url != null) {
        init(url, token: token);
      } else {
        _reconnect();
      }
    }
  }

  void _reconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _connect();
  }

  /// Proactively ensures the socket is connected and in the correct room.
  /// Called when app resumes from background.
  void ensureConnected() {
    if (_socket == null || !_socket!.connected) {
      AppLogger.i(
        '[SocketService] ensureConnected: Socket is null or disconnected, recreating socket...',
      );
      _reconnect();
    } else {
      AppLogger.d('[SocketService] ensureConnected: Socket already connected.');
      // Re-emit join_college just in case the server lost our session/room membership
      if (_lastJoinedCollegeId != null) {
        joinCollege(_lastJoinedCollegeId!);
      }
    }
  }

  void _connect() {
    AppLogger.d(
      '[SocketService] _connect called. CurrentUrl: $_currentUrl, Token: $_token',
    );

    if (_currentUrl == null) return;
    if (_token == null) {
      if (kDebugMode) {
        AppLogger.w('[SocketService] No token provided. Skipping connection.');
      }
      return;
    }

    final options = io.OptionBuilder()
        .setTransports(['websocket', 'polling'])
        .enableAutoConnect()
        .setReconnectionDelay(2000); // 2s wait between retries (infinite attempts by default)

    if (_token != null) {
      options.setAuth({'token': _token});
    }

    _isConnecting = true;
    notifyListeners();
    AppLogger.i('[SocketService] Attempting to connect to $_currentUrl...');
    _socket = io.io(_currentUrl, options.build());

    _socket!.onConnect((_) async {
      _isConnected = true;
      _isConnecting = false;
      _errorMessage = null;
      _errorController.add(null);
      notifyListeners();
      AppLogger.i('[SocketService] Connected successfully to $_currentUrl');

      // Re-join last college if any
      if (_lastJoinedCollegeId != null) {
        joinCollege(_lastJoinedCollegeId!);
      }

      // Start heartbeat to keep WebSocket alive through Android Doze mode.
      // Without this, the OS drops idle sockets in ~30-60s when screen is off.
      _startHeartbeat();

      await _flushQueue();
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      _isConnecting = false;
      _stopHeartbeat();
      notifyListeners();
      AppLogger.w('[SocketService] Disconnected');
    });

    // Handle reconnection (fired when socket reconnects after a disconnect)
    _socket!.on('reconnect', (_) async {
      _isConnected = true;
      _isConnecting = false;
      _errorMessage = null;
      _errorController.add(null);
      notifyListeners();
      AppLogger.i('[SocketService] Reconnected successfully');

      // Re-join last college if any
      if (_lastJoinedCollegeId != null) {
        joinCollege(_lastJoinedCollegeId!);
      }

      // Trigger list update notifications so providers refetch fresh data
      _busListUpdateController.add(null);
      _routeListUpdateController.add(null);
      _userListUpdateController.add(null);

      await _flushQueue();
    });

    // Handle reconnecting state
    _socket!.on('reconnecting', (_) {
      _isConnecting = true;
      _isConnected = false;
      _errorMessage = 'Reconnecting to server...';
      _errorController.add(_errorMessage);
      notifyListeners();
      AppLogger.i('[SocketService] Reconnecting...');
    });

    _socket!.on('reconnect_attempt', (attempt) {
      _errorMessage = 'Connection lost. Reconnecting (Attempt $attempt)...';
      _errorController.add(_errorMessage);
      notifyListeners();
    });

    _socket!.on('reconnect_failed', (_) {
      _isConnecting = false;
      _errorMessage = 'Failed to reconnect. Please check your internet.';
      _errorController.add(_errorMessage);
      notifyListeners();
      AppLogger.e('[SocketService] Reconnection failed');
    });

    _socket!.onConnectError((err) {
      if (_isConnecting) {
        _isConnecting = false;
      }
      _errorMessage = 'Unable to connect to server.';
      _errorController.add(_errorMessage);
      notifyListeners();
      AppLogger.e('[SocketService] Connection Error: $err');
    });

    _socket!.onError((err) {
      if (_isConnecting) {
        _isConnecting = false;
      }
      _errorMessage = 'Socket communication error.';
      _errorController.add(_errorMessage);
      notifyListeners();
      AppLogger.e('[SocketService] Error: $err');
    });

    // Location updates
    _socket!.on('location_updated', (data) {
      AppLogger.v('[SocketService] Received location_updated: $data');
      _locationUpdateController.add(Map<String, dynamic>.from(data));
    });

    // Bus status updates
    _socket!.on('bus_updated', (data) {
      AppLogger.i('[SocketService] Received bus_updated: $data');
      _busUpdateController.add(Map<String, dynamic>.from(data));
      _busListUpdateController.add(null);
    });

    // Driver status updates
    _socket!.on('driver_status_update', (data) {
      AppLogger.i('[SocketService] Received driver_status_update: $data');
      _driverStatusController.add(Map<String, dynamic>.from(data));
    });

    // General list updates
    _socket!.on('bus_list_updated', (_) => _busListUpdateController.add(null));
    _socket!.on(
      'route_list_updated',
      (_) => _routeListUpdateController.add(null),
    );
    _socket!.on(
      'user_list_updated',
      (_) => _userListUpdateController.add(null),
    );

    _socket!.on('sos_room_joined', (data) {
      AppLogger.i('[SocketService] JOINED SOS ROOM: $data');
    });

    _socket!.on('sos_alert', (data) {
      AppLogger.e('[SocketService] RECEIVED SOS ALERT: $data');
      _sosAlertController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('sos_resolved', (data) {
      AppLogger.i('[SocketService] SOS RESOLVED: $data');
      _sosResolvedController.add(Map<String, dynamic>.from(data));
    });

    // Notification updates
    _socket!.on('notification_received', (data) {
      AppLogger.i('[SocketService] Received notification_received: $data');
      _notificationController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('notification_deleted', (data) {
      AppLogger.i('[SocketService] Received notification_deleted: $data');
      _notificationDeletedController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('notification_read', (data) {
      AppLogger.i('[SocketService] Received notification_read: $data');
      _notificationReadController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('notifications_read_all', (data) {
      AppLogger.i('[SocketService] Received notifications_read_all: $data');
      _notificationReadAllController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('new_audit_log', (data) {
      AppLogger.i('[SocketService] Received new_audit_log: $data');
      _newAuditLogController.add(Map<String, dynamic>.from(data));
    });

    // Stop arrival: server broadcasts this to all students in the college room
    // when the driver emits 'stop_reached'.
    _socket!.on('stop_reached', (data) {
      AppLogger.i('[SocketService] Received stop_reached: $data');
      _stopReachedController.add(Map<String, dynamic>.from(data));
    });
  }

  void joinCollege(String collegeId) {
    _lastJoinedCollegeId = collegeId;
    if (_isConnected && _socket != null) {
      AppLogger.i('[SocketService] Emitting join_college: $collegeId');
      _socket?.emit('join_college', collegeId);
    } else {
      AppLogger.w('[SocketService] Queueing join_college: $collegeId');
      _queueEvent('join_college', collegeId);
    }
  }

  Future<void> updateLocation(Map<String, dynamic> data) async {
    AppLogger.v('[SocketService] update_location attempt: $data');
    if (_isConnected && _socket != null) {
      _socket?.emit('update_location', data);
    } else {
      AppLogger.w(
        '[SocketService] Socket disconnected, using REST fallback and queueing',
      );

      // Trigger REST fallback if available
      if (onFallbackUpdate != null) {
        try {
          await onFallbackUpdate!(data);
          AppLogger.i(
            '[SocketService] REST fallback location update successful',
          );
        } catch (e) {
          AppLogger.e('[SocketService] REST fallback failed: $e');
        }
      }

      // Cap location queue: only keep the most recent updates to avoid
      // replaying a long trail of stale GPS positions when reconnecting.
      final locationEvents = _eventQueue
          .where((e) => e['event'] == 'update_location')
          .length;
      if (locationEvents >= _maxLocationQueueSize) {
        // Remove the oldest location event to make room
        final idx = _eventQueue.indexWhere((e) => e['event'] == 'update_location');
        if (idx != -1) _eventQueue.removeAt(idx);
      }

      await _queueEvent('update_location', data);
    }
  }

  void triggerSos(Map<String, dynamic> data) {
    AppLogger.e('[SocketService] EMITTING TRIGGER SOS: $data');
    if (_isConnected && _socket != null) {
      _socket?.emit('trigger_sos', data);
    } else {
      _queueEvent('trigger_sos', data);
    }
  }

  void resolveSos(String sosId) {
    AppLogger.i('[SocketService] EMITTING RESOLVE SOS: $sosId');
    if (_isConnected && _socket != null) {
      _socket?.emit('resolve_sos', {'sos_id': sosId});
    } else {
      _queueEvent('resolve_sos', {'sos_id': sosId});
    }
  }

  /// Emits a stop_reached event to the server. The server should broadcast this
  /// to students in the same college room so they receive a real-time
  /// notification when the bus arrives at their stop.
  ///
  /// Not queued — stale stop-arrival events are meaningless once reconnected.
  void emitStopReached(Map<String, dynamic> data) {
    AppLogger.i('[SocketService] EMITTING stop_reached: $data');
    if (_isConnected && _socket != null) {
      _socket?.emit('stop_reached', data);
    } else {
      AppLogger.w('[SocketService] stop_reached not queued (stale on reconnect): $data');
    }
  }

  Future<void> _queueEvent(String event, dynamic data) async {
    _eventQueue.add({'event': event, 'data': data});
    await _saveQueue();
    if (kDebugMode) {
      AppLogger.d('[SocketService] Event queued: $event');
    }
  }

  Future<void> _saveQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('offline_socket_queue', json.encode(_eventQueue));
  }

  Future<void> _loadQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final queueString = prefs.getString('offline_socket_queue');
    if (queueString != null) {
      try {
        final List<dynamic> decoded = json.decode(queueString);
        _eventQueue.clear();
        _eventQueue.addAll(decoded.cast<Map<String, dynamic>>());
      } catch (e) {
        AppLogger.e('Error loading queue: $e');
      }
    }
  }

  /// Starts a 25-second ping timer to keep the WebSocket connection alive
  /// when the app is backgrounded (screen off). Android Doze mode drops idle
  /// sockets after ~30-60 seconds without activity.
  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (_isConnected && _socket != null) {
        _socket!.emit('ping');
        AppLogger.v('[SocketService] Heartbeat ping sent');
      } else {
        _stopHeartbeat();
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<void> _flushQueue() async {
    if (_eventQueue.isEmpty) return;
    if (kDebugMode) {
      AppLogger.i(
        '[SocketService] Flushing queue: ${_eventQueue.length} events',
      );
    }

    // Create a copy to iterate
    final queueCopy = List<Map<String, dynamic>>.from(_eventQueue);
    _eventQueue.clear(); // Optimistically clear
    await _saveQueue();

    for (final item in queueCopy) {
      _socket?.emit(item['event'], item['data']);
      // Small delay to prevent flooding
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  void sendBusListUpdate() {
    _socket?.emit('bus_list_updated');
    _busListUpdateController.add(null);
  }

  void sendRouteListUpdate() {
    _socket?.emit('route_list_updated');
    _routeListUpdateController.add(null);
  }

  void sendUserListUpdate() {
    _socket?.emit('user_list_updated');
    _userListUpdateController.add(null);
  }

  @override
  void dispose() {
    _stopHeartbeat();
    _socket?.disconnect();
    _socket?.dispose();
    _locationUpdateController.close();
    _busUpdateController.close();
    _busListUpdateController.close();
    _routeListUpdateController.close();
    _userListUpdateController.close();
    _driverStatusController.close();
    _sosAlertController.close();
    _sosResolvedController.close();
    _notificationController.close();
    _errorController.close();
    _newAuditLogController.close();
    _stopReachedController.close();
    super.dispose();
  }
}
