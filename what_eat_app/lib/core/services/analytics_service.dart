import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/recommendation/logic/scoring_engine.dart';
import '../../models/food_model.dart';

/// Thin wrapper around Firebase Analytics with typed events for the app.
class AnalyticsService {
  final FirebaseAnalytics _analytics;

  AnalyticsService({FirebaseAnalytics? analytics})
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  Future<void> logRecommendationRequested(
    RecommendationContext context,
  ) async {
    await _analytics.logEvent(
      name: 'recommendation_requested',
      parameters: {
        'budget': context.budget,
        'companion': context.companion,
        'mood': context.mood ?? 'none',
        'is_vegetarian': context.isVegetarian ? 1 : 0,
        'favorite_cuisines_count': context.favoriteCuisines.length,
      },
    );
  }

  Future<void> logFoodSelected(FoodModel food) async {
    await _analytics.logEvent(
      name: 'food_selected',
      parameters: {
        'food_id': food.id,
        'cuisine_id': food.cuisineId,
        'price_segment': food.priceSegment,
      },
    );
  }

  Future<void> logMapOpened(FoodModel food) async {
    await _analytics.logEvent(
      name: 'map_opened',
      parameters: {
        'food_id': food.id,
        'map_query': food.mapQuery,
      },
    );
  }

  Future<void> logFoodShared({
    required FoodModel food,
    required String source,
  }) async {
    await _analytics.logEvent(
      name: 'food_shared',
      parameters: {
        'food_id': food.id,
        'food_name': food.name,
        'cuisine_id': food.cuisineId,
        'price_segment': food.priceSegment,
        'source': source,
      },
    );
  }

  Future<void> logOnboardingCompleted({
    required bool skipped,
    int? defaultBudget,
    int? spiceTolerance,
    int? favoriteCuisinesCount,
    int? excludedAllergensCount,
  }) async {
    await _analytics.logEvent(
      name: 'onboarding_completed',
      parameters: {
        'skipped': skipped ? 1 : 0,
        if (defaultBudget != null) 'default_budget': defaultBudget,
        if (spiceTolerance != null) 'spice_tolerance': spiceTolerance,
        if (favoriteCuisinesCount != null)
          'favorite_cuisines_count': favoriteCuisinesCount,
        if (excludedAllergensCount != null)
          'excluded_allergens_count': excludedAllergensCount,
      },
    );
  }
}

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});


