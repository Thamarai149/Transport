import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/student/presentation/screens/student_dashboard.dart';
import '../../features/student/presentation/screens/bus_tracking_screen.dart';
import '../../features/driver/presentation/screens/driver_dashboard.dart';
import '../../features/admin/presentation/screens/admin_dashboard.dart';
import '../../features/admin/presentation/screens/manage_routes_screen.dart';
import '../../features/admin/presentation/screens/manage_buses_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  redirect: (BuildContext context, GoRouterState state) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final isLoggingIn = state.matchedLocation == '/login';
    final isRegistering = state.matchedLocation == '/register';

    if (token == null) {
      if (!isLoggingIn && !isRegistering) {
        return '/login';
      }
    } else {
      if (isLoggingIn || isRegistering) {
        final role = prefs.getString('user_role');
        if (role == 'Student') {
          return '/student-dashboard';
        } else if (role == 'Driver') {
          return '/driver-dashboard';
        } else if (role == 'Transport Admin' || role == 'Super Admin') {
          return '/admin-dashboard';
        }
        return '/student-dashboard';
      }
    }
    return null;
  },
  routes: <RouteBase>[
    GoRoute(
      path: '/login',
      builder: (BuildContext context, GoRouterState state) {
        return const LoginScreen();
      },
    ),
    GoRoute(
      path: '/register',
      builder: (BuildContext context, GoRouterState state) {
        return const RegisterScreen();
      },
    ),
    // Role-based dashboards
    GoRoute(
      path: '/student-dashboard',
      builder: (BuildContext context, GoRouterState state) {
        return const StudentDashboardScreen();
      },
    ),
    GoRoute(
      path: '/bus-tracking',
      builder: (BuildContext context, GoRouterState state) {
        return const BusTrackingScreen();
      },
    ),
    GoRoute(
      path: '/driver-dashboard',
      builder: (BuildContext context, GoRouterState state) {
        return const DriverDashboardScreen();
      },
    ),
    GoRoute(
      path: '/admin-dashboard',
      builder: (BuildContext context, GoRouterState state) {
        return const AdminDashboardScreen();
      },
    ),
    GoRoute(
      path: '/manage-routes',
      builder: (BuildContext context, GoRouterState state) {
        return const ManageRoutesScreen();
      },
    ),
    GoRoute(
      path: '/manage-buses',
      builder: (BuildContext context, GoRouterState state) {
        return const ManageBusesScreen();
      },
    ),
  ],
);

