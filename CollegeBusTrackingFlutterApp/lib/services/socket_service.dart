import 'package:socket_io_client/socket_io_client.dart' as io_client;
import 'dart:async';
import 'package:flutter/foundation.dart';

class SocketService extends ChangeNotifier {
  io_client.Socket? _socket;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  // Streams for real-time events
  final _locationUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get locationUpdateStream =>
      _locationUpdateController.stream;

  final _busListUpdateController = StreamController<void>.broadcast();
  Stream<void> get busListUpdateStream => _busListUpdateController.stream;

  void init(String baseUrl) {
    if (_socket != null) return;

    debugPrint('Initializing Socket.io with URL: $baseUrl');

    _socket = io_client.io(
      baseUrl,
      io_client.OptionBuilder()
          .setTransports(['websocket', 'polling']) // Enable polling fallback
          .enableAutoConnect()
          .enableForceNew()
          .build(),
    );

    _socket!.onConnect((_) {
      _isConnected = true;
      debugPrint('Socket connected: ${_socket!.id}');
      notifyListeners();
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      debugPrint('Socket disconnected');
      notifyListeners();
    });

    _socket!.onConnectError(
      (data) => debugPrint('Socket connect error: $data'),
    );
    _socket!.onError((data) => debugPrint('Socket error: $data'));

    // Listen for events
    _socket!.on('location_updated', (data) {
      debugPrint('Socket event: location_updated');
      _locationUpdateController.add(data);
    });

    _socket!.on('bus_updated', (_) {
      debugPrint('Socket event: bus_updated');
      _busListUpdateController.add(null);
    });
  }

  void joinCollege(String collegeId) {
    if (_socket == null || !_isConnected) return;
    debugPrint('Joining college room: $collegeId');
    _socket!.emit('join_college', collegeId);
  }

  void updateLocation(Map<String, dynamic> data) {
    if (_socket == null || !_isConnected) return;
    debugPrint('Emitting update_location');
    _socket!.emit('update_location', data);
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _locationUpdateController.close();
    _busListUpdateController.close();
    super.dispose();
  }
}
