import 'package:collegebus/features/student/presentation/student_bus_stop_screen.dart';
import 'package:collegebus/features/student/presentation/student_home_screen.dart';
import 'package:collegebus/shared/screens/splash_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:go_router/go_router.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/features/auth/presentation/screens/login_screen.dart';
import 'package:collegebus/features/auth/presentation/screens/register_screen.dart';

import 'package:collegebus/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:collegebus/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:collegebus/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:collegebus/features/student/presentation/student_dashboard.dart';
import 'package:collegebus/features/student/presentation/bus_schedule_screen.dart';
import 'package:collegebus/features/driver/presentation/driver_dashboard.dart';
import 'package:collegebus/features/coordinator/presentation/coordinator_dashboard.dart';
import 'package:collegebus/features/coordinator/presentation/schedule_management_screen.dart';
import 'package:collegebus/features/college_admin/presentation/college_admin_dashboard.dart';
import 'package:collegebus/features/super_admin/presentation/super_admin_dashboard.dart';
import 'package:collegebus/features/super_admin/presentation/screens/college_details_screen.dart';
import 'package:collegebus/features/user/presentation/screens/profile_screen.dart';
import 'package:collegebus/features/student/presentation/student_change_password_screen.dart';
import 'package:collegebus/features/user/presentation/screens/language_selection_screen.dart';
import 'package:collegebus/shared/screens/privacy_policy_screen.dart';
import 'package:collegebus/shared/screens/terms_conditions_screen.dart';
import 'package:collegebus/features/notification/presentation/screens/notifications_screen.dart';
import 'package:collegebus/features/user/presentation/screens/referral_screen.dart';
import 'package:collegebus/features/user/presentation/screens/edit_profile_screen.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/features/coordinator/presentation/driver_selection_screen.dart';
import 'package:collegebus/features/coordinator/presentation/assignment_history_screen.dart';
import 'package:collegebus/features/coordinator/presentation/modules/edit_bus_screen.dart';
import 'package:collegebus/features/coordinator/presentation/modules/edit_driver_screen.dart';
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:collegebus/features/user/domain/user_model.dart';
import 'package:collegebus/features/college/domain/college_model.dart';

