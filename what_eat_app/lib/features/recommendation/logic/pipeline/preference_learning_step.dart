import '../../../../core/utils/logger.dart';
import '../user_preference_learner.dart';
import 'recommendation_step.dart';

/// Step 3: Learn user preferences from history
/// Single Responsibility: Only learn preferences
class PreferenceLearningStep implements RecommendationStep {
  final UserPreferenceLearner _learner;
  
  PreferenceLearningStep(this._learner);
  
  @override
  String get stepName => 'PreferenceLearning';
  
  @override
  Future<PipelineContext?> process(PipelineContext context) async {
    try {
      AppLogger.info('📚 [$stepName] Learning preferences for user ${context.userId}...');
      final learnedPreferences = await _learner.learnPreferences(context.userId);
      
      if (!learnedPreferences.isEmpty) {
        AppLogger.info('✅ [$stepName] Learned preferences: ${learnedPreferences.favoriteCuisines.length} cuisines, confidence: ${learnedPreferences.confidence.toStringAsFixed(2)}');
        
        // Apply learned preferences to context
        final updatedContext = _learner.applyLearnedPreferences(
          context.recommendationContext,
          learnedPreferences,
        );
        
        return context.copyWith(
          recommendationContext: updatedContext,
          learnedPreferences: learnedPreferences,
        );
      }
      
      AppLogger.debug('[$stepName] No preferences learned (new user or insufficient data)');
      return context;
    } catch (e, st) {
      AppLogger.error('[$stepName] Error learning preferences: $e', e, st);
      return context; // Continue without learned preferences
    }
  }
}

