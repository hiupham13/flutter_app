import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/food_model.dart';
import '../data/repositories/food_repository.dart';
import 'scoring_engine.dart';
import '../../../../core/services/weather_service.dart';

// Repository Provider
final foodRepositoryProvider = Provider<FoodRepository>((ref) {
  return FoodRepository();
});

// Scoring Engine Provider
final scoringEngineProvider = Provider<ScoringEngine>((ref) {
  return ScoringEngine();
});

// Recommendation State
class RecommendationState {
  final List<FoodModel> recommendedFoods;
  final FoodModel? currentFood;
  final bool isLoading;
  final String? error;

  RecommendationState({
    this.recommendedFoods = const [],
    this.currentFood,
    this.isLoading = false,
    this.error,
  });

  RecommendationState copyWith({
    List<FoodModel>? recommendedFoods,
    FoodModel? currentFood,
    bool? isLoading,
    String? error,
  }) {
    return RecommendationState(
      recommendedFoods: recommendedFoods ?? this.recommendedFoods,
      currentFood: currentFood ?? this.currentFood,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Recommendation Notifier
class RecommendationNotifier extends StateNotifier<RecommendationState> {
  final FoodRepository _repository;
  final ScoringEngine _scoringEngine;

  RecommendationNotifier(this._repository, this._scoringEngine)
      : super(RecommendationState());

  Future<void> getRecommendations(RecommendationContext context) async {
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

      // Tính điểm và lấy top 3
      final topFoods = _scoringEngine.getTopFoods(allFoods, context, 3);

      if (topFoods.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'Không có món ăn phù hợp với yêu cầu',
        );
        return;
      }

      // Tăng view count cho món đầu tiên
      await _repository.incrementViewCount(topFoods.first.id);

      state = state.copyWith(
        recommendedFoods: topFoods,
        currentFood: topFoods.first,
        isLoading: false,
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
}

// Recommendation Provider
final recommendationProvider =
    StateNotifierProvider<RecommendationNotifier, RecommendationState>((ref) {
  final repository = ref.watch(foodRepositoryProvider);
  final engine = ref.watch(scoringEngineProvider);
  return RecommendationNotifier(repository, engine);
});

