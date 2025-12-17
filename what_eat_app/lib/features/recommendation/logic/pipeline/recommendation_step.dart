import '../../../../models/food_model.dart';
import '../scoring_engine.dart';
import '../scoring_weights.dart';
import '../user_preference_learner.dart';

/// Context passed between pipeline steps
class PipelineContext {
  List<FoodModel> foods;
  RecommendationContext recommendationContext;
  String userId;
  int topN;
  bool isNewUser;
  LearnedPreferences? learnedPreferences;
  ScoringWeights? weights;
  
  PipelineContext({
    required this.foods,
    required this.recommendationContext,
    required this.userId,
    required this.topN,
    this.isNewUser = false,
    this.learnedPreferences,
    this.weights,
  });
  
  PipelineContext copyWith({
    List<FoodModel>? foods,
    RecommendationContext? recommendationContext,
    String? userId,
    int? topN,
    bool? isNewUser,
    LearnedPreferences? learnedPreferences,
    ScoringWeights? weights,
  }) {
    return PipelineContext(
      foods: foods ?? this.foods,
      recommendationContext: recommendationContext ?? this.recommendationContext,
      userId: userId ?? this.userId,
      topN: topN ?? this.topN,
      isNewUser: isNewUser ?? this.isNewUser,
      learnedPreferences: learnedPreferences ?? this.learnedPreferences,
      weights: weights ?? this.weights,
    );
  }
}

/// Base interface for recommendation pipeline steps
/// Follows Single Responsibility Principle (SRP) - each step does one thing
abstract class RecommendationStep {
  /// Process the pipeline context and return updated context
  /// Returns null if step should be skipped
  Future<PipelineContext?> process(PipelineContext context);
  
  /// Step name for logging
  String get stepName;
}

