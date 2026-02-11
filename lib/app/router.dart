import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Auth
import 'package:dust_count/features/auth/domain/auth_providers.dart';
import 'package:dust_count/features/auth/presentation/splash_screen.dart';
import 'package:dust_count/features/auth/presentation/onboarding_screen.dart';
import 'package:dust_count/features/auth/presentation/login_screen.dart';
import 'package:dust_count/features/auth/presentation/register_screen.dart';
import 'package:dust_count/features/auth/presentation/forgot_password_screen.dart';
import 'package:dust_count/features/auth/presentation/profile_screen.dart';

// Household
import 'package:dust_count/features/household/presentation/household_list_screen.dart';
import 'package:dust_count/features/household/presentation/create_household_screen.dart';
import 'package:dust_count/features/household/presentation/join_household_screen.dart';
import 'package:dust_count/features/household/presentation/household_home_screen.dart';
import 'package:dust_count/features/household/presentation/household_settings_screen.dart';
import 'package:dust_count/features/household/presentation/manage_predefined_tasks_screen.dart';

// Tasks
import 'package:dust_count/features/tasks/presentation/task_detail_screen.dart';
import 'package:dust_count/features/tasks/presentation/task_edit_screen.dart';
import 'package:dust_count/shared/models/task_log.dart';
import 'package:dust_count/shared/models/household.dart';

/// Router provider that creates the GoRouter instance
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,

    // Refresh router when auth state changes
    refreshListenable: GoRouterRefreshStream(
      authState.hasValue ? Stream.value(authState.value) : const Stream.empty(),
    ),

    redirect: (BuildContext context, GoRouterState state) {
      final isAuthenticated = authState.value != null;
      final isOnAuthPage = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/register') ||
          state.matchedLocation.startsWith('/forgot-password') ||
          state.matchedLocation == '/onboarding';
      final isOnSplash = state.matchedLocation == '/splash';

      // Don't redirect if on splash screen (let it handle the flow)
      if (isOnSplash) {
        return null;
      }

      // If not authenticated and not on auth page, redirect to login
      if (!isAuthenticated && !isOnAuthPage) {
        return '/login';
      }

      // If authenticated and on auth page, redirect to households
      if (isAuthenticated && isOnAuthPage) {
        return '/households';
      }

      return null;
    },

    routes: [
      // Splash Screen
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Onboarding Screen
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Auth Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Household Routes
      GoRoute(
        path: '/households',
        name: 'households',
        builder: (context, state) => const HouseholdListScreen(),
        routes: [
          GoRoute(
            path: 'create',
            name: 'create-household',
            builder: (context, state) => const CreateHouseholdScreen(),
          ),
          GoRoute(
            path: 'join',
            name: 'join-household',
            builder: (context, state) => const JoinHouseholdScreen(),
          ),
          GoRoute(
            path: 'join/:code',
            name: 'join-household-with-code',
            builder: (context, state) {
              final code = state.pathParameters['code'];
              return JoinHouseholdScreen(inviteCode: code);
            },
          ),
        ],
      ),

      // Household Home Route (with nested routes)
      GoRoute(
        path: '/household/:id',
        name: 'household-home',
        builder: (context, state) {
          final householdId = state.pathParameters['id']!;
          return HouseholdHomeScreen(householdId: householdId);
        },
        routes: [
          GoRoute(
            path: 'settings',
            name: 'household-settings',
            builder: (context, state) {
              final householdId = state.pathParameters['id']!;
              return HouseholdSettingsScreen(householdId: householdId);
            },
            routes: [
              GoRoute(
                path: 'tasks',
                name: 'manage-predefined-tasks',
                builder: (context, state) {
                  final householdId = state.pathParameters['id']!;
                  return ManagePredefinedTasksScreen(householdId: householdId);
                },
              ),
            ],
          ),
          GoRoute(
            path: 'task/:taskId',
            name: 'task-detail',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              return TaskDetailScreen(
                taskLog: extra['task'] as TaskLog,
                household: extra['household'] as Household,
              );
            },
            routes: [
              GoRoute(
                path: 'edit',
                name: 'task-edit',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>;
                  return TaskEditScreen(
                    taskLog: extra['task'] as TaskLog,
                    household: extra['household'] as Household,
                  );
                },
              ),
            ],
          ),
        ],
      ),

      // Profile Route
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],

    // Error handling
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/households'),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    ),
  );
});

/// Helper class to convert Stream to Listenable for GoRouter
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
