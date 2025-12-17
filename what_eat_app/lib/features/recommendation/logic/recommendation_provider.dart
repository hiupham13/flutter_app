import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../../../../models/food_model.dart';
import '../data/repositories/food_repository.dart';
import '../interfaces/repository_interfaces.dart';
import '../data/repositories/history_repository.dart';
import 'scoring_engine.dart';
import 'data_validator.dart';
import 'diversity_enforcer.dart';
import 'user_feedback_learner.dart';
import 'user_preference_learner.dart';
import '../../../../core/utils/logger.dart';
import 'pipeline/recommendation_orchestrator.dart';
import 'pipeline/pipeline_providers.dart';

// Repository Provider - Returns interface (DIP)
final foodRepositoryProvider = Provider<IFoodRepository>((ref) {
  return FoodRepository();
});

// Scoring Engine Provider with context-dependent weights
final scoringEngineProvider = Provider<ScoringEngine>((ref) {
  return ScoringEngine();
});

// History Repository Provider - Returns interface (DIP)
final historyRepositoryProvider = Provider<IHistoryRepository>((ref) {
  return HistoryRepository();
});

// Data Validator Provider
final dataValidatorProvider = Provider<DataValidator>((ref) {
  return DataValidator();
});

// Diversity Enforcer Provider
final diversityEnforcerProvider = Provider<DiversityEnforcer>((ref) {
  return DiversityEnforcer();
});

// User Feedback Learner Provider
final userFeedbackLearnerProvider = Provider<UserFeedbackLearner>((ref) {
  return UserFeedbackLearner(
    ref.watch(foodRepositoryProvider),
    ref.watch(historyRepositoryProvider),
  );
});

// User Preference Learner Provider
final userPreferenceLearnerProvider = Provider<UserPreferenceLearner>((ref) {
  return UserPreferenceLearner(
    foodRepository: ref.watch(foodRepositoryProvider),
    historyRepository: ref.watch(historyRepositoryProvider),
  );
});

// Recommendation State
class RecommendationState {
  final List<FoodModel> recommendedFoods;
  final FoodModel? currentFood;
  final bool isLoading;
  final String? error;
  final List<FoodModel> history;

  RecommendationState({
    this.recommendedFoods = const [],
    this.currentFood,
    this.isLoading = false,
    this.error,
    this.history = const [],
  });

  RecommendationState copyWith({
    List<FoodModel>? recommendedFoods,
    FoodModel? currentFood,
    bool? isLoading,
    String? error,
    List<FoodModel>? history,
  }) {
    return RecommendationState(
      recommendedFoods: recommendedFoods ?? this.recommendedFoods,
      currentFood: currentFood ?? this.currentFood,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      history: history ?? this.history,
    );
  }
}

// Recommendation Notifier - Refactored to use Pipeline pattern (SRP)
class RecommendationNotifier extends StateNotifier<RecommendationState> {
  final RecommendationOrchestrator _orchestrator;
  final IFoodRepository _repository;
  final IHistoryRepository _historyRepository;
  final UserFeedbackLearner _feedbackLearner;

  RecommendationNotifier(
    this._orchestrator,
    this._repository,
    this._historyRepository,
    this._feedbackLearner,
  ) : super(RecommendationState());

  /// Get recommendations using pipeline orchestrator
  /// Follows Single Responsibility Principle (SRP) - delegates to orchestrator
  Future<void> getRecommendations(RecommendationContext context,
      {int topN = 5, required String userId}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Delegate to orchestrator
      final result = await _orchestrator.getRecommendations(
        context: context,
        userId: userId,
        topN: topN,
      );

      if (result.hasError || result.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: result.error ?? 'Không có món ăn phù hợp với yêu cầu',
        );
        return;
      }

      final selectedFood = result.foods.first;

      // Update local state immediately
      final updatedHistory = [
        selectedFood,
        ...state.history.where((f) => f.id != selectedFood.id),
      ];

      state = state.copyWith(
        recommendedFoods: result.foods,
        currentFood: selectedFood,
        isLoading: false,
        history: updatedHistory,
      );
      
      AppLogger.info('✅ Recommendation completed: ${result.foods.length} foods');
    } catch (e, st) {
      // Standardized error handling: Log + Crashlytics
      AppLogger.error('Error getting recommendations: $e', e, st);
      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'Recommendation failed',
        fatal: false,
      );
      state = state.copyWith(
        isLoading: false,
        error: 'Lỗi khi lấy gợi ý: $e',
      );
    }
  }
  
  /// Record user skip action
  Future<void> recordSkip(String userId, String foodId, RecommendationContext context) async {
    await _feedbackLearner.recordUserAction(
      userId: userId,
      foodId: foodId,
      action: UserAction.skip,
      context: context,
    );
  }
  
  /// Record user favorite action
  Future<void> recordFavorite(String userId, String foodId, RecommendationContext context) async {
    await _feedbackLearner.recordUserAction(
      userId: userId,
      foodId: foodId,
      action: UserAction.favorite,
      context: context,
    );
  }
  
  /// Record user reject action
  Future<void> recordReject(String userId, String foodId, RecommendationContext context) async {
    await _feedbackLearner.recordUserAction(
      userId: userId,
      foodId: foodId,
      action: UserAction.reject,
      context: context,
    );
  }

  void nextFood() {
    if (state.recommendedFoods.length > 1) {
      final currentIndex = state.recommendedFoods.indexOf(state.currentFood!);
      final nextIndex = (currentIndex + 1) % state.recommendedFoods.length;
      state = state.copyWith(currentFood: state.recommendedFoods[nextIndex]);
    }
  }

  Future<void> selectFood(String foodId) async {
    await _repository.incrementPickCount(foodId);
  }

  List<FoodModel> getRecommendationHistory() => state.history;

  Future<void> loadHistory({
    required String userId,
    int limit = 20,
  }) async {
    final ids = await _historyRepository.fetchHistoryFoodIds(
      userId: userId,
      limit: limit,
    );
    if (ids.isEmpty) return;

    final foods = <FoodModel>[];
    for (final id in ids) {
      final food = await _repository.getFoodById(id);
      if (food != null) foods.add(food);
    }

    state = state.copyWith(history: foods);
  }
}

// Recommendation Provider - Uses orchestrator (SRP)
final recommendationProvider =
    StateNotifierProvider<RecommendationNotifier, RecommendationState>((ref) {
  final orchestrator = ref.watch(recommendationOrchestratorProvider);
  final repository = ref.watch(foodRepositoryProvider);
  final historyRepo = ref.watch(historyRepositoryProvider);
  final feedbackLearner = ref.watch(userFeedbackLearnerProvider);
  return RecommendationNotifier(
    orchestrator,
    repository,
    historyRepo,
    feedbackLearner,
  );
});

