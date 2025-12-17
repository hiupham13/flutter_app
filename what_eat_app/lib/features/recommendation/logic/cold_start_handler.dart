import '../../../../models/food_model.dart';
import '../interfaces/repository_interfaces.dart';
import 'scoring_engine.dart';
import '../../../../core/utils/logger.dart';

/// Handles recommendations for new users without history
class ColdStartHandler {
  final IFoodRepository _foodRepository;
  final ScoringEngine _scoringEngine;
  
  ColdStartHandler(this._foodRepository, this._scoringEngine);
  
  /// Get recommendations for new user
  /// Uses popular/trending foods instead of personalization
  Future<List<FoodModel>> getRecommendationsForNewUser(
    RecommendationContext context,
    int topN,
  ) async {
    AppLogger.info('🆕 Getting recommendations for new user (cold start)');
    
    try {
      // Strategy 1: Popular foods (high view + pick count)
      final allFoods = await _foodRepository.getAllFoods();
      final popularFoods = _getPopularFoods(allFoods, limit: topN * 3);
      
      var result = await _scoringEngine.getTopFoods(popularFoods, context, topN);
      if (result.length >= topN) {
        AppLogger.info('✅ Found ${result.length} popular foods');
        return result;
      }
      
      // Strategy 2: Trending foods (high recent view count)
      final trendingFoods = _getTrendingFoods(allFoods, limit: topN * 3);
      result = await _scoringEngine.getTopFoods(trendingFoods, context, topN);
      if (result.length >= topN) {
        AppLogger.info('✅ Found ${result.length} trending foods');
        return result;
      }
      
      // Strategy 3: Random diverse foods
      AppLogger.info('⚠️ Using random diverse foods as fallback');
      return _getRandomDiverseFoods(allFoods, context, topN);
    } catch (e, st) {
      AppLogger.error('Error in cold start handler: $e', e, st);
      return [];
    }
  }
  
  /// Get popular foods (sorted by view + pick count)
  List<FoodModel> _getPopularFoods(List<FoodModel> foods, {required int limit}) {
    final sorted = List<FoodModel>.from(foods);
    sorted.sort((a, b) {
      // Popularity = weighted combination of views and picks
      final aPopularity = (a.viewCount * 0.3) + (a.pickCount * 0.7);
      final bPopularity = (b.viewCount * 0.3) + (b.pickCount * 0.7);
      return bPopularity.compareTo(aPopularity);
    });
    
    return sorted.take(limit).toList();
  }
  
  /// Get trending foods (high recent activity)
  /// For now, uses pick count as proxy for trending
  List<FoodModel> _getTrendingFoods(List<FoodModel> foods, {required int limit}) {
    final sorted = List<FoodModel>.from(foods);
    sorted.sort((a, b) {
      // Trending = pick count (users choosing it recently)
      final aTrending = a.pickCount.toDouble() / (a.viewCount + 1); // Pick rate
      final bTrending = b.pickCount.toDouble() / (b.viewCount + 1);
      return bTrending.compareTo(aTrending);
    });
    
    return sorted.take(limit).toList();
  }
  
  /// Get random diverse foods
  List<FoodModel> _getRandomDiverseFoods(
    List<FoodModel> foods,
    RecommendationContext context,
    int topN,
  ) {
    // Filter by hard constraints first
    final filtered = foods.where((food) {
      if (!food.isActive) return false;
      if (food.priceSegment > context.budget + 1) return false;
      
      // Check allergens
      for (final allergen in context.excludedAllergens) {
        if (food.allergenTags.contains(allergen)) return false;
      }
      
      // Check vegetarian
      if (context.isVegetarian) {
        final isVegetarianFood = food.flavorProfile.contains('vegetarian') ||
                                 food.contextScores['is_vegetarian'] == 1.0;
        if (!isVegetarianFood) return false;
      }
      
      return true;
    }).toList();
    
    // Shuffle and take diverse sample
    filtered.shuffle();
    
    final result = <FoodModel>[];
    final usedCuisines = <String>{};
    
    for (final food in filtered) {
      if (result.length >= topN) break;
      
      // Prefer diverse cuisines
      if (!usedCuisines.contains(food.cuisineId) || result.length < topN * 0.5) {
        result.add(food);
        usedCuisines.add(food.cuisineId);
      }
    }
    
    return result;
  }
}

