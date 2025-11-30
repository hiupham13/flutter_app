import '../../../../models/food_model.dart';
import '../../../../core/services/weather_service.dart';

/// Context input cho thuật toán gợi ý
class RecommendationContext {
  final WeatherData? weather;
  final int budget; // 1: Cheap, 2: Mid, 3: High
  final String companion; // "alone", "date", "group"
  final String? mood; // "normal", "stress", "sick"
  final List<String> excludedFoods;
  final List<String> excludedAllergens;

  RecommendationContext({
    this.weather,
    required this.budget,
    required this.companion,
    this.mood,
    this.excludedFoods = const [],
    this.excludedAllergens = const [],
  });
}

/// Engine tính điểm cho món ăn dựa trên ngữ cảnh
class ScoringEngine {
  /// Tính điểm cho một món ăn
  /// Công thức: FINAL_SCORE = (BASE_SCORE * MULTIPLIERS) + RANDOM_FACTOR
  double calculateScore(FoodModel food, RecommendationContext context) {
    // Hard filters - Loại bỏ ngay nếu không phù hợp
    if (!_passHardFilters(food, context)) {
      return 0.0;
    }

    double score = 100.0; // Base score

    // Context multipliers
    score *= _getWeatherMultiplier(food, context.weather);
    score *= _getCompanionMultiplier(food, context.companion);
    score *= _getMoodMultiplier(food, context.mood);
    score *= _getBudgetMultiplier(food, context.budget);

    // Random factor (0-10% để tạo sự đa dạng)
    final randomFactor = (score * 0.1 * (0.5 + (DateTime.now().millisecond % 100) / 100));
    score += randomFactor;

    return score;
  }

  /// Kiểm tra hard filters
  bool _passHardFilters(FoodModel food, RecommendationContext context) {
    // Kiểm tra món có active không
    if (!food.isActive) return false;

    // Kiểm tra budget
    if (food.priceSegment > context.budget) return false;

    // Kiểm tra excluded foods
    if (context.excludedFoods.contains(food.id)) return false;

    // Kiểm tra allergens
    for (final allergen in context.excludedAllergens) {
      if (food.allergenTags.contains(allergen)) return false;
    }

    return true;
  }

  /// Tính multiplier dựa trên thời tiết
  double _getWeatherMultiplier(FoodModel food, WeatherData? weather) {
    if (weather == null) return 1.0;

    // Sử dụng context_scores từ food model nếu có
    if (weather.isHot) {
      return food.contextScores['weather_hot'] ?? 0.8;
    } else if (weather.isRainy) {
      return food.contextScores['weather_rain'] ?? 1.5;
    } else if (weather.isCold) {
      return food.contextScores['weather_cold'] ?? 1.2;
    }

    return 1.0;
  }

  /// Tính multiplier dựa trên người đi cùng
  double _getCompanionMultiplier(FoodModel food, String companion) {
    final key = 'companion_$companion';
    return food.contextScores[key] ?? 1.0;
  }

  /// Tính multiplier dựa trên tâm trạng
  double _getMoodMultiplier(FoodModel food, String? mood) {
    if (mood == null) return 1.0;

    final key = 'mood_$mood';
    return food.contextScores[key] ?? 1.0;
  }

  /// Tính multiplier dựa trên budget
  double _getBudgetMultiplier(FoodModel food, int budget) {
    // Nếu món rẻ hơn budget thì tăng điểm nhẹ
    if (food.priceSegment < budget) {
      return 1.1;
    }
    // Nếu đúng budget thì giữ nguyên
    if (food.priceSegment == budget) {
      return 1.0;
    }
    // Nếu vượt budget thì đã bị loại ở hard filter
    return 0.0;
  }

  /// Sắp xếp và lấy top N món ăn
  List<FoodModel> getTopFoods(
    List<FoodModel> foods,
    RecommendationContext context,
    int topN,
  ) {
    final scoredFoods = foods.map((food) {
      return MapEntry(food, calculateScore(food, context));
    }).toList();

    scoredFoods.sort((a, b) => b.value.compareTo(a.value));

    return scoredFoods
        .take(topN)
        .where((entry) => entry.value > 0)
        .map((entry) => entry.key)
        .toList();
  }
}

