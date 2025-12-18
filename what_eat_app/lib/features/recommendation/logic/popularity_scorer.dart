import '../../../../models/food_model.dart';
import '../interfaces/scorer_interfaces.dart';

/// Scores foods based on popularity and user engagement
/// Implements IPopularityScorer interface (DIP)
class PopularityScorer implements IPopularityScorer {
  /// Get popularity multiplier based on view and pick counts
  /// Higher pick rate = more popular = higher multiplier
  @override
  double getPopularityMultiplier(FoodModel food) {
    final totalViews = food.viewCount;
    final totalPicks = food.pickCount;
    
    // New food with no data - neutral
    if (totalViews == 0) {
      return 1.0;
    }
    
    // Calculate pick rate (conversion rate)
    final pickRate = totalPicks / totalViews;
    
    // Boost foods with high pick rate
    // >20% = very popular (30% boost)
    if (pickRate > 0.2) {
      return 1.3;
    }
    
    // >10% = popular (15% boost)
    if (pickRate > 0.1) {
      return 1.15;
    }
    
    // >5% = somewhat popular (5% boost)
    if (pickRate > 0.05) {
      return 1.05;
    }
    
    // Low pick rate - neutral or slight penalty
    if (pickRate < 0.01) {
      return 0.95; // Slight penalty for very low engagement
    }
    
    return 1.0; // Neutral
  }
  
  /// Get trending multiplier based on recent activity
  /// Foods with high recent views relative to total = trending
  @override
  double getTrendingMultiplier(FoodModel food) {
    // For now, use pick count as proxy for trending
    // (Foods that are being picked recently are trending)
    final totalViews = food.viewCount;
    final totalPicks = food.pickCount;
    
    if (totalViews == 0) {
      return 1.0;
    }
    
    // High pick rate suggests trending
    final pickRate = totalPicks / totalViews;
    
    // Very high pick rate (>15%) = trending
    if (pickRate > 0.15) {
      return 1.2; // 20% boost for trending
    }
    
    // Moderate pick rate (>8%) = somewhat trending
    if (pickRate > 0.08) {
      return 1.1; // 10% boost
    }
    
    return 1.0; // Neutral
  }
  
  /// Get combined popularity score (popularity + trending)
  @override
  double getCombinedMultiplier(FoodModel food) {
    final popularity = getPopularityMultiplier(food);
    final trending = getTrendingMultiplier(food);
    
    // Average of both (or weighted average)
    return (popularity * 0.7) + (trending * 0.3);
  }
  
  /// Get popularity score for ranking (0.0 - 1.0)
  @override
  double getPopularityScore(FoodModel food) {
    final totalViews = food.viewCount;
    final totalPicks = food.pickCount;
    
    if (totalViews == 0) {
      return 0.5; // Neutral score for new foods
    }
    
    final pickRate = totalPicks / totalViews;
    
    // Normalize to 0.0 - 1.0
    // Pick rate of 0.2 (20%) = score of 1.0
    // Pick rate of 0.0 (0%) = score of 0.0
    return (pickRate / 0.2).clamp(0.0, 1.0);
  }
}

