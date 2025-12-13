import 'package:hive/hive.dart';
import '../../models/food_model.dart';
import '../utils/logger.dart';

/// Persistent cache service using Hive
/// Provides TTL (Time-To-Live) management and version control
class CacheService {
  static const String _foodBoxName = 'foods_cache';
  static const String _metaBoxName = 'cache_meta';
  static const Duration _defaultTtl = Duration(hours: 24);
  
  Box<FoodModel>? _foodBox;
  Box<dynamic>? _metaBox;
  Duration ttl;
  
  // Singleton pattern
  static final CacheService _instance = CacheService._internal();
  factory CacheService({Duration? ttlOverride}) {
    if (ttlOverride != null) {
      _instance.ttl = ttlOverride;
    }
    return _instance;
  }
  
  CacheService._internal() : ttl = _defaultTtl;
  
  /// Initialize Hive boxes
  /// Must be called before using the cache
  Future<void> init() async {
    try {
      _foodBox = await Hive.openBox<FoodModel>(_foodBoxName);
      _metaBox = await Hive.openBox(_metaBoxName);
      AppLogger.info('CacheService initialized successfully');
    } catch (e, st) {
      AppLogger.error('CacheService init failed: $e', e, st);
      rethrow;
    }
  }
  
  /// Save foods to persistent cache with timestamp
  Future<void> saveFoodsToCache(List<FoodModel> foods) async {
    if (_foodBox == null || _metaBox == null) {
      AppLogger.warning('CacheService not initialized, skipping save');
      return;
    }
    
    try {
      // Clear existing cache
      await _foodBox!.clear();
      
      // Save each food item
      for (var food in foods) {
        await _foodBox!.put(food.id, food);
      }
      
      // Update metadata
      await _metaBox!.put('last_updated', DateTime.now().millisecondsSinceEpoch);
      await _metaBox!.put('version', 1);
      await _metaBox!.put('count', foods.length);
      
      AppLogger.info('Saved ${foods.length} foods to cache');
    } catch (e, st) {
      AppLogger.error('saveFoodsToCache failed: $e', e, st);
    }
  }
  
  /// Retrieve foods from cache
  /// Returns empty list if cache is invalid or expired
  Future<List<FoodModel>> getFoodsFromCache() async {
    if (_foodBox == null) {
      AppLogger.warning('CacheService not initialized');
      return [];
    }
    
    if (!isCacheValid()) {
      AppLogger.info('Cache expired or invalid');
      return [];
    }
    
    try {
      final foods = _foodBox!.values.toList();
      AppLogger.info('Retrieved ${foods.length} foods from cache');
      return foods;
    } catch (e, st) {
      AppLogger.error('getFoodsFromCache failed: $e', e, st);
      return [];
    }
  }
  
  /// Check if cache is still valid (not expired)
  bool isCacheValid() {
    if (_metaBox == null) return false;
    
    final lastUpdated = _metaBox!.get('last_updated') as int?;
    if (lastUpdated == null) return false;
    
    final lastUpdatedTime = DateTime.fromMillisecondsSinceEpoch(lastUpdated);
    final age = DateTime.now().difference(lastUpdatedTime);
    
    final isValid = age <= ttl && (_foodBox?.isNotEmpty ?? false);
    
    if (!isValid) {
      AppLogger.debug('Cache invalid: age=${age.inMinutes}min, ttl=${ttl.inMinutes}min');
    }
    
    return isValid;
  }
  
  /// Clear all cached data
  Future<void> clearCache() async {
    if (_foodBox == null || _metaBox == null) {
      AppLogger.warning('CacheService not initialized');
      return;
    }
    
    try {
      await _foodBox!.clear();
      await _metaBox!.clear();
      AppLogger.info('Cache cleared successfully');
    } catch (e, st) {
      AppLogger.error('clearCache failed: $e', e, st);
    }
  }
  
  /// Get current cache version
  int get cacheVersion {
    if (_metaBox == null) return 0;
    return _metaBox!.get('version', defaultValue: 0) as int;
  }
  
  /// Get cache age in minutes
  int get cacheAgeMinutes {
    if (_metaBox == null) return -1;
    
    final lastUpdated = _metaBox!.get('last_updated') as int?;
    if (lastUpdated == null) return -1;
    
    final lastUpdatedTime = DateTime.fromMillisecondsSinceEpoch(lastUpdated);
    return DateTime.now().difference(lastUpdatedTime).inMinutes;
  }
  
  /// Get number of cached items
  int get cachedItemsCount {
    if (_foodBox == null) return 0;
    return _foodBox!.length;
  }
  
  /// Invalidate cache if version doesn't match
  Future<void> invalidateIfVersionMismatch(int serverVersion) async {
    if (cacheVersion < serverVersion) {
      AppLogger.info('Cache version mismatch: local=$cacheVersion, server=$serverVersion');
      await clearCache();
    }
  }
  
  /// Get cache statistics for debugging
  Map<String, dynamic> getCacheStats() {
    return {
      'initialized': _foodBox != null && _metaBox != null,
      'valid': isCacheValid(),
      'version': cacheVersion,
      'items_count': cachedItemsCount,
      'age_minutes': cacheAgeMinutes,
      'ttl_minutes': ttl.inMinutes,
    };
  }
  
  /// Close boxes (call on app dispose)
  Future<void> dispose() async {
    try {
      await _foodBox?.close();
      await _metaBox?.close();
      AppLogger.info('CacheService disposed');
    } catch (e, st) {
      AppLogger.error('CacheService dispose failed: $e', e, st);
    }
  }
}
