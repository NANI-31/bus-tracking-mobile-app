import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/core/services/socket_service.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/core/providers/api_provider.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';

/// SocketService provider - depends on auth token for initialization
final socketServiceProvider = ChangeNotifierProvider<SocketService>((ref) {
  final socketService = SocketService();

  // Initial setup: read current token without watching
  final token = ref.read(authProvider).value?.token;
  if (token != null) {
    socketService.init(AppConstants.baseUrl, token: token);
  }

  // Listen for token changes to update connection
  // We specify fireImmediately: false because we handled initial state above
  ref.listen(authProvider.select((state) => state.value?.token), (
    previous,
    next,
  ) {
    if (previous != next) {
      socketService.updateAuth(next);
    }
  });

  // Inject HTTP Fallback
  socketService.onFallbackUpdate = (data) async {
    final api = ref.read(apiServiceProvider);
    final busId = data['busId'] as String;
    final location = data['location'] as Map<String, dynamic>;
    final lat = location['lat'] as double;
    final lng = location['lng'] as double;
    final speed = (data['speed'] ?? 0.0) as double;
    final heading = (data['heading'] ?? 0.0) as double;

    await api.updateBusLocation(busId, lat, lng, speed, heading);
  };

  return socketService;
});
