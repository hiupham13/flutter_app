import '../../../../models/food_model.dart';
import '../sources/food_firestore_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/services/cache_service.dart';

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

  /// Lấy tất cả món ăn (ưu tiên cache, fallback Firestore)
  Future<List<FoodModel>> getAllFoods() async {
    List<FoodModel> cachedFoods = const [];
    try {
      cachedFoods = await _cache.getFoodsFromCache();
      if (cachedFoods.isNotEmpty && _cache.isCacheValid()) {
        return cachedFoods;
      }

      // Fetch from Firestore
      final foods = await _dataSource.fetchAllFoods();

      // Save to cache (best-effort)
      await _cache.saveFoodsToCache(foods);

      return foods;
    } catch (e) {
      AppLogger.error('Error getting all foods: $e');
      // Fallback to stale cache if available
      if (cachedFoods.isNotEmpty) return cachedFoods;
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

