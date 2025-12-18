import 'dart:async';
import '../../../../models/food_model.dart';
import '../../../../core/utils/logger.dart';
import '../../interfaces/repository_interfaces.dart';
import '../user_feedback_learner.dart';
import '../scoring_engine.dart';
import 'recommendation_step.dart';
import 'recommendation_pipeline.dart';

/// Orchestrator for recommendation pipeline
/// Follows Single Responsibility Principle (SRP) - only orchestrates, delegates to pipeline
class RecommendationOrchestrator {
  final RecommendationPipeline _pipeline;
  final IFoodRepository _repository;
  final IHistoryRepository _historyRepository;
  final UserFeedbackLearner _feedbackLearner;
  
  RecommendationOrchestrator({
    required RecommendationPipeline pipeline,
    required IFoodRepository repository,
    required IHistoryRepository historyRepository,
    required UserFeedbackLearner feedbackLearner,
  })  : _pipeline = pipeline,
        _repository = repository,
        _historyRepository = historyRepository,
        _feedbackLearner = feedbackLearner;
  
  /// Get recommendations using pipeline
  Future<RecommendationResult> getRecommendations({
    required RecommendationContext context,
    required String userId,
    int topN = 5,
  }) async {
    try {
      // Create initial pipeline context
      final initialContext = PipelineContext(
        foods: [], // Will be fetched by DataFetchStep
        recommendationContext: context,
        userId: userId,
        topN: topN,
      );
      
      // Execute pipeline
      final resultContext = await _pipeline.execute(initialContext);
      
      if (resultContext == null || resultContext.foods.isEmpty) {
        return RecommendationResult(
          foods: [],
          error: 'Không có món ăn phù hợp với yêu cầu',
        );
      }
      
      final selectedFood = resultContext.foods.first;
      
      // Record user action (non-blocking)
      unawaited(_feedbackLearner.recordUserAction(
        userId: userId,
        foodId: selectedFood.id,
        action: UserAction.pick,
        context: context,
      ).catchError((e) {
        AppLogger.debug('Feedback learning failed (non-critical): $e');
      }));
      
      // Increment view count (non-blocking)
      unawaited(_repository.incrementViewCount(selectedFood.id).catchError((e) {
        return;
      }));
      
      // Add to history (non-blocking)
      unawaited(_historyRepository.addHistory(
        userId: userId,
        food: selectedFood,
        context: context,
      ).catchError((e) {
        return;
      }));
      
      return RecommendationResult(
        foods: resultContext.foods,
        error: null,
      );
    } catch (e, st) {
      AppLogger.error('Error in recommendation orchestrator: $e', e, st);
      return RecommendationResult(
        foods: [],
        error: 'Lỗi khi lấy gợi ý: $e',
      );
    }
  }
}

/// Result from recommendation pipeline
class RecommendationResult {
  final List<FoodModel> foods;
  final String? error;
  
  RecommendationResult({
    required this.foods,
    this.error,
  });
  
  bool get hasError => error != null;
  bool get isEmpty => foods.isEmpty;
}

