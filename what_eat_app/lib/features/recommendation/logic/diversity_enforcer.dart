import '../../../../models/food_model.dart';
import '../../../../core/utils/logger.dart';

/// Ensures diversity in top N recommendations
class DiversityEnforcer {
  /// Enforce diversity in top N results
  /// Ensures different cuisines and meal types
  List<FoodModel> enforceDiversity(
    List<FoodModel> scoredFoods,
    int topN, {
    double diversityThreshold = 0.7, // Min 70% should be diverse
  }) {
    if (scoredFoods.isEmpty || topN <= 0) return [];
    
    final result = <FoodModel>[];
    final usedCuisines = <String>{};
    final usedMealTypes = <String>{};
    
    // First pass: Prioritize diverse foods
    final minDiverseCount = (topN * diversityThreshold).ceil();
    
    for (final food in scoredFoods) {
      if (result.length >= topN) break;
      
      final cuisineDiversity = !usedCuisines.contains(food.cuisineId);
      final mealTypeDiversity = !usedMealTypes.contains(food.mealTypeId);
      
      // If we still need diversity, prioritize diverse foods
      if (result.length < minDiverseCount) {
        if (cuisineDiversity || mealTypeDiversity) {
          result.add(food);
          usedCuisines.add(food.cuisineId);
          usedMealTypes.add(food.mealTypeId);
        }
      } else {
        // After minimum diversity, just add top scores
        if (!result.contains(food)) {
          result.add(food);
          usedCuisines.add(food.cuisineId);
          usedMealTypes.add(food.mealTypeId);
        }
      }
    }
    
    // Fill remaining slots with top scores if needed
    if (result.length < topN) {
      for (final food in scoredFoods) {
        if (result.length >= topN) break;
        if (!result.contains(food)) {
          result.add(food);
        }
      }
    }
    
    AppLogger.debug('🎲 Diversity enforced: ${usedCuisines.length} cuisines, ${usedMealTypes.length} meal types');
    
    return result.take(topN).toList();
  }
  
  /// Balance categories - ensure at least one from each major category
  /// 🆕 Enhanced with better distribution
  List<FoodModel> balanceCategories(
    List<FoodModel> scoredFoods,
    int topN, {
    List<String>? requiredCategories,
  }) {
    if (scoredFoods.isEmpty || topN <= 0) return [];
    
    final categories = requiredCategories ?? ['soup', 'dry', 'snack', 'hotpot'];
    final result = <FoodModel>[];
    final categoryFound = <String, bool>{};
    final categoryCounts = <String, int>{};
    
    // Initialize counts
    for (final category in categories) {
      categoryCounts[category] = 0;
    }
    
    // First pass: Ensure at least one from each category
    for (final category in categories) {
      if (result.length >= topN) break;
      
      final food = scoredFoods.firstWhere(
        (f) => f.mealTypeId == category && !result.contains(f),
        orElse: () => scoredFoods.firstWhere(
          (f) => !result.contains(f),
          orElse: () => scoredFoods.first,
        ),
      );
      
      if (!result.contains(food)) {
        result.add(food);
        categoryFound[category] = true;
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      }
    }
    
    // Second pass: Distribute remaining slots evenly across categories
    final remainingSlots = topN - result.length;
    if (remainingSlots > 0) {
      final slotsPerCategory = (remainingSlots / categories.length).ceil();
      
      for (final category in categories) {
        if (result.length >= topN) break;
        
        final categoryFoods = scoredFoods
            .where((f) => f.mealTypeId == category && !result.contains(f))
            .take(slotsPerCategory)
            .toList();
        
        for (final food in categoryFoods) {
          if (result.length >= topN) break;
          result.add(food);
          categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
        }
      }
    }
    
    // Third pass: Fill any remaining slots with top scores
    for (final food in scoredFoods) {
      if (result.length >= topN) break;
      if (!result.contains(food)) {
        result.add(food);
        final category = food.mealTypeId;
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      }
    }
    
    AppLogger.debug('⚖️ Category balanced: ${categoryFound.length} categories, distribution: $categoryCounts');
    
    return result.take(topN).toList();
  }
  
  /// 🆕 Ensure minimum variety in results
  /// Guarantees at least N different cuisines and M different meal types
  List<FoodModel> ensureMinimumVariety(
    List<FoodModel> scoredFoods,
    int topN, {
    int minCuisines = 2,
    int minMealTypes = 2,
  }) {
    if (scoredFoods.isEmpty || topN <= 0) return [];
    
    final result = <FoodModel>[];
    final usedCuisines = <String>{};
    final usedMealTypes = <String>{};
    
    // First pass: Ensure minimum variety
    for (final food in scoredFoods) {
      if (result.length >= topN) break;
      
      final needsCuisine = usedCuisines.length < minCuisines;
      final needsMealType = usedMealTypes.length < minMealTypes;
      
      final hasNewCuisine = !usedCuisines.contains(food.cuisineId);
      final hasNewMealType = !usedMealTypes.contains(food.mealTypeId);
      
      // Prioritize foods that add variety
      if ((needsCuisine && hasNewCuisine) || (needsMealType && hasNewMealType)) {
        result.add(food);
        usedCuisines.add(food.cuisineId);
        usedMealTypes.add(food.mealTypeId);
      } else if (usedCuisines.length >= minCuisines && usedMealTypes.length >= minMealTypes) {
        // Minimum variety met, add any food
        if (!result.contains(food)) {
          result.add(food);
          usedCuisines.add(food.cuisineId);
          usedMealTypes.add(food.mealTypeId);
        }
      }
    }
    
    // Second pass: Fill remaining with top scores
    for (final food in scoredFoods) {
      if (result.length >= topN) break;
      if (!result.contains(food)) {
        result.add(food);
        usedCuisines.add(food.cuisineId);
        usedMealTypes.add(food.mealTypeId);
      }
    }
    
    AppLogger.debug('🎯 Minimum variety ensured: ${usedCuisines.length} cuisines (min: $minCuisines), ${usedMealTypes.length} meal types (min: $minMealTypes)');
    
    return result.take(topN).toList();
  }
  
  /// 🆕 Combined diversity enforcement with category balancing and minimum variety
  List<FoodModel> enforceDiversityWithBalancing(
    List<FoodModel> scoredFoods,
    int topN, {
    double diversityThreshold = 0.7,
    int minCuisines = 2,
    int minMealTypes = 2,
    bool balanceCategories = true,
  }) {
    if (scoredFoods.isEmpty || topN <= 0) return [];
    
    // Step 1: Ensure minimum variety
    var result = ensureMinimumVariety(
      scoredFoods,
      topN,
      minCuisines: minCuisines,
      minMealTypes: minMealTypes,
    );
    
    // Step 2: Balance categories if requested
    if (balanceCategories && result.length < topN) {
      result = this.balanceCategories(result, topN);
    }
    
    // Step 3: Enforce diversity
    result = this.enforceDiversity(result, topN, diversityThreshold: diversityThreshold);
    
    return result;
  }
  
  /// Calculate diversity score (0.0 - 1.0)
  double calculateDiversityScore(List<FoodModel> foods) {
    if (foods.isEmpty) return 0.0;
    
    final uniqueCuisines = foods.map((f) => f.cuisineId).toSet().length;
    final uniqueMealTypes = foods.map((f) => f.mealTypeId).toSet().length;
    
    final cuisineDiversity = uniqueCuisines / foods.length;
    final mealTypeDiversity = uniqueMealTypes / foods.length;
    
    return (cuisineDiversity + mealTypeDiversity) / 2.0;
  }
}

