import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/food_model.dart';
import '../data/repositories/food_repository.dart';
import 'scoring_engine.dart';
import '../data/repositories/history_repository.dart';

// Repository Provider
final foodRepositoryProvider = Provider<FoodRepository>((ref) {
  return FoodRepository();
});

// Scoring Engine Provider
final scoringEngineProvider = Provider<ScoringEngine>((ref) {
  return ScoringEngine();
});

// History Repository Provider
final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository();
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

// Recommendation Notifier
class RecommendationNotifier extends StateNotifier<RecommendationState> {
  final FoodRepository _repository;
  final ScoringEngine _scoringEngine;
  final HistoryRepository _historyRepository;

  RecommendationNotifier(
    this._repository,
    this._scoringEngine,
    this._historyRepository,
  )
      : super(RecommendationState());

  Future<void> getRecommendations(RecommendationContext context,
      {int topN = 5, required String userId}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Lấy tất cả món ăn
      final allFoods = await _repository.getAllFoods();

      if (allFoods.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'Không tìm thấy món ăn nào',
        );
        return;
      }

      // Tính điểm và lấy top N (default 5 để re-roll thoải mái)
      final topFoods = _scoringEngine.getTopFoods(allFoods, context, topN);

      if (topFoods.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'Không có món ăn phù hợp với yêu cầu',
        );
        return;
      }

      // Tăng view count cho món đầu tiên
      await _repository.incrementViewCount(topFoods.first.id);

      // Lưu history lên Firestore (best-effort)
      await _historyRepository.addHistory(
        userId: userId,
        food: topFoods.first,
        context: context,
      );

      final updatedHistory = [
        topFoods.first,
        ...state.history.where((f) => f.id != topFoods.first.id),
      ];

      state = state.copyWith(
        recommendedFoods: topFoods,
        currentFood: topFoods.first,
        isLoading: false,
        history: updatedHistory,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Lỗi khi lấy gợi ý: $e',
      );
    }
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

// Recommendation Provider
final recommendationProvider =
    StateNotifierProvider<RecommendationNotifier, RecommendationState>((ref) {
  final repository = ref.watch(foodRepositoryProvider);
  final engine = ref.watch(scoringEngineProvider);
  final historyRepo = ref.watch(historyRepositoryProvider);
  return RecommendationNotifier(repository, engine, historyRepo);
});

