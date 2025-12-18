import '../../../../core/utils/logger.dart';
import '../scoring_engine.dart';
import '../scoring_weights.dart';
import '../graceful_degradation.dart';
import 'recommendation_step.dart';

/// Step 5: Score foods and get recommendations with graceful degradation
/// Single Responsibility: Only score and get recommendations
class ScoringStep implements RecommendationStep {
  ScoringStep();
  
  @override
  String get stepName => 'Scoring';
  
  @override
  Future<PipelineContext?> process(PipelineContext context) async {
    // Skip if cold start already provided foods
    if (context.isNewUser) {
      AppLogger.debug('[$stepName] Skipping (cold start already provided foods)');
      return context;
    }
    
    try {
      AppLogger.info('⚡ [$stepName] Scoring ${context.foods.length} foods...');
      
      // Get context-dependent weights
      final weights = ScoringWeights.getContextDependentWeights(
        budget: context.recommendationContext.budget,
        companion: context.recommendationContext.companion,
        weather: context.recommendationContext.weather,
      );
      
      // Create weighted engine with same dependencies as base engine
      // Note: We create a new engine with updated weights
      final weightedEngine = ScoringEngine(weights: weights);
      
      // Get recommendations with graceful degradation
      final gracefulDegradation = GracefulDegradation(weightedEngine);
      final topFoods = await gracefulDegradation.getRecommendationsWithFallback(
        context.foods,
        context.recommendationContext,
        context.topN,
      );
      
      AppLogger.info('✅ [$stepName] Got ${topFoods.length} recommendations');
      return context.copyWith(
        foods: topFoods,
        weights: weights,
      );
    } catch (e, st) {
      AppLogger.error('[$stepName] Error scoring foods: $e', e, st);
      return context; // Continue with original foods
    }
  }
}

