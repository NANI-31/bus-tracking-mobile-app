import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService extends ChangeNotifier {
  io.Socket? _socket;
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _currentUrl;
  String? _token;

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String? get token => _token;

  StreamController<Map<String, dynamic>>? _locationUpdateController;
  StreamController<Map<String, dynamic>>? _busUpdateController;
  StreamController<void>? _busListUpdateController;

  Stream<Map<String, dynamic>> get locationUpdateStream =>
      _locationUpdateController?.stream ?? const Stream.empty();
  Stream<Map<String, dynamic>> get busUpdateStream =>
      _busUpdateController?.stream ?? const Stream.empty();
  Stream<void> get busListUpdateStream =>
      _busListUpdateController?.stream ?? const Stream.empty();

  void init(String url, {String? token}) {
    _currentUrl = url;
    _token = token;
    _resetControllers();
    _connect();
  }

  void _resetControllers() {
    _locationUpdateController?.close();
    _busUpdateController?.close();
    _busListUpdateController?.close();

    _locationUpdateController =
        StreamController<Map<String, dynamic>>.broadcast();
    _busUpdateController = StreamController<Map<String, dynamic>>.broadcast();
    _busListUpdateController = StreamController<void>.broadcast();
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
        print('[SocketService] Logged out: Disconnected and cleaned up.');
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
    if (_currentUrl == null) return;
    if (_token == null) {
      if (kDebugMode) {
        print('[SocketService] No token provided. Skipping connection.');
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
    _socket = io.io(_currentUrl, options.build());

    _socket!.onConnect((_) {
      _isConnected = true;
      _isConnecting = false;
      notifyListeners();
      if (kDebugMode) {
        print('[SocketService] Connected');
      }
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      _isConnecting = false;
      notifyListeners();
      if (kDebugMode) {
        print('[SocketService] Disconnected');
      }
    });

    _socket!.onConnectError((err) {
      _isConnecting = false;
      notifyListeners();
      if (kDebugMode) {
        print('[SocketService] Connection Error: $err');
      }
    });

    _socket!.onError((err) {
      _isConnecting = false;
      notifyListeners();
      if (kDebugMode) {
        print('[SocketService] Error: $err');
      }
    });

    // Location updates
    _socket!.on('location_updated', (data) {
      _locationUpdateController?.add(Map<String, dynamic>.from(data));
    });

    // Bus status updates
    _socket!.on('bus_updated', (data) {
      _busUpdateController?.add(Map<String, dynamic>.from(data));
      _busListUpdateController?.add(null);
    });

    // General list updates
    _socket!.on('bus_list_updated', (_) => _busListUpdateController?.add(null));
  }

  void joinCollege(String collegeId) {
    _socket?.emit('join_college', collegeId);
  }

  void updateLocation(Map<String, dynamic> data) {
    _socket?.emit('update_location', data);
  }

  void sendBusListUpdate() {
    _socket?.emit('bus_list_updated');
    _busListUpdateController?.add(null);
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _locationUpdateController?.close();
    _busUpdateController?.close();
    _busListUpdateController?.close();
    super.dispose();
  }
}
