import 'dart:math' as math;

import '../../../../models/food_model.dart';
import '../../../../core/services/weather_service.dart';
import '../../../../core/interfaces/time_manager_interface.dart';
import '../../../../core/services/time_manager.dart';
import '../../../../core/utils/logger.dart';
import 'scoring_weights.dart';
import '../interfaces/scorer_interfaces.dart';
import 'location_scorer.dart';
import 'popularity_scorer.dart';
import 'dietary_restriction_scorer.dart';
import 'time_availability_scorer.dart';

// Export DietaryRestriction for use in RecommendationContext
export 'dietary_restriction_scorer.dart' show DietaryRestriction;

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
  final List<DietaryRestriction> dietaryRestrictions; // 🆕 Keto, vegan, halal, etc.
  final String? foodType; // 🆕 "wet" (nước), "dry" (khô), null

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
    this.dietaryRestrictions = const [],
    this.foodType,
  });
  
  /// Create copy with updated values
  RecommendationContext copyWith({
    WeatherData? weather,
    int? budget,
    String? companion,
    String? mood,
    List<String>? excludedFoods,
    List<String>? excludedAllergens,
    List<String>? favoriteCuisines,
    List<String>? recentlyEaten,
    List<String>? blacklistedFoods,
    bool? isVegetarian,
    int? spiceTolerance,
    List<DietaryRestriction>? dietaryRestrictions,
    String? foodType,
  }) {
    return RecommendationContext(
      weather: weather ?? this.weather,
      budget: budget ?? this.budget,
      companion: companion ?? this.companion,
      mood: mood ?? this.mood,
      excludedFoods: excludedFoods ?? this.excludedFoods,
      excludedAllergens: excludedAllergens ?? this.excludedAllergens,
      favoriteCuisines: favoriteCuisines ?? this.favoriteCuisines,
      recentlyEaten: recentlyEaten ?? this.recentlyEaten,
      blacklistedFoods: blacklistedFoods ?? this.blacklistedFoods,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      spiceTolerance: spiceTolerance ?? this.spiceTolerance,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      foodType: foodType ?? this.foodType,
    );
  }
}

/// Engine tính điểm cho món ăn dựa trên ngữ cảnh
/// Follows Dependency Inversion Principle (DIP) - depends on abstractions
class ScoringEngine {
  final ITimeManager _timeManager;
  final ScoringWeights _weights;
  final ILocationScorer _locationScorer;
  final IPopularityScorer _popularityScorer;
  final IDietaryRestrictionScorer _dietaryScorer;
  final ITimeAvailabilityScorer _timeAvailabilityScorer;
  String? _cachedTimeOfDay; // ⚡ Cache time of day across scoring session
  Map<String, double>? _cachedLocationMultipliers; // ⚡ Cache location multipliers
  
  ScoringEngine({
    ScoringWeights? weights,
    ITimeManager? timeManager,
    ILocationScorer? locationScorer,
    IPopularityScorer? popularityScorer,
    IDietaryRestrictionScorer? dietaryScorer,
    ITimeAvailabilityScorer? timeAvailabilityScorer,
  })  : _weights = weights ?? ScoringWeights.defaultWeights,
        _timeManager = timeManager ?? TimeManager(),
        _locationScorer = locationScorer ?? LocationScorer() as ILocationScorer,
        _popularityScorer = popularityScorer ?? PopularityScorer() as IPopularityScorer,
        _dietaryScorer = dietaryScorer ?? DietaryRestrictionScorer() as IDietaryRestrictionScorer,
        _timeAvailabilityScorer = timeAvailabilityScorer ?? TimeAvailabilityScorer() as ITimeAvailabilityScorer;
  
  /// Reset cache when starting new recommendation session
  void resetCache() {
    _cachedTimeOfDay = null;
    _cachedLocationMultipliers = null;
  }
  
  /// Pre-calculate location multipliers for all foods (async)
  /// Call this before scoring to cache location data
  Future<void> precalculateLocationMultipliers(List<FoodModel> foods) async {
    if (_cachedLocationMultipliers == null) {
      _cachedLocationMultipliers = await _locationScorer.preCalculateLocationMultipliers(foods);
    }
  }
  
