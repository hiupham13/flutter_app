import '../../../../models/food_model.dart';
import 'scoring_engine.dart';
import '../../../../core/utils/logger.dart';

/// Gracefully degrades filters when no foods match strict criteria
class GracefulDegradation {
  final ScoringEngine _scoringEngine;
  
  GracefulDegradation(this._scoringEngine);
  
  /// Get recommendations with fallback strategy
  /// Tries strict filters first, then gradually relaxes
  Future<List<FoodModel>> getRecommendationsWithFallback(
    List<FoodModel> foods,
    RecommendationContext context,
    int topN,
  ) async {
    if (foods.isEmpty) {
      AppLogger.warning('⚠️ No foods available for recommendation');
      return [];
    }
    
    AppLogger.info('🔄 Starting graceful degradation strategy...');
    
    // Try 1: Strict filters (original context)
    var result = await _scoringEngine.getTopFoods(foods, context, topN);
    if (result.length >= topN) {
      AppLogger.info('✅ Found ${result.length} foods with strict filters');
      return result;
    }
    
    AppLogger.info('⚠️ Only ${result.length} foods with strict filters, relaxing...');
    
    // Try 2: Relax budget (allow +1 segment)
    if (context.budget < 3) {
      final relaxedContext = _relaxBudget(context);
      result = await _scoringEngine.getTopFoods(foods, relaxedContext, topN);
      if (result.length >= topN) {
        AppLogger.info('✅ Found ${result.length} foods with relaxed budget');
        return result;
      }
    }
    
    // Try 3: Ignore time availability (still check other filters)
    final moreRelaxedContext = _relaxTimeAvailability(context);
    result = await _scoringEngine.getTopFoods(foods, moreRelaxedContext, topN);
    if (result.length >= topN) {
      AppLogger.info('✅ Found ${result.length} foods ignoring time availability');
      return result;
    }
    
    // Try 4: Only hard filters (allergies, vegetarian, blacklist)
    final minimalContext = RecommendationContext(
      weather: context.weather,
      budget: 3, // Max budget
      companion: context.companion,
      excludedAllergens: context.excludedAllergens, // Keep allergies
      isVegetarian: context.isVegetarian, // Keep vegetarian
      blacklistedFoods: context.blacklistedFoods, // Keep blacklist
      dietaryRestrictions: context.dietaryRestrictions, // Keep dietary
      // Remove other filters
    );
    result = await _scoringEngine.getTopFoods(foods, minimalContext, topN);
    if (result.isNotEmpty) {
      AppLogger.info('✅ Found ${result.length} foods with minimal filters');
      return result;
    }
    
    // Try 5: Only allergies and vegetarian (last resort)
    final lastResortContext = RecommendationContext(
      weather: null,
      budget: 3,
      companion: 'alone',
      excludedAllergens: context.excludedAllergens,
      isVegetarian: context.isVegetarian,
      dietaryRestrictions: context.dietaryRestrictions,
    );
    result = await _scoringEngine.getTopFoods(foods, lastResortContext, topN);
    if (result.isNotEmpty) {
      AppLogger.info('✅ Found ${result.length} foods with last resort filters');
      return result;
    }
    
    // Final fallback: Return random popular foods (if any exist)
    AppLogger.warning('⚠️ No foods match any criteria, returning popular foods');
    return _getRandomPopularFoods(foods, topN);
  }
  
  /// Relax budget constraint
  RecommendationContext _relaxBudget(RecommendationContext context) {
    return RecommendationContext(
      weather: context.weather,
      budget: (context.budget + 1).clamp(1, 3),
      companion: context.companion,
      mood: context.mood,
      excludedFoods: context.excludedFoods,
      excludedAllergens: context.excludedAllergens,
      favoriteCuisines: context.favoriteCuisines,
      recentlyEaten: context.recentlyEaten,
      blacklistedFoods: context.blacklistedFoods,
      isVegetarian: context.isVegetarian,
      spiceTolerance: context.spiceTolerance,
    );
  }
  
  /// Relax time availability (set to allow all times)
  RecommendationContext _relaxTimeAvailability(RecommendationContext context) {
    // Note: This is handled in scoring engine, but we can create a context
    // that doesn't penalize time mismatches
    return context; // Time availability is handled in scoring, not context
  }
  
  /// Get random popular foods as last resort
  List<FoodModel> _getRandomPopularFoods(List<FoodModel> foods, int topN) {
    // Sort by popularity (view count + pick count)
    final sorted = List<FoodModel>.from(foods);
    sorted.sort((a, b) {
      final aPopularity = (a.viewCount * 0.3) + (a.pickCount * 0.7);
      final bPopularity = (b.viewCount * 0.3) + (b.pickCount * 0.7);
      return bPopularity.compareTo(aPopularity);
    });
    
    return sorted.take(topN).toList();
  }
}

