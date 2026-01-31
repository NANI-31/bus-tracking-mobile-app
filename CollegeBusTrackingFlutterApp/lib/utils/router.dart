import 'package:collegebus/screens/student/student_bus_stop_screen.dart';
import 'package:collegebus/screens/student/student_home_screen.dart';
import 'package:collegebus/screens/splash_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:go_router/go_router.dart';
import 'package:collegebus/providers/auth_provider.dart';
import 'package:collegebus/auth/login_screen.dart';
import 'package:collegebus/auth/register_screen.dart';

import 'package:collegebus/auth/forgot_password_screen.dart';
import 'package:collegebus/auth/otp_verification_screen.dart';
import 'package:collegebus/auth/reset_password_screen.dart';
import 'package:collegebus/screens/student/student_dashboard.dart';
import 'package:collegebus/screens/student/bus_schedule_screen.dart';
import 'package:collegebus/screens/driver/driver_dashboard.dart';
import 'package:collegebus/screens/coordinator/coordinator_dashboard.dart';
import 'package:collegebus/screens/coordinator/schedule_management_screen.dart';
import 'package:collegebus/screens/admin/admin_dashboard.dart';
import 'package:collegebus/screens/college_admin/college_admin_dashboard.dart';
import 'package:collegebus/screens/super_admin/super_admin_dashboard.dart';
import 'package:collegebus/screens/common/profile_screen.dart';
import 'package:collegebus/screens/student/student_change_password_screen.dart';
import 'package:collegebus/screens/common/privacy_policy_screen.dart';
import 'package:collegebus/screens/common/terms_conditions_screen.dart';
import 'package:collegebus/screens/common/notifications/notifications_screen.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:collegebus/screens/coordinator/driver_selection_screen.dart';
import 'package:collegebus/screens/coordinator/assignment_history_screen.dart';
import 'package:collegebus/screens/coordinator/modules/edit_bus_screen.dart';
import 'package:collegebus/models/bus_model.dart';

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
            return '/student/home';
          case UserRole.driver:
            return '/driver';
          case UserRole.busCoordinator:
            return '/coordinator';
          case UserRole.admin:
            return '/admin';
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
              return EditBusScreen(busNumber: busNumber, bus: bus);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboard(),
      ),
      GoRoute(
        path: '/college-admin',
        builder: (context, state) => const CollegeAdminDashboard(),
      ),
      GoRoute(
        path: '/super-admin',
        builder: (context, state) => const SuperAdminDashboard(),
      ),
    ],
  );
});

class SimpleNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}