  /// ⚡ OPTIMIZED: Faster multiplier calculation with caching
  /// Tính điểm cho một món ăn với weighted scoring
  /// Công thức: FINAL_SCORE = (BASE_SCORE * WEIGHTED_MULTIPLIERS) + RANDOM_FACTOR
  double calculateScore(FoodModel food, RecommendationContext context) {
    // Hard filters already passed at this point
    double score = 100.0; // Base score

    // ⚡ Cache time of day (called once per session, not per food)
    _cachedTimeOfDay ??= _timeManager.getTimeOfDay();

    // Weighted multipliers using linear weighting
    // Formula: score *= multiplier * (1 + (weight - 1) * 0.5)
    // This allows weights > 1 to amplify, weights < 1 to reduce impact
    final weatherMultiplier = _getWeatherMultiplier(food, context.weather);
    score *= weatherMultiplier * (1.0 + (_weights.weatherWeight - 1.0) * 0.5);
    
    final companionMultiplier = food.contextScores['companion_${context.companion}'] ?? 1.0;
    score *= companionMultiplier * (1.0 + (_weights.companionWeight - 1.0) * 0.5);
    
    if (context.mood != null) {
      final moodMultiplier = food.contextScores['mood_${context.mood}'] ?? 1.0;
      score *= moodMultiplier * (1.0 + (_weights.moodWeight - 1.0) * 0.5);
    }
    
    final budgetMultiplier = _getBudgetMultiplier(food, context.budget);
    score *= budgetMultiplier * (1.0 + (_weights.budgetWeight - 1.0) * 0.5);
    
    // 🆕 Food type multiplier (wet/dry)
    if (context.foodType != null) {
      final isWetFood = _isWetFood(food);
      if (context.foodType == 'wet' && isWetFood) {
        score *= 1.3; // Boost wet foods if user wants wet
      } else if (context.foodType == 'dry' && !isWetFood) {
        score *= 1.3; // Boost dry foods if user wants dry
      } else {
        score *= 0.7; // Reduce score if doesn't match preference
      }
    }
    
    // 🆕 Spice level multiplier
    if (context.spiceTolerance != null) {
      final foodSpiceLevel = _getFoodSpiceLevel(food);
      final spiceDiff = (foodSpiceLevel - context.spiceTolerance).abs();
      if (spiceDiff == 0) {
        score *= 1.2; // Perfect match
      } else if (spiceDiff == 1) {
        score *= 1.0; // Close match
      } else if (spiceDiff == 2) {
        score *= 0.8; // Somewhat different
      } else {
        score *= 0.5; // Very different
      }
    }
    
    final timeAvailabilityMultiplier = _getTimeAvailabilityMultiplier(food);
    score *= timeAvailabilityMultiplier * (1.0 + (_weights.timeWeight - 1.0) * 0.5);
    
    final timeOfDayMultiplier = food.contextScores['time_$_cachedTimeOfDay'] ?? 1.0;
    score *= timeOfDayMultiplier * (1.0 + (_weights.timeWeight - 1.0) * 0.5);
    
    // Personalization multipliers (weighted)
    if (context.favoriteCuisines.isNotEmpty && context.favoriteCuisines.contains(food.cuisineId)) {
      score *= 1.2 * (1.0 + (_weights.personalizationWeight - 1.0) * 0.5);
    }
    if (context.recentlyEaten.contains(food.id)) {
      score *= 0.7 * (1.0 + (_weights.personalizationWeight - 1.0) * 0.5);
    }
    
    // 🆕 Location scoring (from cache)
    final locationMultiplier = _cachedLocationMultipliers?[food.id] ?? 1.0;
    score *= locationMultiplier * (1.0 + (_weights.popularityWeight - 1.0) * 0.5);
    
    // 🆕 Popularity scoring
    final popularityMultiplier = _popularityScorer.getCombinedMultiplier(food);
    score *= popularityMultiplier * (1.0 + (_weights.popularityWeight - 1.0) * 0.5);
    
    // 🆕 Dietary restrictions scoring
    if (context.dietaryRestrictions.isNotEmpty) {
      final dietaryMultiplier = _dietaryScorer.getDietaryMultiplier(
        food,
        context.dietaryRestrictions,
      );
      score *= dietaryMultiplier; // Hard filter if doesn't match
    }
    
    // 🆕 Enhanced time availability scoring
    final enhancedTimeMultiplier = _timeAvailabilityScorer.getAvailabilityMultiplier(food);
    score *= enhancedTimeMultiplier * (1.0 + (_weights.timeWeight - 1.0) * 0.5);

    // Random factor (0-10% để tạo sự đa dạng)
    score += score * 0.1 * math.Random().nextDouble();

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
    
    // 🆕 Check dietary restrictions (hard filter)
    if (context.dietaryRestrictions.isNotEmpty) {
      final dietaryScorer = DietaryRestrictionScorer();
      if (!dietaryScorer.matchesRestrictions(food, context.dietaryRestrictions)) {
        return false;
      }
    }
    
    // 🆕 Check food type (wet/dry) - soft filter (prefer matching but allow others)
    if (context.foodType != null) {
      final isWetFood = _isWetFood(food);
      if (context.foodType == 'wet' && !isWetFood) {
        // Prefer wet foods but don't hard filter
        // Will be handled in scoring
      } else if (context.foodType == 'dry' && isWetFood) {
        // Prefer dry foods but don't hard filter
        // Will be handled in scoring
      }
    }
    
    return true;
  }
  
