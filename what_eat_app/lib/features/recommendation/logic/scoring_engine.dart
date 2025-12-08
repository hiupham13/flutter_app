import 'dart:math';

import '../../../../models/food_model.dart';
import '../../../../core/services/weather_service.dart';
import '../../../../core/services/time_manager.dart';
import '../../../../core/utils/logger.dart';

/// Context input cho thuật toán gợi ý
class RecommendationContext {
  final WeatherData? weather;
  final int budget; // 1: Cheap, 2: Mid, 3: High
  final String companion; // "alone", "date", "group"
  final String? mood; // "normal", "stress", "sick"
  final List<String> excludedFoods;
  final List<String> excludedAllergens;
  final List<String> favoriteCuisines;
  final List<String> recentlyEaten;
  final List<String> blacklistedFoods;
  final bool isVegetarian;
  final int spiceTolerance; // 0-5

  RecommendationContext({
    this.weather,
    required this.budget,
    required this.companion,
    this.mood,
    this.excludedFoods = const [],
    this.excludedAllergens = const [],
    this.favoriteCuisines = const [],
    this.recentlyEaten = const [],
    this.blacklistedFoods = const [],
    this.isVegetarian = false,
    this.spiceTolerance = 2,
  });
}

/// Engine tính điểm cho món ăn dựa trên ngữ cảnh
class ScoringEngine {
  final TimeManager _timeManager = TimeManager();
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
    score *= _getTimeAvailabilityMultiplier(food);
    score *= _getTimeOfDayMultiplier(food);
    score *= _getCuisinePreferenceMultiplier(food, context.favoriteCuisines);
    score *= _getRecentlyEatenPenalty(food, context.recentlyEaten);
    score *= _getVegetarianMultiplier(food, context.isVegetarian);

    // Random factor (0-10% để tạo sự đa dạng)
    final random = Random();
    final randomFactor = score * 0.1 * random.nextDouble();
    score += randomFactor;

