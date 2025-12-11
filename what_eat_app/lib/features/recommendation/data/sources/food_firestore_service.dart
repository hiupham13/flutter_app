import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../models/food_model.dart';
import '../../../../core/constants/firebase_collections.dart';
import '../../../../core/utils/logger.dart';

abstract class FoodDataSource {
  Future<List<FoodModel>> fetchAllFoods();
  Future<FoodModel?> fetchFoodById(String foodId);
  Future<void> incrementViewCount(String foodId);
  Future<void> incrementPickCount(String foodId);
  Future<List<FoodModel>> fetchFoodsByFilters({
    int? budget,
    String? cuisineId,
    String? mealTypeId,
    String? keyword,
  });
  Future<List<FoodModel>> searchFoods(String query);
}

class FoodFirestoreService implements FoodDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Lấy tất cả món ăn từ Firestore
  @override
  Future<List<FoodModel>> fetchAllFoods() async {
    try {
      final querySnapshot = await _firestore
          .collection(FirebaseCollections.foods)
          .where('is_active', isEqualTo: true)
          .get();

      final foods = <FoodModel>[];
      for (final doc in querySnapshot.docs) {
        try {
          final food = FoodModel.fromFirestore(doc);
          foods.add(food);
        } catch (e) {
          AppLogger.error('Error parsing food document ${doc.id}: $e');
          // Skip invalid documents, continue with others
        }
      }
      return foods;
    } catch (e) {
      AppLogger.error('Error fetching foods from Firestore: $e');
      return [];
    }
  }

  /// Lấy món ăn theo ID
  @override
  Future<FoodModel?> fetchFoodById(String foodId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseCollections.foods)
          .doc(foodId)
          .get();

      if (doc.exists) {
        return FoodModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      AppLogger.error('Error fetching food by ID: $e');
      return null;
    }
  }

  /// Lọc món ăn theo tiêu chí (simple client-side after fetch)
  @override
  Future<List<FoodModel>> fetchFoodsByFilters({
    int? budget,
    String? cuisineId,
    String? mealTypeId,
    String? keyword,
  }) async {
    final all = await fetchAllFoods();
    return _filterFoodsLocal(
      all,
      budget: budget,
      cuisineId: cuisineId,
      mealTypeId: mealTypeId,
      keyword: keyword,
    );
  }

  /// Tìm kiếm món ăn theo keyword (client-side for now)
  @override
  Future<List<FoodModel>> searchFoods(String query) async {
    return fetchFoodsByFilters(keyword: query);
  }

  /// Tăng view count của món ăn
  @override
  Future<void> incrementViewCount(String foodId) async {
    try {
      await _firestore
          .collection(FirebaseCollections.foods)
          .doc(foodId)
          .update({
        'view_count': FieldValue.increment(1),
      });
    } catch (e) {
      AppLogger.error('Error incrementing view count: $e');
    }
  }

  /// Tăng pick count của món ăn
  @override
  Future<void> incrementPickCount(String foodId) async {
    try {
      await _firestore
          .collection(FirebaseCollections.foods)
          .doc(foodId)
          .update({
        'pick_count': FieldValue.increment(1),
      });
    } catch (e) {
      AppLogger.error('Error incrementing pick count: $e');
    }
  }

  List<FoodModel> _filterFoodsLocal(
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
}