  /// 🆕 Check if food is wet (nước) or dry (khô)
  /// Dựa vào searchKeywords và flavorProfile
  bool _isWetFood(FoodModel food) {
    final wetKeywords = ['nước', 'súp', 'canh', 'lẩu', 'phở', 'bún', 'miến', 'cháo', 'nước dùng'];
    final dryKeywords = ['khô', 'rán', 'nướng', 'chiên', 'xào', 'bánh', 'cơm', 'mì'];
    
    // Check searchKeywords
    for (final keyword in food.searchKeywords) {
      final lowerKeyword = keyword.toLowerCase();
      if (wetKeywords.any((w) => lowerKeyword.contains(w))) {
        return true;
      }
      if (dryKeywords.any((d) => lowerKeyword.contains(d))) {
        return false;
      }
    }
    
    // Check flavorProfile
    for (final profile in food.flavorProfile) {
      final lowerProfile = profile.toLowerCase();
      if (wetKeywords.any((w) => lowerProfile.contains(w))) {
        return true;
      }
      if (dryKeywords.any((d) => lowerProfile.contains(d))) {
        return false;
      }
    }
    
    // Check description
    final lowerDesc = food.description.toLowerCase();
    if (wetKeywords.any((w) => lowerDesc.contains(w))) {
      return true;
    }
    if (dryKeywords.any((d) => lowerDesc.contains(d))) {
      return false;
    }
    
    // Default: assume dry if unclear
    return false;
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
  
  /// 🆕 Get food spice level (0-5) based on flavorProfile and searchKeywords
  int _getFoodSpiceLevel(FoodModel food) {
    final spiceKeywords = {
      'không cay': 0,
      'nhẹ': 1,
      'vừa': 2,
      'cay': 3,
      'rất cay': 4,
      'cực cay': 5,
      'spicy': 3,
      'mild': 1,
      'hot': 4,
    };
    
    // Check searchKeywords
    for (final keyword in food.searchKeywords) {
      final lowerKeyword = keyword.toLowerCase();
      for (final entry in spiceKeywords.entries) {
        if (lowerKeyword.contains(entry.key)) {
          return entry.value;
        }
      }
    }
    
    // Check flavorProfile
    for (final profile in food.flavorProfile) {
      final lowerProfile = profile.toLowerCase();
      for (final entry in spiceKeywords.entries) {
        if (lowerProfile.contains(entry.key)) {
          return entry.value;
        }
      }
    }
    
    // Check contextScores
    final spiceScore = food.contextScores['spice_level'];
    if (spiceScore != null) {
      return spiceScore.round().clamp(0, 5);
    }
    
    // Default: medium spice (2)
    return 2;
  }


  /// ⚡ OPTIMIZED: Two-pass strategy with lazy evaluation
  /// Pass 1: Fast hard filters
  /// Pass 2: Score only qualified foods with early exit
  Future<List<FoodModel>> getTopFoods(
    List<FoodModel> foods,
    RecommendationContext context,
    int topN,
  ) async {
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
    
    // 🆕 Pre-calculate location multipliers (async, but cache for session)
    await precalculateLocationMultipliers(qualified);
    
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

