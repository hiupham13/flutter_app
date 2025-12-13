import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/food_model.dart';
import '../../../core/utils/logger.dart';

class FavoritesRepository {
  final FirebaseFirestore _firestore;
  final String userId;

  FavoritesRepository({
    required this.userId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get user's favorite food IDs
  Stream<List<String>> watchFavorites() {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return <String>[];
          final data = doc.data();
          if (data == null) return <String>[];
          
          final favorites = data['favorites'] as List?;
          return favorites?.cast<String>() ?? <String>[];
        })
        .handleError((error, stackTrace) {
          AppLogger.error('Watch favorites failed: $error', error, stackTrace);
          return <String>[];
        });
  }

  /// Get favorite food IDs (one-time)
  Future<List<String>> getFavorites() async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (!doc.exists) return [];
      final data = doc.data();
      if (data == null) return [];
      
      final favorites = data['favorites'] as List?;
      return favorites?.cast<String>() ?? [];
    } catch (e, st) {
      AppLogger.error('Get favorites failed: $e', e, st);
      return [];
    }
  }

  /// Add food to favorites
  Future<void> addFavorite(String foodId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'favorites': FieldValue.arrayUnion([foodId]),
      });
      AppLogger.info('Added favorite: $foodId');
    } catch (e, st) {
      AppLogger.error('Add favorite failed: $e', e, st);
      rethrow;
    }
  }

  /// Remove food from favorites
  Future<void> removeFavorite(String foodId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'favorites': FieldValue.arrayRemove([foodId]),
      });
      AppLogger.info('Removed favorite: $foodId');
    } catch (e, st) {
      AppLogger.error('Remove favorite failed: $e', e, st);
      rethrow;
    }
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(String foodId) async {
    final favorites = await getFavorites();
    
    if (favorites.contains(foodId)) {
      await removeFavorite(foodId);
    } else {
      await addFavorite(foodId);
    }
  }

  /// Check if food is favorited
  Future<bool> isFavorite(String foodId) async {
    final favorites = await getFavorites();
    return favorites.contains(foodId);
  }

  /// Clear all favorites
  Future<void> clearAllFavorites() async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'favorites': [],
      });
      AppLogger.info('Cleared all favorites');
    } catch (e, st) {
      AppLogger.error('Clear favorites failed: $e', e, st);
      rethrow;
    }
  }
}