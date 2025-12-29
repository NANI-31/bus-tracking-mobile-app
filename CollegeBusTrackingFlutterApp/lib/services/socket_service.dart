import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collegebus/utils/app_logger.dart';

class SocketService extends ChangeNotifier {
  io.Socket? _socket;
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _currentUrl;
  String? _token;
  String? _lastJoinedCollegeId;
  final List<Map<String, dynamic>> _eventQueue = [];

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String? get token => _token;

  Stream<Map<String, dynamic>> get locationUpdateStream =>
      _locationUpdateController.stream;
  Stream<Map<String, dynamic>> get busUpdateStream =>
      _busUpdateController.stream;
  Stream<void> get busListUpdateStream => _busListUpdateController.stream;
  Stream<Map<String, dynamic>> get driverStatusStream =>
      _driverStatusController.stream;

  SocketService() {
    _locationUpdateController =
        StreamController<Map<String, dynamic>>.broadcast();
    _busUpdateController = StreamController<Map<String, dynamic>>.broadcast();
    _busListUpdateController = StreamController<void>.broadcast();
    _driverStatusController =
        StreamController<Map<String, dynamic>>.broadcast();
  }

  late final StreamController<Map<String, dynamic>> _locationUpdateController;
  late final StreamController<Map<String, dynamic>> _busUpdateController;
  late final StreamController<void> _busListUpdateController;
  late final StreamController<Map<String, dynamic>> _driverStatusController;

  Future<void> init(String url, {String? token}) async {
    _currentUrl = url;
    _token = token;
    await _loadQueue();
    _connect();
  }

  void updateAuth(String? token) {
    if (_token == token) return;
    _token = token;

    if (_token == null) {
      // User logged out, just disconnect
      _socket?.disconnect();
      _socket?.dispose();
      _socket = null;
      _isConnected = false;
      _isConnecting = false;
      notifyListeners();
      if (kDebugMode) {
        AppLogger.i('[SocketService] Logged out: Disconnected and cleaned up.');
      }
    } else {
      _reconnect();
    }
  }

  void _reconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _connect();
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
        .setReconnectionAttempts(10)
        .setReconnectionDelay(5000);

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
      notifyListeners();
      AppLogger.i('[SocketService] Connected successfully to $_currentUrl');

      // Re-join last college if any
      if (_lastJoinedCollegeId != null) {
        joinCollege(_lastJoinedCollegeId!);
      }

      await _flushQueue();
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      _isConnecting = false;
      notifyListeners();
      AppLogger.w('[SocketService] Disconnected');
    });

    _socket!.onConnectError((err) {
      _isConnecting = false;
      notifyListeners();
      AppLogger.e('[SocketService] Connection Error: $err');
    });

    _socket!.onError((err) {
      _isConnecting = false;
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
    AppLogger.v('[SocketService] Emitting update_location: $data');
    if (_isConnected && _socket != null) {
      _socket?.emit('update_location', data);
    } else {
      AppLogger.w(
        '[SocketService] Socket not connected, queueing update_location',
      );
      await _queueEvent('update_location', data);
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

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _locationUpdateController.close();
    _busUpdateController.close();
    _busListUpdateController.close();
    _driverStatusController.close();
    super.dispose();
  }
}
