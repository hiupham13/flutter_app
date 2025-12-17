import '../../../../core/utils/logger.dart';
import '../anti_repetition_filter.dart';
import 'recommendation_step.dart';

/// Step 6: Filter out recently recommended foods
/// Single Responsibility: Only filter repetitions
class AntiRepetitionStep implements RecommendationStep {
  final AntiRepetitionFilter _filter;
  
  AntiRepetitionStep(this._filter);
  
  @override
  String get stepName => 'AntiRepetition';
  
  @override
  Future<PipelineContext?> process(PipelineContext context) async {
    // Skip if cold start (new users don't have history)
    if (context.isNewUser) {
      AppLogger.debug('[$stepName] Skipping (new user, no history)');
      return context;
    }
    
    try {
      AppLogger.info('🔄 [$stepName] Filtering recent recommendations...');
      final filteredFoods = await _filter.filterRecentRecommendations(
        context.foods,
        context.userId,
        context.topN,
      );
      
      AppLogger.info('✅ [$stepName] Filtered to ${filteredFoods.length} foods');
      return context.copyWith(foods: filteredFoods);
    } catch (e, st) {
      AppLogger.error('[$stepName] Error filtering repetitions: $e', e, st);
      return context; // Continue with original foods
    }
  }
}

