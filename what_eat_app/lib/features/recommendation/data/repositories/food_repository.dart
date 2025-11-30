import '../../../../models/food_model.dart';
import '../sources/food_firestore_service.dart';
import '../../../../core/utils/logger.dart';

// TODO: Implement Hive cache when ready
// import 'package:hive/hive.dart';

class FoodRepository {
  final FoodFirestoreService _firestoreService = FoodFirestoreService();

  /// Lấy tất cả món ăn (ưu tiên cache, fallback Firestore)
  Future<List<FoodModel>> getAllFoods() async {
    try {
      // TODO: Check cache first
      // final cachedFoods = await _getCachedFoods();
      // if (cachedFoods.isNotEmpty) {
      //   return cachedFoods;
      // }

      // Fetch from Firestore
      final foods = await _firestoreService.fetchAllFoods();

      // TODO: Save to cache
      // await _saveFoodsToCache(foods);

      return foods;
    } catch (e) {
      AppLogger.error('Error getting all foods: $e');
      return [];
    }
  }

  /// Lấy món ăn theo ID
  Future<FoodModel?> getFoodById(String foodId) async {
    try {
      return await _firestoreService.fetchFoodById(foodId);
    } catch (e) {
      AppLogger.error('Error getting food by ID: $e');
      return null;
    }
  }

  /// Tăng view count
  Future<void> incrementViewCount(String foodId) async {
    await _firestoreService.incrementViewCount(foodId);
  }

  /// Tăng pick count
  Future<void> incrementPickCount(String foodId) async {
    await _firestoreService.incrementPickCount(foodId);
  }
}

