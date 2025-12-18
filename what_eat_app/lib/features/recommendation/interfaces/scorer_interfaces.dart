import '../../../../models/food_model.dart';
import '../logic/scoring_engine.dart';

/// Interface for location-based scoring
/// Follows Dependency Inversion Principle (DIP)
abstract class ILocationScorer {
  /// Get location multiplier for a food
  Future<double> getLocationMultiplier(FoodModel food);
  
  /// Get location multipliers for all foods (batch operation)
  Future<Map<String, double>> getLocationMultipliers(List<FoodModel> foods);
  
  /// Pre-calculate location multipliers for all foods
  Future<Map<String, double>> preCalculateLocationMultipliers(List<FoodModel> foods);
}

/// Interface for popularity-based scoring
abstract class IPopularityScorer {
  /// Get popularity multiplier
  double getPopularityMultiplier(FoodModel food);
  
  /// Get trending multiplier
  double getTrendingMultiplier(FoodModel food);
  
  /// Get combined multiplier (popularity + trending)
  double getCombinedMultiplier(FoodModel food);
  
  /// Get popularity score (0.0 - 1.0)
  double getPopularityScore(FoodModel food);
}

/// Interface for dietary restriction scoring
abstract class IDietaryRestrictionScorer {
  /// Get dietary multiplier based on restrictions
  double getDietaryMultiplier(FoodModel food, List<DietaryRestriction> restrictions);
  
  /// Check if food matches restrictions
  bool matchesRestrictions(FoodModel food, List<DietaryRestriction> restrictions);
}

/// Interface for time availability scoring
abstract class ITimeAvailabilityScorer {
  /// Get availability multiplier
  double getAvailabilityMultiplier(FoodModel food);
  
  /// Check if food is available now
  bool isAvailableNow(FoodModel food);
  
  /// Get availability status message
  String getAvailabilityStatus(FoodModel food);
}

