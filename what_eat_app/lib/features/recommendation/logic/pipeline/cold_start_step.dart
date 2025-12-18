import '../../../../core/utils/logger.dart';
import '../../interfaces/repository_interfaces.dart';
import '../cold_start_handler.dart';
import 'recommendation_step.dart';

/// Step 4: Check if user is new and handle cold start
/// Single Responsibility: Only handle cold start
class ColdStartStep implements RecommendationStep {
  final IHistoryRepository _historyRepository;
  final ColdStartHandler _coldStartHandler;
  
  ColdStartStep(this._historyRepository, this._coldStartHandler);
  
  @override
  String get stepName => 'ColdStart';
  
  @override
  Future<PipelineContext?> process(PipelineContext context) async {
    try {
      // Check if user is new
      final recentHistory = await _historyRepository.fetchHistoryFoodIdsWithDays(
        userId: context.userId,
        days: 30,
      );
      
      final isNewUser = recentHistory.isEmpty;
      
      if (isNewUser) {
        AppLogger.info('🆕 [$stepName] New user detected, using cold start strategy');
        final coldStartFoods = await _coldStartHandler.getRecommendationsForNewUser(
          context.recommendationContext,
          context.topN,
        );
        
        return context.copyWith(
          foods: coldStartFoods,
          isNewUser: true,
        );
      }
      
      AppLogger.debug('[$stepName] Existing user, continuing with normal flow');
      return context.copyWith(isNewUser: false);
    } catch (e, st) {
      AppLogger.error('[$stepName] Error in cold start: $e', e, st);
      return context; // Continue with normal flow on error
    }
  }
}

