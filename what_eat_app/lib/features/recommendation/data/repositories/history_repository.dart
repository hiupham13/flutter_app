import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/logger.dart';
import '../../../../models/food_model.dart';
import '../../logic/scoring_engine.dart';

class HistoryRepository {
  final FirebaseFirestore _firestore;

  HistoryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> addHistory({
    required String userId,
    required FoodModel food,
    required RecommendationContext context,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('recommendation_history')
          .add({
        'food_id': food.id,
        'timestamp': FieldValue.serverTimestamp(),
        'context': {
          'budget': context.budget,
          'companion': context.companion,
          'mood': context.mood,
          'favorite_cuisines': context.favoriteCuisines,
          'recently_eaten': context.recentlyEaten,
          'blacklisted_foods': context.blacklistedFoods,
          'is_vegetarian': context.isVegetarian,
          'spice_tolerance': context.spiceTolerance,
          'excluded_allergens': context.excludedAllergens,
          'excluded_foods': context.excludedFoods,
          'weather': context.weather != null
              ? {
                  'temperature': context.weather!.temperature,
                  'condition': context.weather!.condition,
                  'description': context.weather!.description,
                  'code': context.weather!.weatherCode,
                }
              : null,
        },
      });
    } catch (e) {
      AppLogger.error('Failed to add history: $e');
    }
  }

  Future<List<String>> fetchHistoryFoodIds({
    required String userId,
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('recommendation_history')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => doc.data()['food_id'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
    } catch (e) {
      AppLogger.error('Failed to fetch history: $e');
      return [];
    }
  }
}