final routerProvider = riverpod.Provider<GoRouter>((ref) {
  // Simple notifier to trigger router refresh on auth state changes
  final notifier = SimpleNotifier();

  // Dispose notifier when provider is disposed
  ref.onDispose(notifier.dispose);

  // Listen to auth provider changes
  ref.listen(authProvider, (_, __) {
    notifier.notify();
  });

  return GoRouter(
    refreshListenable: notifier,
    initialLocation: '/',
    redirect: (context, state) {
      // Read the current auth state directly
      final authState = ref.read(authProvider);

      debugPrint('ROUTER Redirect: Location=${state.matchedLocation}');
      debugPrint(
        'ROUTER Auth State: isLoading=${authState.isLoading}, hasError=${authState.hasError}, value=${authState.value}',
      );

      // 1. Loading State
      if (authState.isLoading) {
        debugPrint('ROUTER: Auth is loading, staying on Splash');
        // Return null (stay on splash) or a loading route if strict
        return null;
      }

      // 2. Error State (Treat as not logged in or handle gracefully)
      if (authState.hasError) {
        debugPrint('ROUTER: Auth has error, redirecting to /login');
        return '/login';
      }

      final hasUser = authState.value?.currentUser != null;
      // We also verify token persistence for edge cases
      // but rely primarily on the state

      final isLoginRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation.startsWith(
            '/register',
          ) || // Handle sub-routes/params
          state.matchedLocation == '/forgot-password' ||
          state.matchedLocation == '/otp-verify' ||
          state.matchedLocation.startsWith('/reset-password');

      final isRootRoute = state.matchedLocation == '/';

      // 3. Not Logged In -> Redirect to Login
      if (!hasUser && !isLoginRoute) {
        debugPrint('ROUTER: User not logged in, redirecting to /login');
        return '/login';
      }

      // 4. Logged In -> Redirect to Dashboard (if on login/root)
      if (hasUser && (isLoginRoute || isRootRoute)) {
        final userRole = authState.value?.currentUser?.role;
        debugPrint(
          'ROUTER: User logged in ($userRole), redirecting to dashboard',
        );
        switch (userRole) {
          case UserRole.student:
          case UserRole.parent:
          case UserRole.teacher:
            return '/student';
          case UserRole.driver:
            return '/driver';
          case UserRole.busCoordinator:
            return '/coordinator';
          case UserRole.collegeAdmin:
            return '/college-admin';
          case UserRole.superAdmin:
            return '/super-admin';
          default:
            return '/student'; // Fallback
        }
      }

      return null; // No redirect needed
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/otp-verify',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>? ?? {};
          return OtpVerificationScreen(
            email: extras['email'] as String? ?? '',
            isResetPassword: extras['isResetPassword'] as bool? ?? false,
          );
        },
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return ResetPasswordScreen(email: email);
        },
      ),

      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/privacy-policy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/terms-conditions',
        builder: (context, state) => const TermsConditionsScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) => const EditProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/referral',
        builder: (context, state) => const ReferralScreen(),
      ),

      GoRoute(
        path: '/student',
        builder: (context, state) => const StudentDashboard(),
        routes: [
          GoRoute(
            path: 'home',
            builder: (context, state) => const StudentHomeScreen(),
          ),
          GoRoute(
            path: 'schedule',
            builder: (context, state) => const BusScheduleScreen(),
          ),
          GoRoute(
            path: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: 'change-password',
            builder: (context, state) => const StudentChangePasswordScreen(),
          ),
          GoRoute(
            path: 'privacy-policy',
            builder: (context, state) => const PrivacyPolicyScreen(),
          ),
          GoRoute(
            path: 'terms-conditions',
            builder: (context, state) => const TermsConditionsScreen(),
          ),
          GoRoute(
            path: 'bus-stop',
            builder: (context, state) => const StudentBusStopScreen(),
          ),
          GoRoute(
            path: 'language',
            builder: (context, state) => const LanguageSelectionScreen(),
          ),
          GoRoute(
            path: 'edit-profile',
            builder: (context, state) => const EditProfileScreen(),
          ),
        ],
      ),

      GoRoute(
        path: '/driver',
        builder: (context, state) => const DriverDashboard(),
      ),
      GoRoute(
        path: '/coordinator',
        builder: (context, state) => const CoordinatorDashboard(),
        routes: [
          GoRoute(
            path: 'schedule',
            builder: (context, state) => const ScheduleManagementScreen(),
          ),
          GoRoute(
            path: 'assign-driver/:busNumber',
            builder: (context, state) {
              final busNumber = state.pathParameters['busNumber']!;
              return DriverSelectionScreen(busNumber: busNumber);
            },
          ),
          GoRoute(
            path: 'assignment-history/:busId/:busNumber',
            builder: (context, state) {
              final busId = state.pathParameters['busId']!;
              final busNumber = state.pathParameters['busNumber']!;
              return AssignmentHistoryScreen(
                busId: busId,
                busNumber: busNumber,
              );
            },
          ),
          GoRoute(
            path: 'edit-bus/:busNumber',
            builder: (context, state) {
              final busNumber = state.pathParameters['busNumber']!;
              final bus = state.extra as BusModel?;
              final isBusEditable =
                  state.uri.queryParameters['editable'] != 'false';
              return EditBusScreen(
                busNumber: busNumber,
                bus: bus,
                isBusEditable: isBusEditable,
              );
            },
          ),
          GoRoute(
            path: 'edit-driver/:driverId',
            builder: (context, state) {
              final driverId = state.pathParameters['driverId']!;
              final driver = state.extra as UserModel?;
              return EditDriverScreen(driverId: driverId, driver: driver);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/college-admin',
        builder: (context, state) => const CollegeAdminDashboard(),
      ),
      GoRoute(
        path: '/super-admin',
        builder: (context, state) => const SuperAdminDashboard(),
        routes: [
          GoRoute(
            path: 'colleges/:id',
            builder: (context, state) {
              final collegeId = state.pathParameters['id']!;
              final college = state.extra as CollegeModel?;
              return CollegeDetailsScreen(
                collegeId: collegeId,
                college: college,
              );
            },
          ),
          GoRoute(
            path: 'buses/:busNumber',
            builder: (context, state) {
              final busNumber = state.pathParameters['busNumber']!;
              final bus = state.extra as BusModel?;
              final isBusEditable = state.uri.queryParameters['editable'] != 'false';
              return EditBusScreen(
                busNumber: busNumber,
                bus: bus,
                isBusEditable: isBusEditable,
              );
            },
          ),
          GoRoute(
            path: 'drivers/:driverId',
            builder: (context, state) {
              final driverId = state.pathParameters['driverId']!;
              final driver = state.extra as UserModel?;
              return EditDriverScreen(driverId: driverId, driver: driver);
            },
          ),
          GoRoute(
            path: 'schedules',
            builder: (context, state) {
              return const ScheduleManagementScreen();
            },
          ),
        ],
      ),
    ],
  );
});

class SimpleNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}
