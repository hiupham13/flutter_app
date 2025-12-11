import 'package:what_eat_app/models/food_model.dart';

/// Lightweight in-memory cache with expiry.
/// Designed to be replaced by Hive adapters later without changing the API.
class CacheService {
  static const Duration _defaultTtl = Duration(minutes: 10);

  List<FoodModel> _foods = const [];
  DateTime? _lastUpdated;
  Duration ttl;

  CacheService({Duration? ttlOverride}) : ttl = ttlOverride ?? _defaultTtl;

  Future<void> saveFoodsToCache(List<FoodModel> foods) async {
    _foods = List<FoodModel>.from(foods);
    _lastUpdated = DateTime.now();
  }

  Future<List<FoodModel>> getFoodsFromCache() async {
    if (!isCacheValid()) return [];
    return List<FoodModel>.from(_foods);
  }

  Future<void> clearCache() async {
    _foods = const [];
    _lastUpdated = null;
  }

  bool isCacheValid() {
    if (_lastUpdated == null) return false;
    final diff = DateTime.now().difference(_lastUpdated!);
    return diff <= ttl && _foods.isNotEmpty;
  }
}

