/// Repository barrel file - exports all repositories for easy importing
library;

export 'base_repository.dart';

// Feature repositories
export 'package:collegebus/features/auth/data/auth_repository.dart';
export 'package:collegebus/features/bus/data/bus_repository.dart';
export 'package:collegebus/features/user/data/user_repository.dart';
export 'package:collegebus/features/college/data/college_repository.dart';
export 'package:collegebus/features/route/data/route_repository.dart';
export 'package:collegebus/features/schedule/data/schedule_repository.dart';
export 'package:collegebus/features/incident/data/incident_repository.dart';
export 'package:collegebus/features/notification/data/notification_repository.dart';
export 'package:collegebus/features/payment/data/payment_repository.dart';

// New Features:
export 'package:collegebus/features/audit/data/audit_repository.dart';
export 'package:collegebus/features/system/data/system_repository.dart';
