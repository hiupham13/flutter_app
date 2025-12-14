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
  String? _cachedTimeOfDay; // ⚡ Cache time of day across scoring session
  
  /// Reset cache when starting new recommendation session
  void resetCache() {
    _cachedTimeOfDay = null;
  }
  
  /// ⚡ OPTIMIZED: Faster multiplier calculation with caching
  /// Tính điểm cho một món ăn
  /// Công thức: FINAL_SCORE = (BASE_SCORE * MULTIPLIERS) + RANDOM_FACTOR
  double calculateScore(FoodModel food, RecommendationContext context) {
    // Hard filters already passed at this point
    double score = 100.0; // Base score

    // ⚡ Cache time of day (called once per session, not per food)
    _cachedTimeOfDay ??= _timeManager.getTimeOfDay();

    // Fast multipliers using direct map lookups
    score *= _getWeatherMultiplier(food, context.weather);
    score *= food.contextScores['companion_${context.companion}'] ?? 1.0;
    score *= context.mood != null ? (food.contextScores['mood_${context.mood}'] ?? 1.0) : 1.0;
    score *= _getBudgetMultiplier(food, context.budget);
    score *= _getTimeAvailabilityMultiplier(food);
    score *= food.contextScores['time_$_cachedTimeOfDay'] ?? 1.0;
    
    // Simple inline multipliers
    if (context.favoriteCuisines.isNotEmpty && context.favoriteCuisines.contains(food.cuisineId)) {
      score *= 1.2;
    }
    if (context.recentlyEaten.contains(food.id)) {
      score *= 0.7;
    }

    // Random factor (0-10% để tạo sự đa dạng)
    score += score * 0.1 * Random().nextDouble();

    return score;
  }

  /// ⚡ OPTIMIZED: Fast hard filters without logging overhead
  /// Kiểm tra hard filters - Loại bỏ ngay nếu không phù hợp
  bool _passHardFilters(FoodModel food, RecommendationContext context) {
    // Fast checks without logging
    if (!food.isActive) return false;
    if (food.priceSegment > context.budget + 1) return false;
    if (context.excludedFoods.contains(food.id)) return false;
    if (context.blacklistedFoods.contains(food.id)) return false;
    
    // Check allergens
    for (final allergen in context.excludedAllergens) {
      if (food.allergenTags.contains(allergen)) return false;
    }
    
    // Check vegetarian
    if (context.isVegetarian) {
      final isVegetarianFood = food.flavorProfile.contains('vegetarian') ||
                               food.contextScores['is_vegetarian'] == 1.0;
      if (!isVegetarianFood) return false;
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


  /// ⚡ OPTIMIZED: Two-pass strategy with lazy evaluation
  /// Pass 1: Fast hard filters
  /// Pass 2: Score only qualified foods with early exit
  List<FoodModel> getTopFoods(
    List<FoodModel> foods,
    RecommendationContext context,
    int topN,
  ) {
    AppLogger.info('⚡ Filtering ${foods.length} foods...');
    
    // Reset cache for new session
    resetCache();
    
    // ⚡ PASS 1: Fast hard filters (cheap operations)
    final qualified = <FoodModel>[];
    for (final food in foods) {
      if (_passHardFilters(food, context)) {
        qualified.add(food);
      }
    }
    
    AppLogger.info('⚡ ${qualified.length} foods passed hard filters');
    
    if (qualified.isEmpty) return [];
    
    // ⚡ PASS 2: Score qualified foods with early exit
    final candidates = <MapEntry<FoodModel, double>>[];
    int scored = 0;
    
    for (final food in qualified) {
      final score = calculateScore(food, context);
      if (score > 0) {
        candidates.add(MapEntry(food, score));
        scored++;
      }
      
      // ⚡ Early exit: Stop when we have enough good candidates
      // Buffer of 3x to ensure variety after sorting
      if (candidates.length >= topN * 3) {
        AppLogger.debug('⚡ Early exit: ${candidates.length} candidates after scoring $scored foods');
        break;
      }
    }
    
    AppLogger.info('⚡ Scored $scored foods, ${candidates.length} valid candidates');
    
    // ⚡ Partial sort: Only sort candidates (not all foods)
    candidates.sort((a, b) => b.value.compareTo(a.value));
    
    final result = candidates.take(topN).map((e) => e.key).toList();
    AppLogger.info('⚡ Returning top ${result.length} foods');
    
    return result;
  }
}

