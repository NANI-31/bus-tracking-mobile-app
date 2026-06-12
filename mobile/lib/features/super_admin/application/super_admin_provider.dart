import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/super_admin/services/super_admin_service.dart';
import 'package:collegebus/features/super_admin/services/super_admin_state.dart';

/// Provider for SuperAdminService
final superAdminServiceProvider = AsyncNotifierProvider<SuperAdminService, SuperAdminState>(
  () => SuperAdminService(),
);
