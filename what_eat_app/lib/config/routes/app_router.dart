import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/food_model.dart';
import '../../features/recommendation/logic/scoring_engine.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/recommendation/presentation/result_screen.dart';
import 'go_router_refresh_stream.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = FirebaseAuth.instance;

  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: GoRouterRefreshStream(auth.authStateChanges()),
    redirect: (context, state) {
      final user = auth.currentUser;
      final loggingIn = state.matchedLocation.startsWith('/auth');

      if (user == null && !loggingIn) {
        return '/auth/login';
      }
      if (user != null && loggingIn) {
        return '/dashboard';
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
    ],
  );
});

