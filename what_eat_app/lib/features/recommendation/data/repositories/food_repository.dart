import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/food_model.dart';
import '../sources/food_firestore_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/services/cache_service.dart';

/// Provider for FoodRepository singleton
final foodRepositoryProvider = Provider<FoodRepository>((ref) {
  return FoodRepository();
});

class FoodRepository {
  final FoodDataSource _dataSource;
  final CacheService _cache;

  FoodRepository({FoodDataSource? dataSource, CacheService? cache})
      : _dataSource = dataSource ?? FoodFirestoreService(),
        _cache = cache ?? CacheService();

  /// Lọc món ăn local (support test & offline)
  List<FoodModel> filterFoodsLocal(
    List<FoodModel> foods, {
    int? budget,
    String? cuisineId,
    String? mealTypeId,
    String? keyword,
  }) {
    return foods.where((food) {
      if (budget != null && food.priceSegment > budget + 1) return false;
      if (cuisineId != null && food.cuisineId != cuisineId) return false;
      if (mealTypeId != null && food.mealTypeId != mealTypeId) return false;
      if (keyword != null && keyword.isNotEmpty) {
        final lower = keyword.toLowerCase();
        final nameHit = food.name.toLowerCase().contains(lower);
        final searchHit = food.searchKeywords
            .any((kw) => kw.toLowerCase().contains(lower));
        if (!nameHit && !searchHit) return false;
      }
      return true;
    }).toList();
  }

  /// Lấy tất cả món ăn với offline-first strategy
  ///
  /// Strategy:
  /// 1. Try valid cache first (return immediately + background sync)
  /// 2. If cache invalid, fetch from Firestore
  /// 3. If Firestore fails, fallback to stale cache
  Future<List<FoodModel>> getAllFoods() async {
    List<FoodModel> cachedFoods = const [];
    
    try {
      // 1️⃣ TRY CACHE FIRST (Ưu tiên cache)
      cachedFoods = await _cache.getFoodsFromCache();
      if (cachedFoods.isNotEmpty && _cache.isCacheValid()) {
        AppLogger.info('✅ Using valid cache (${cachedFoods.length} items, age: ${_cache.cacheAgeMinutes}min)');
        
        // 2️⃣ BACKGROUND SYNC (Không block UI)
        _syncInBackground();
        
        return cachedFoods; // ⚡ Return ngay
      }
      
      // 3️⃣ FETCH FROM FIRESTORE
      AppLogger.info('📡 Fetching foods from Firestore (cache invalid)...');
      final foods = await _dataSource.fetchAllFoods();
      
      if (foods.isEmpty) {
        AppLogger.warning('Firestore returned empty list');
        // Fallback to stale cache if available
        if (cachedFoods.isNotEmpty) {
          AppLogger.info('Using stale cache as fallback (${cachedFoods.length} items)');
          return cachedFoods;
        }
        return [];
      }
      
      // 4️⃣ SAVE TO CACHE
      await _cache.saveFoodsToCache(foods);
      AppLogger.info('✅ Fetched and cached ${foods.length} foods');
      
      return foods;
      
    } catch (e, st) {
      AppLogger.error('getAllFoods failed: $e', e, st);
      
      // 5️⃣ FALLBACK TO STALE CACHE (Better than nothing)
      if (cachedFoods.isNotEmpty) {
        AppLogger.warning('⚠️ Using stale cache as fallback (${cachedFoods.length} items)');
        return cachedFoods;
      }
      
      return [];
    }
  }
  
  /// Background sync - Fire and forget
  /// Updates cache without blocking UI
  Future<void> _syncInBackground() async {
    try {
      AppLogger.debug('🔄 Background sync started');
      final foods = await _dataSource.fetchAllFoods();
      
      if (foods.isNotEmpty) {
        await _cache.saveFoodsToCache(foods);
        AppLogger.info('✅ Background sync completed (${foods.length} items)');
      }
    } catch (e) {
      // Silent fail - background sync is best-effort
      AppLogger.debug('Background sync failed (expected when offline): $e');
    }
  }
  
  /// Force refresh - Clears cache and fetches fresh data
  /// Use for pull-to-refresh
  Future<List<FoodModel>> refreshFoods() async {
    try {
      AppLogger.info('🔄 Force refresh requested');
      await _cache.clearCache();
      return await getAllFoods();
    } catch (e, st) {
      AppLogger.error('refreshFoods failed: $e', e, st);
      return [];
    }
  }

  /// Lấy món ăn theo ID
  Future<FoodModel?> getFoodById(String foodId) async {
    try {
      // Try cache first
      final cached = await _cache.getFoodsFromCache();
      for (final item in cached) {
        if (item.id == foodId) return item;
      }

      // Fetch from Firestore
      final food = await _dataSource.fetchFoodById(foodId);
      return food;
    } catch (e) {
      AppLogger.error('Error getting food by ID: $e');
      return null;
    }
  }

  /// Lọc món ăn theo tiêu chí (client-side)
  Future<List<FoodModel>> getFoodsByFilters({
    int? budget,
    String? cuisineId,
    String? mealTypeId,
    String? keyword,
  }) async {
    final foods = await getAllFoods();
    return filterFoodsLocal(
      foods,
      budget: budget,
      cuisineId: cuisineId,
      mealTypeId: mealTypeId,
      keyword: keyword,
    );
  }

  /// Tìm kiếm món ăn theo keyword
  Future<List<FoodModel>> searchFoods(String query) async {
    return getFoodsByFilters(keyword: query);
  }

  /// Tăng view count
  Future<void> incrementViewCount(String foodId) async {
    await _dataSource.incrementViewCount(foodId);
  }

  /// Tăng pick count
  Future<void> incrementPickCount(String foodId) async {
    await _dataSource.incrementPickCount(foodId);
  }
}

