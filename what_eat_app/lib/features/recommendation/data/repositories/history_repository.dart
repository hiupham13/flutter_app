import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/logger.dart';
import '../../../../models/food_model.dart';
import '../../logic/scoring_engine.dart';
import '../../interfaces/repository_interfaces.dart';

/// History repository implementing IHistoryRepository interface (DIP)
class HistoryRepository implements IHistoryRepository {
  final FirebaseFirestore _firestore;

  HistoryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
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

  @override
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

  /// Fetch full history with documents for deletion
  Future<List<HistoryItem>> fetchFullHistory({
    required String userId,
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('recommendation_history')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return HistoryItem(
          id: doc.id,
          foodId: data['food_id'] as String? ?? '',
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      AppLogger.error('Failed to fetch full history: $e');
      return [];
    }
  }

  /// Delete a single history item
  Future<void> deleteHistoryItem({
    required String userId,
    required String historyId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('recommendation_history')
          .doc(historyId)
          .delete();
      
      AppLogger.info('History item deleted: $historyId');
    } catch (e) {
      AppLogger.error('Failed to delete history item: $e');
      rethrow;
    }
  }

  /// Clear all history for a user
  Future<void> clearAllHistory({required String userId}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('recommendation_history')
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      AppLogger.info('All history cleared for user: $userId');
    } catch (e) {
      AppLogger.error('Failed to clear history: $e');
      rethrow;
    }
  }
  
  /// Add user action for feedback learning
  @override
  Future<void> addUserAction({
    required String userId,
    required String foodId,
    required String action, // 'pick', 'skip', 'favorite', 'reject'
    RecommendationContext? context,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('user_actions')
          .add({
        'food_id': foodId,
        'action': action,
        'timestamp': FieldValue.serverTimestamp(),
        'context': context != null ? {
          'budget': context.budget,
          'companion': context.companion,
          'mood': context.mood,
        } : null,
      });
    } catch (e) {
      AppLogger.error('Failed to add user action: $e');
    }
  }
  
  /// Fetch history food IDs with days filter (overloaded method)
  @override
  Future<List<String>> fetchHistoryFoodIdsWithDays({
    required String userId,
    int days = 7,
  }) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('recommendation_history')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(cutoffDate))
          .orderBy('timestamp', descending: true)
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

/// History item model với document ID for deletion
class HistoryItem {
  final String id;
  final String foodId;
  final DateTime timestamp;

  HistoryItem({
    required this.id,
    required this.foodId,
    required this.timestamp,
  });
}

