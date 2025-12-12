import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/food_model.dart';
import '../../features/recommendation/logic/scoring_engine.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/recommendation/presentation/result_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/favorites/presentation/favorites_screen.dart';
import '../../features/user/data/user_preferences_repository.dart';
import '../theme/style_tokens.dart';
import 'go_router_refresh_stream.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = FirebaseAuth.instance;
  final prefsRepo = UserPreferencesRepository();

  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: GoRouterRefreshStream(auth.authStateChanges()),
    redirect: (context, state) async {
      final user = auth.currentUser;
      final loggingIn = state.matchedLocation.startsWith('/auth');
      final inOnboarding = state.matchedLocation.startsWith('/onboarding');

      if (user == null && !loggingIn) {
        return '/auth/login';
      }
      if (user != null && loggingIn) {
        return '/dashboard';
      }

      if (user != null) {
        final settings = await prefsRepo.fetchUserSettings(user.uid);
        final done = settings?.onboardingCompleted ?? false;

        if (!done && !inOnboarding) {
          return '/onboarding';
        }
        if (done && inOnboarding) {
          return '/dashboard';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        pageBuilder: (context, state) => _buildSlidePage(
          state: state,
          child: const DashboardScreen(),
          offset: const Offset(0, 0.03),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) => _buildFadePage(
          state: state,
          child: const OnboardingScreen(),
        ),
      ),
      GoRoute(
        path: '/auth/login',
        name: 'login',
        pageBuilder: (context, state) => _buildFadePage(
          state: state,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/auth/register',
        name: 'register',
        pageBuilder: (context, state) => _buildFadePage(
          state: state,
          child: const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: '/auth/forgot',
        name: 'forgot_password',
        pageBuilder: (context, state) => _buildFadePage(
          state: state,
          child: const ForgotPasswordScreen(),
        ),
      ),
      GoRoute(
        path: '/result',
        name: 'result',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final food = extra?['food'] as FoodModel?;
          final recommendationContext = extra?['context'] as RecommendationContext?;
          
          if (food == null) {
            return _buildSlidePage(
              state: state,
              child: const DashboardScreen(),
              offset: const Offset(-0.06, 0),
            );
          }
          
          // Use provided context or create default
          final ctx = recommendationContext ?? RecommendationContext(
            budget: 2,
            companion: 'alone',
          );
          
          return _buildSlideUpPage(
            state: state,
            child: ResultScreen(
              food: food,
              recContext: ctx,
            ),
          );
        },
      ),
      GoRoute(
        path: '/favorites',
        name: 'favorites',
        pageBuilder: (context, state) => _buildSlidePage(
          state: state,
          child: const FavoritesScreen(),
          offset: const Offset(0.06, 0),
        ),
      ),
    ],
  );
});

CustomTransitionPage _buildFadePage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: AppDurations.medium,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

CustomTransitionPage _buildSlidePage({
  required GoRouterState state,
  required Widget child,
  Offset offset = const Offset(0.1, 0),
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: AppDurations.medium,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween(begin: offset, end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeOutCubic));
      return SlideTransition(
        position: animation.drive(tween),
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    },
  );
}

CustomTransitionPage _buildSlideUpPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: AppDurations.medium,
    reverseTransitionDuration: AppDurations.medium,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slideTween = Tween(begin: const Offset(0, 0.08), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeOutCubic));
      return SlideTransition(
        position: animation.drive(slideTween),
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    },
  );
}

