import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../models/food_model.dart';
import '../../../../core/constants/firebase_collections.dart';
import '../../../../core/utils/logger.dart';

class FoodFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Lấy tất cả món ăn từ Firestore
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

  /// Tăng view count của món ăn
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
}

