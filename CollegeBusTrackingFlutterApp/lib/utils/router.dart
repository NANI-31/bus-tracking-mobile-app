import 'package:collegebus/screens/student/student_bus_stop_screen.dart';
import 'package:collegebus/screens/student/student_home_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/auth/login_screen.dart';
import 'package:collegebus/auth/register_screen.dart';

import 'package:collegebus/auth/forgot_password_screen.dart';
import 'package:collegebus/auth/otp_verification_screen.dart';
import 'package:collegebus/auth/reset_password_screen.dart';
import 'package:collegebus/screens/student/student_dashboard.dart';
import 'package:collegebus/screens/student/bus_schedule_screen.dart';
// import 'package:collegebus/screens/teacher/teacher_dashboard.dart'; // Removed
import 'package:collegebus/screens/driver/driver_dashboard.dart';
import 'package:collegebus/screens/coordinator/coordinator_dashboard.dart';
import 'package:collegebus/screens/coordinator/schedule_management_screen.dart';
import 'package:collegebus/screens/admin/admin_dashboard.dart';
import 'package:collegebus/screens/student/student_profile_screen.dart';
import 'package:collegebus/screens/student/student_change_password_screen.dart';
import 'package:collegebus/screens/common/privacy_policy_screen.dart';
import 'package:collegebus/screens/common/terms_conditions_screen.dart';
import 'package:collegebus/screens/common/notifications/notifications_screen.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:collegebus/screens/coordinator/driver_selection_screen.dart';
import 'package:collegebus/screens/coordinator/assignment_history_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final authService = Provider.of<AuthService>(context, listen: false);

      // If auth service is still initializing, don't redirect yet
      if (!authService.isInitialized) {
        return null;
      }

      final isLoggedIn = authService.currentUserModel != null;
      final isLoginRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password' ||
          state.matchedLocation == '/otp-verify' ||
          state.matchedLocation.startsWith('/reset-password');

      if (!isLoggedIn && !isLoginRoute) {
        return '/login';
      }

      if (isLoggedIn && isLoginRoute) {
        // Redirect to appropriate dashboard based on user role
        final userRole = authService.userRole;
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
          default:
            return null;
        }
      }

      return null;
    },
    routes: [
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
          final extras = state.extra as Map<String, dynamic>;
          return OtpVerificationScreen(
            email: extras['email'] as String,
            isResetPassword: extras['isResetPassword'] as bool,
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
            builder: (context, state) => const StudentProfileScreen(),
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
      /*
      GoRoute(
        path: '/teacher',
        builder: (context, state) => const TeacherDashboard(),
      ),
      */
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
        ],
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboard(),
      ),
    ],
  );
}
