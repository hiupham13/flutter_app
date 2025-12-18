import 'dart:async';
import '../interfaces/repository_interfaces.dart';
import '../../../../core/utils/logger.dart';
import 'scoring_engine.dart';

/// User action types for feedback learning
enum UserAction {
  pick,      // User selected this food
  skip,      // User skipped this recommendation
  favorite,  // User favorited this food
  reject,    // User explicitly rejected this food
}

/// Learns from user actions to improve recommendations
class UserFeedbackLearner {
  final IFoodRepository _foodRepository;
  final IHistoryRepository _historyRepository;
  
  UserFeedbackLearner(
    this._foodRepository,
    this._historyRepository,
  );
  
  /// Record user action and update weights
  Future<void> recordUserAction({
    required String userId,
    required String foodId,
    required UserAction action,
    required RecommendationContext context,
  }) async {
    try {
      AppLogger.info('📚 Recording user action: $action for food $foodId');
      
      // Log action to Firestore for analysis
      await _logActionToFirestore(
        userId: userId,
        foodId: foodId,
        action: action,
        context: context,
      );
      
      // Update weights based on action (fire-and-forget)
      _updateWeightsFromAction(
        userId: userId,
        foodId: foodId,
        action: action,
        context: context,
      ).catchError((e) {
        AppLogger.debug('Weight update failed (non-critical): $e');
      });
    } catch (e, st) {
      AppLogger.error('Error recording user action: $e', e, st);
    }
  }
  
  /// Log action to Firestore
  Future<void> _logActionToFirestore({
    required String userId,
    required String foodId,
    required UserAction action,
    required RecommendationContext context,
  }) async {
    try {
      await _historyRepository.addUserAction(
        userId: userId,
        foodId: foodId,
        action: action.toString().split('.').last,
        context: context,
      );
    } catch (e) {
      AppLogger.error('Failed to log action to Firestore: $e');
    }
  }
  
  /// Update preference weights based on action
  Future<void> _updateWeightsFromAction({
    required String userId,
    required String foodId,
    required UserAction action,
    required RecommendationContext context,
  }) async {
    try {
      final food = await _foodRepository.getFoodById(foodId);
      if (food == null) {
        AppLogger.warning('Food $foodId not found for weight update');
        return;
      }
      
      // Get current user preferences (would need UserPreferencesRepository)
      // For now, we'll just log the action
      // In future, this would update weights in Firestore
      
      switch (action) {
        case UserAction.pick:
        case UserAction.favorite:
          // Positive feedback - increase weights for this food's attributes
          AppLogger.debug('✅ Positive feedback: Boost ${food.cuisineId}, ${food.mealTypeId}');
          // TODO: Update user preference weights
          break;
          
        case UserAction.skip:
        case UserAction.reject:
          // Negative feedback - decrease weights
          AppLogger.debug('❌ Negative feedback: Reduce ${food.cuisineId}, ${food.mealTypeId}');
          // TODO: Update user preference weights
          break;
      }
    } catch (e, st) {
      AppLogger.error('Error updating weights from action: $e', e, st);
    }
  }
  
  /// Get learned preferences for user
  /// Returns context with learned preferences applied
  Future<RecommendationContext> applyLearnedPreferences(
    String userId,
    RecommendationContext baseContext,
  ) async {
    try {
      // Get user's learned preferences from Firestore
      // For now, return base context
      // In future, this would:
      // 1. Load user preference weights
      // 2. Adjust favoriteCuisines based on learned preferences
      // 3. Adjust excludedFoods based on rejections
      
      return baseContext;
    } catch (e, st) {
      AppLogger.error('Error applying learned preferences: $e', e, st);
      return baseContext;
    }
  }
}

