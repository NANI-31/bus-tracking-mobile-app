import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/services/api/socket_service.dart';
import 'package:collegebus/utils/constants.dart';
import 'auth_provider.dart';

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

  return socketService;
});
