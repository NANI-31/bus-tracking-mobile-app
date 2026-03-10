import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/core/data/repositories.dart';

// Re-export specific providers already defined in feature folders if any,
// but for now, we define them here for central access to avoid circular imports
// between application providers and legacy ApiService.

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);
final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(),
);
final busRepositoryProvider = Provider<BusRepository>((ref) => BusRepository());
final routeRepositoryProvider = Provider<RouteRepository>(
  (ref) => RouteRepository(),
);
final scheduleRepositoryProvider = Provider<ScheduleRepository>(
  (ref) => ScheduleRepository(),
);
final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(),
);
final collegeRepositoryProvider = Provider<CollegeRepository>(
  (ref) => CollegeRepository(),
);
final incidentRepositoryProvider = Provider<IncidentRepository>(
  (ref) => IncidentRepository(),
);
final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => PaymentRepository(),
);

// New Feature Repositories
final auditRepositoryProvider = Provider<AuditRepository>(
  (ref) => AuditRepository(),
);
final systemRepositoryProvider = Provider<SystemRepository>(
  (ref) => SystemRepository(),
);
