import '../../../../core/utils/logger.dart';
import '../data_validator.dart';
import 'recommendation_step.dart';

/// Step 2: Validate and fix food data
/// Single Responsibility: Only validate data
class ValidationStep implements RecommendationStep {
  final DataValidator _validator;
  
  ValidationStep(this._validator);
  
  @override
  String get stepName => 'Validation';
  
  @override
  Future<PipelineContext?> process(PipelineContext context) async {
    try {
      AppLogger.info('🔍 [$stepName] Validating ${context.foods.length} foods...');
      final validatedFoods = _validator.validateAndFixList(context.foods);
      AppLogger.info('✅ [$stepName] Validated ${validatedFoods.length} foods');
      return context.copyWith(foods: validatedFoods);
    } catch (e, st) {
      AppLogger.error('[$stepName] Error validating foods: $e', e, st);
      return context; // Continue with original foods on error
    }
  }
}

