import '../../interfaces/repository_interfaces.dart';
import '../../../../core/utils/logger.dart';
import 'recommendation_step.dart';

/// Step 1: Fetch all foods from repository
/// Single Responsibility: Only fetch data
class DataFetchStep implements RecommendationStep {
  final IFoodRepository _repository;
  
  DataFetchStep(this._repository);
  
  @override
  String get stepName => 'DataFetch';
  
  @override
  Future<PipelineContext?> process(PipelineContext context) async {
    try {
      AppLogger.info('📦 [$stepName] Fetching all foods...');
      final foods = await _repository.getAllFoods();
      
      if (foods.isEmpty) {
        AppLogger.warning('[$stepName] No foods found');
        return null; // Signal to stop pipeline
      }
      
      AppLogger.info('✅ [$stepName] Fetched ${foods.length} foods');
      return context.copyWith(foods: foods);
    } catch (e, st) {
      AppLogger.error('[$stepName] Error fetching foods: $e', e, st);
      return null; // Signal error
    }
  }
}

