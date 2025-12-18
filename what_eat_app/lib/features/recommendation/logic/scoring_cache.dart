import '../../../../models/food_model.dart';
import 'scoring_engine.dart';
import '../../../../core/utils/logger.dart';

/// Cache entry for scoring results
class ScoringCacheEntry {
  final List<FoodModel> foods;
  final RecommendationContext context;
  final int topN;
  final List<FoodModel> result;
  final DateTime timestamp;
  
  ScoringCacheEntry({
    required this.foods,
    required this.context,
    required this.topN,
    required this.result,
    required this.timestamp,
  });
  
  /// Check if cache entry is still valid
  bool isValid({Duration maxAge = const Duration(minutes: 5)}) {
    return DateTime.now().difference(timestamp) < maxAge;
  }
  
  /// Check if cache entry matches query
  bool matches(
    List<FoodModel> foods,
    RecommendationContext context,
    int topN,
  ) {
    // Simple matching: same food count, same context key fields, same topN
    if (this.foods.length != foods.length) return false;
    if (this.topN != topN) return false;
    
    // Check context key fields
    if (this.context.budget != context.budget) return false;
    if (this.context.companion != context.companion) return false;
    if (this.context.mood != context.mood) return false;
    if (this.context.isVegetarian != context.isVegetarian) return false;
    
    // Check excluded foods/allergens (simplified - just check count)
    if (this.context.excludedFoods.length != context.excludedFoods.length) {
      return false;
    }
    if (this.context.excludedAllergens.length != context.excludedAllergens.length) {
      return false;
    }
    
    return true;
  }
}

/// Cache for scoring results to improve performance
class ScoringCache {
  final Map<String, ScoringCacheEntry> _cache = {};
  final Duration _defaultMaxAge;
  
  ScoringCache({Duration? maxAge})
      : _defaultMaxAge = maxAge ?? const Duration(minutes: 5);
  
  /// Generate cache key from context
  String _generateCacheKey(RecommendationContext context, int topN) {
    // Simple key based on key context fields
    return '${context.budget}_${context.companion}_${context.mood ?? "null"}_'
           '${context.isVegetarian}_${context.excludedFoods.length}_'
           '${context.excludedAllergens.length}_$topN';
  }
  
  /// Get cached result if available and valid
  List<FoodModel>? getCachedResult(
    List<FoodModel> foods,
    RecommendationContext context,
    int topN,
  ) {
    final key = _generateCacheKey(context, topN);
    final entry = _cache[key];
    
    if (entry == null) {
      return null; // No cache
    }
    
    if (!entry.isValid(maxAge: _defaultMaxAge)) {
      _cache.remove(key); // Expired
      return null;
    }
    
    if (!entry.matches(foods, context, topN)) {
      return null; // Doesn't match
    }
    
    AppLogger.debug('✅ Cache hit for key: $key');
    return entry.result;
  }
  
  /// Store result in cache
  void cacheResult(
    List<FoodModel> foods,
    RecommendationContext context,
    int topN,
    List<FoodModel> result,
  ) {
    final key = _generateCacheKey(context, topN);
    
    _cache[key] = ScoringCacheEntry(
      foods: foods,
      context: context,
      topN: topN,
      result: result,
      timestamp: DateTime.now(),
    );
    
    AppLogger.debug('💾 Cached result for key: $key');
    
    // Clean up old entries if cache gets too large
    if (_cache.length > 50) {
      _cleanup();
    }
  }
  
  /// Clean up expired entries
  void _cleanup() {
    _cache.removeWhere((key, entry) => !entry.isValid(maxAge: _defaultMaxAge));
    AppLogger.debug('🧹 Cleaned up cache, ${_cache.length} entries remaining');
  }
  
  /// Clear all cache
  void clear() {
    _cache.clear();
    AppLogger.debug('🗑️ Cache cleared');
  }
  
  /// Get cache stats
  Map<String, dynamic> getStats() {
    return {
      'size': _cache.length,
      'maxAge': _defaultMaxAge.inMinutes,
    };
  }
}

