import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/bloc/auth_cubit.dart';
import '../features/auth/screens/onboarding_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/signup_student_screen.dart';
import '../features/auth/screens/signup_startup_screen.dart';
import '../features/home/screens/home_shell.dart';
import '../features/home/screens/home_screen.dart';
import '../features/opportunities/screens/explore_screen.dart';
import '../features/opportunities/screens/opportunity_detail_screen.dart';
import '../features/opportunities/screens/create_opportunity_screen.dart';
import '../features/applications/screens/applications_screen.dart';
import '../features/applications/screens/apply_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/edit_profile_screen.dart';
import '../features/startup/screens/startup_profile_screen.dart';
import '../features/startup/screens/startup_dashboard_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

GoRouter createRouter(AuthCubit authCubit) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    refreshListenable: _GoRouterRefreshStream(authCubit.stream),
    redirect: (context, state) {
      final authState = authCubit.state;
      final isLoggedIn = authState is AuthAuthenticated;
      final isOnAuthPage = state.matchedLocation.startsWith('/auth') ||
          state.matchedLocation == '/onboarding';
      if (authState is AuthInitial || authState is AuthLoading) {
        return null;
      }
      if (!isLoggedIn && !isOnAuthPage) return '/onboarding';
      if (isLoggedIn && isOnAuthPage) return '/home';

      // Role-based guards: keep students out of startup-only screens and
      // vice versa, even if they land on the route via a deep link.
      if (isLoggedIn) {
        final isStartup = authState.user.isStartup;
        final location = state.matchedLocation;

        const startupOnlyRoutes = ['/startup/dashboard', '/opportunity/create'];
        final isStartupOnlyRoute =
            startupOnlyRoutes.any((r) => location.startsWith(r));
        if (isStartupOnlyRoute && !isStartup) return '/home';

        const studentOnlyRoutes = ['/applications'];
        final isStudentOnlyRoute =
            studentOnlyRoutes.any((r) => location.startsWith(r));
        if (isStudentOnlyRoute && isStartup) return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/auth/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/auth/signup/student',
        builder: (_, __) => const SignupStudentScreen(),
      ),
      GoRoute(
        path: '/auth/signup/startup',
        builder: (_, __) => const SignupStartupScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/explore',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ExploreScreen(),
            ),
          ),
          GoRoute(
            path: '/applications',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ApplicationsScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
          GoRoute(
            path: '/startup/dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: StartupDashboardScreen(),
            ),
          ),
        ],
      ),
      // NOTE: static routes like '/opportunity/create' must be declared
      // BEFORE the dynamic '/opportunity/:id' route. go_router matches
      // routes in declaration order, and ':id' matches any segment
      // (including the literal word "create"), so if the dynamic route
      // came first it would swallow '/opportunity/create' and render
      // OpportunityDetailScreen with id="create" -> "Opportunity not found."
      GoRoute(
        path: '/opportunity/create',
        builder: (_, __) => const CreateOpportunityScreen(),
      ),
      GoRoute(
        path: '/opportunity/:id',
        builder: (context, state) => OpportunityDetailScreen(
          opportunityId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/opportunity/:id/apply',
        builder: (context, state) => ApplyScreen(
          opportunityId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/startup/:id',
        builder: (context, state) => StartupProfileScreen(
          startupId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (_, __) => const EditProfileScreen(),
      ),
    ],
  );
}