    return score;
  }

  /// Kiểm tra hard filters
  bool _passHardFilters(FoodModel food, RecommendationContext context) {
    // Kiểm tra món có active không
    if (!food.isActive) {
      AppLogger.debug('Food ${food.id} filtered: not active');
      return false;
    }

    // Kiểm tra budget - Cho phép món có giá cao hơn budget một chút (flexible)
    // Nếu budget = 1, cho phép món segment 2 nhưng điểm sẽ thấp
    // Chỉ loại bỏ nếu vượt quá nhiều (segment > budget + 1)
    if (food.priceSegment > context.budget + 1) {
      AppLogger.debug('Food ${food.id} filtered: priceSegment ${food.priceSegment} > budget ${context.budget} + 1');
      return false;
    }

    // Kiểm tra available times - Chỉ loại bỏ nếu có thông tin và không khớp
    // Nếu availableTimes rỗng hoặc null → Cho phép bán mọi lúc (flexible)
    final currentTime = _timeManager.getTimeOfDay();
    if (food.availableTimes.isNotEmpty && !food.availableTimes.contains(currentTime)) {
      // Không loại bỏ hoàn toàn, chỉ log để biết
      // Sẽ giảm điểm ở multiplier thay vì loại bỏ
      AppLogger.debug('Food ${food.id} not ideal at $currentTime (available: ${food.availableTimes}), but allowing with lower score');
      // Không return false, để món vẫn pass nhưng điểm sẽ thấp hơn
    }

    // Kiểm tra excluded foods
    if (context.excludedFoods.contains(food.id) ||
        context.blacklistedFoods.contains(food.id)) {
      AppLogger.debug('Food ${food.id} filtered: in excluded foods');
      return false;
    }

    // Kiểm tra allergens
    for (final allergen in context.excludedAllergens) {
      if (food.allergenTags.contains(allergen)) {
        AppLogger.debug('Food ${food.id} filtered: contains allergen $allergen');
        return false;
      }
    }

    // Kiểm tra vegetarian (nếu user chọn ăn chay và món không đánh dấu)
    if (context.isVegetarian) {
      final isVegetarianFood =
          food.flavorProfile.contains('vegetarian') || food.contextScores['is_vegetarian'] == 1.0;
      if (!isVegetarianFood) {
        AppLogger.debug('Food ${food.id} filtered: user is vegetarian');
        return false;
      }
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
    // Nếu cao hơn budget một chút (segment = budget + 1) thì giảm điểm nhưng vẫn cho phép
    if (food.priceSegment == budget + 1) {
      return 0.7; // Giảm điểm nhưng vẫn pass
    }
    // Nếu vượt quá nhiều thì đã bị loại ở hard filter
    return 0.0;
  }

  /// Tính multiplier dựa trên available times
  /// Nếu món không bán ở khung giờ hiện tại → Giảm điểm nhưng vẫn cho phép
  double _getTimeAvailabilityMultiplier(FoodModel food) {
    final currentTime = _timeManager.getTimeOfDay();
    
    // Nếu không có thông tin available times → Cho phép mọi lúc (multiplier = 1.0)
    if (food.availableTimes.isEmpty) {
      return 1.0;
    }
    
    // Nếu bán ở khung giờ hiện tại → Giữ nguyên điểm
    if (food.availableTimes.contains(currentTime)) {
      return 1.0;
    }
    
    // Nếu không bán ở khung giờ hiện tại → Giảm điểm nhưng vẫn cho phép
    // (Vì có thể user vẫn muốn ăn món đó dù không phải giờ bán chính)
    return 0.6; // Giảm 40% điểm nhưng vẫn pass
  }

  /// Tính multiplier dựa trên time of day preference (context_scores key: time_morning/lunch/dinner/late_night)
  double _getTimeOfDayMultiplier(FoodModel food) {
    final currentTime = _timeManager.getTimeOfDay();
    final key = 'time_$currentTime';
    return food.contextScores[key] ?? 1.0;
  }

  /// Ưu tiên cuisine ưa thích của user
  double _getCuisinePreferenceMultiplier(FoodModel food, List<String> favoriteCuisines) {
    if (favoriteCuisines.isEmpty) return 1.0;
    if (favoriteCuisines.contains(food.cuisineId)) {
      return 1.2;
    }
    return 1.0;
  }

  /// Giảm điểm cho món vừa ăn gần đây để tránh lặp
  double _getRecentlyEatenPenalty(FoodModel food, List<String> recentlyEaten) {
    if (recentlyEaten.contains(food.id)) {
      return 0.7;
    }
    return 1.0;
  }

  /// Penalty nhẹ nếu món không phù hợp khẩu vị chay (đã lọc ở hard filters khi chắc chắn)
  double _getVegetarianMultiplier(FoodModel food, bool isVegetarian) {
    if (!isVegetarian) return 1.0;
    final isVegetarianFood =
        food.flavorProfile.contains('vegetarian') || food.contextScores['is_vegetarian'] == 1.0;
    return isVegetarianFood ? 1.0 : 0.0;
  }

  /// Sắp xếp và lấy top N món ăn
  List<FoodModel> getTopFoods(
    List<FoodModel> foods,
    RecommendationContext context,
    int topN,
  ) {
    AppLogger.info('Scoring ${foods.length} foods with context: budget=${context.budget}, companion=${context.companion}, mood=${context.mood}');
    
    final scoredFoods = foods.map((food) {
      final score = calculateScore(food, context);
      if (score > 0) {
        AppLogger.debug('Food ${food.id} (${food.name}): score=$score');
      }
      return MapEntry(food, score);
    }).toList();

    scoredFoods.sort((a, b) => b.value.compareTo(a.value));

    final topFoods = scoredFoods
        .take(topN)
        .where((entry) => entry.value > 0)
        .map((entry) => entry.key)
        .toList();
    
    AppLogger.info('Found ${topFoods.length} foods after filtering');
    
    return topFoods;
  }
}

