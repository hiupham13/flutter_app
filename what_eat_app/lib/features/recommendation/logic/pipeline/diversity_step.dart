import '../../../../core/utils/logger.dart';
import '../diversity_enforcer.dart';
import 'recommendation_step.dart';

/// Step 7: Enforce diversity with category balancing
/// Single Responsibility: Only enforce diversity
class DiversityStep implements RecommendationStep {
  final DiversityEnforcer _enforcer;
  
  DiversityStep(this._enforcer);
  
  @override
  String get stepName => 'Diversity';
  
  @override
  Future<PipelineContext?> process(PipelineContext context) async {
    try {
      AppLogger.info('🌈 [$stepName] Enforcing diversity...');
      final diverseFoods = _enforcer.enforceDiversityWithBalancing(
        context.foods,
        context.topN,
        minCuisines: 2,
        minMealTypes: 2,
        balanceCategories: true,
      );
      
      final diversityScore = _enforcer.calculateDiversityScore(diverseFoods);
      AppLogger.info('✅ [$stepName] Enforced diversity: ${diverseFoods.length} foods, score: ${diversityScore.toStringAsFixed(2)}');
      
      return context.copyWith(foods: diverseFoods);
    } catch (e, st) {
      AppLogger.error('[$stepName] Error enforcing diversity: $e', e, st);
      return context; // Continue with original foods
    }
  }
}

