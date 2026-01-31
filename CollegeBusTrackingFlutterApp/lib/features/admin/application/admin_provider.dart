import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/college_admin/services/college_admin_service.dart';
import 'package:collegebus/features/super_admin/services/super_admin_service.dart';
import 'package:collegebus/core/providers/socket_provider.dart';

/// Provider for CollegeAdminService
final collegeAdminServiceProvider = ChangeNotifierProvider<CollegeAdminService>((
  ref,
) {
  // We use ref.read because we only need the instance to subscribe to streams.
  // We DO NOT want to rebuild CollegeAdminService (and lose all data)
  // just because SocketService.isConnected changed (triggered notifyListeners).
  final socket = ref.read(socketServiceProvider);
  return CollegeAdminService(socketService: socket);
});

/// Provider for SuperAdminService
final superAdminServiceProvider = ChangeNotifierProvider<SuperAdminService>((
  ref,
) {
  return SuperAdminService();
});
