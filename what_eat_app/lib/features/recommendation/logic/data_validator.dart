import '../../../../models/food_model.dart';
import '../../../../core/utils/logger.dart';

/// Validates and fixes food data to ensure algorithm doesn't crash
class DataValidator {
  /// Validate and fix food model - returns fixed version
  FoodModel validateAndFix(FoodModel food) {
    try {
      // Fix missing or invalid context scores
      Map<String, double> contextScores = _getValidContextScores(food);
      
      // Fix missing or invalid price segment
      int priceSegment = _getValidPriceSegment(food);
      
      // Fix missing or empty lists
      List<String> searchKeywords = food.searchKeywords.isEmpty 
          ? [food.name.toLowerCase()] 
          : food.searchKeywords;
      
      List<String> images = food.images.isEmpty 
          ? [''] // Empty string for placeholder
          : food.images;
      
      // Create fixed food model
      return FoodModel.create(
        id: food.id,
        name: food.name.isNotEmpty ? food.name : 'Unknown Food',
        searchKeywords: searchKeywords,
        description: food.description,
        images: images,
        cuisineId: food.cuisineId.isNotEmpty ? food.cuisineId : 'vn',
        mealTypeId: food.mealTypeId.isNotEmpty ? food.mealTypeId : 'dry',
        flavorProfile: food.flavorProfile,
        allergenTags: food.allergenTags,
        priceSegment: priceSegment,
        avgCalories: food.avgCalories,
        availableTimes: food.availableTimes.isEmpty 
            ? ['morning', 'lunch', 'dinner'] 
            : food.availableTimes,
        contextScores: contextScores,
        mapQuery: food.mapQuery.isNotEmpty ? food.mapQuery : food.name,
        isActive: food.isActive,
        createdAt: food.createdAt,
        updatedAt: food.updatedAt,
        viewCount: food.viewCount >= 0 ? food.viewCount : 0,
        pickCount: food.pickCount >= 0 ? food.pickCount : 0,
      );
    } catch (e, st) {
      AppLogger.error('Error validating food ${food.id}: $e', e, st);
      // Return food with minimal fixes
      return _createMinimalValidFood(food);
    }
  }
  
  /// Get valid context scores with fallback defaults
  Map<String, double> _getValidContextScores(FoodModel food) {
    Map<String, double> scores;
    
    try {
      scores = food.contextScores;
    } catch (e) {
      // If parsing fails, use empty map
      scores = {};
    }
    
    // Ensure all required keys exist with default values
    final defaults = _getDefaultContextScores();
    defaults.forEach((key, value) {
      if (!scores.containsKey(key)) {
        scores[key] = value;
      } else {
        // Clamp values to valid range [0.0, 2.0]
        scores[key] = scores[key]!.clamp(0.0, 2.0);
      }
    });
    
    return scores;
  }
  
  /// Get valid price segment (1-3)
  int _getValidPriceSegment(FoodModel food) {
    if (food.priceSegment < 1 || food.priceSegment > 3) {
      AppLogger.warning('Invalid price segment ${food.priceSegment} for food ${food.id}, defaulting to 2');
      return 2; // Default mid-range
    }
    return food.priceSegment;
  }
  
  /// Default context scores when missing
  Map<String, double> _getDefaultContextScores() {
    return {
      'weather_hot': 1.0,
      'weather_rain': 1.0,
      'weather_cold': 1.0,
      'companion_alone': 1.0,
      'companion_date': 1.0,
      'companion_group': 1.0,
      'mood_normal': 1.0,
      'mood_stress': 1.0,
      'mood_sick': 1.0,
      'time_morning': 1.0,
      'time_lunch': 1.0,
      'time_dinner': 1.0,
      'time_late_night': 1.0,
    };
  }
  
  /// Create minimal valid food when validation completely fails
  FoodModel _createMinimalValidFood(FoodModel food) {
    return FoodModel.create(
      id: food.id,
      name: food.name.isNotEmpty ? food.name : 'Unknown Food',
      searchKeywords: [food.name.toLowerCase()],
      description: food.description,
      images: food.images,
      cuisineId: 'vn',
      mealTypeId: 'dry',
      flavorProfile: [],
      allergenTags: [],
      priceSegment: 2,
      avgCalories: null,
      availableTimes: ['morning', 'lunch', 'dinner'],
      contextScores: _getDefaultContextScores(),
      mapQuery: food.name,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      viewCount: 0,
      pickCount: 0,
    );
  }
  
  /// Validate a list of foods and return fixed versions
  List<FoodModel> validateAndFixList(List<FoodModel> foods) {
    return foods.map((food) => validateAndFix(food)).toList();
  }
  
  /// Check data quality score (0.0 - 1.0)
  double calculateQualityScore(FoodModel food) {
    double score = 1.0;
    
    // Deduct for missing data
    if (food.contextScores.isEmpty) score -= 0.4;
    if (food.priceSegment < 1 || food.priceSegment > 3) score -= 0.3;
    if (food.images.isEmpty) score -= 0.2;
    if (food.searchKeywords.isEmpty) score -= 0.1;
    
    return score.clamp(0.0, 1.0);
  }
}

