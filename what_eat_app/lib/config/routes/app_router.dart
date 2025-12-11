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
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/forgot',
        name: 'forgot_password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/result',
        name: 'result',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final food = extra?['food'] as FoodModel?;
          final recommendationContext = extra?['context'] as RecommendationContext?;
          
          if (food == null) {
            return const DashboardScreen();
          }
          
          // Use provided context or create default
          final ctx = recommendationContext ?? RecommendationContext(
            budget: 2,
            companion: 'alone',
          );
          
          return ResultScreen(
            food: food,
            context: ctx,
          );
        },
      ),
      GoRoute(
        path: '/favorites',
        name: 'favorites',
        builder: (context, state) => const FavoritesScreen(),
      ),
    ],
  );
});

