import '../../../../models/food_model.dart';
import '../interfaces/repository_interfaces.dart';
import '../../../../core/utils/logger.dart';

/// Prevents recommending foods that were recently recommended
class AntiRepetitionFilter {
  final IHistoryRepository _historyRepository;
  
  AntiRepetitionFilter(this._historyRepository);
  
  /// Filter out recently recommended foods
  /// Returns filtered list with recent recommendations deprioritized
  Future<List<FoodModel>> filterRecentRecommendations(
    List<FoodModel> scoredFoods,
    String userId,
    int topN, {
    int lookbackDays = 7,
  }) async {
    if (scoredFoods.isEmpty) return [];
    
    try {
      // Get recently recommended food IDs
      final recentFoodIds = await _historyRepository.fetchHistoryFoodIdsWithDays(
        userId: userId,
        days: lookbackDays,
      );
      
      if (recentFoodIds.isEmpty) {
        // No recent history, return as-is
        return scoredFoods.take(topN).toList();
      }
      
      AppLogger.debug('🔄 Found ${recentFoodIds.length} recently recommended foods');
      
      // Split into recent and new foods
      final recentFoods = <FoodModel>[];
      final newFoods = <FoodModel>[];
      
      for (final food in scoredFoods) {
        if (recentFoodIds.contains(food.id)) {
          recentFoods.add(food);
        } else {
          newFoods.add(food);
        }
      }
      
      // Prioritize new foods, but allow some recent if needed
      final result = <FoodModel>[];
      
      // Add new foods first (up to 80% of topN)
      final newFoodsLimit = (topN * 0.8).ceil();
      result.addAll(newFoods.take(newFoodsLimit));
      
      // Fill remaining with recent foods if needed
      if (result.length < topN && recentFoods.isNotEmpty) {
        final remaining = topN - result.length;
        result.addAll(recentFoods.take(remaining));
      }
      
      // If still not enough, add more new foods
      if (result.length < topN) {
        final remaining = topN - result.length;
        result.addAll(newFoods.skip(newFoodsLimit).take(remaining));
      }
      
      AppLogger.debug('✅ Anti-repetition: ${newFoods.length} new, ${recentFoods.length} recent');
      
      return result.take(topN).toList();
    } catch (e, st) {
      AppLogger.error('Error in anti-repetition filter: $e', e, st);
      // On error, return original list
      return scoredFoods.take(topN).toList();
    }
  }
  
  /// Check if food was recently recommended
  Future<bool> wasRecentlyRecommended(String userId, String foodId, {int days = 7}) async {
    try {
      final recentFoodIds = await _historyRepository.fetchHistoryFoodIdsWithDays(
        userId: userId,
        days: days,
      );
      return recentFoodIds.contains(foodId);
    } catch (e) {
      AppLogger.error('Error checking recent recommendation: $e');
      return false;
    }
  }
}

