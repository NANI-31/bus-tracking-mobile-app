import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/college_admin/services/college_admin_service.dart';
import 'package:collegebus/features/college_admin/services/college_admin_state.dart';

/// Provider for CollegeAdminService
final collegeAdminServiceProvider = AsyncNotifierProvider<CollegeAdminService, CollegeAdminState>(
  () => CollegeAdminService(),
);
