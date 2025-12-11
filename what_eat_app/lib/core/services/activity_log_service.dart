import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/firebase_collections.dart';
import '../utils/logger.dart';
import '../../features/recommendation/logic/scoring_engine.dart';
import '../../models/food_model.dart';

class ActivityLogService {
  ActivityLogService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final List<_PendingLog> _queue = [];
  bool _flushing = false;
  static const int _batchSize = 10;

  CollectionReference<Map<String, dynamic>> _logs(String userId) => _firestore
      .collection(FirebaseCollections.users)
      .doc(userId)
      .collection(FirebaseCollections.activityLogs);

  Future<void> logRecommendationRequest({
    required String userId,
    required RecommendationContext context,
  }) async {
    _enqueue(
      userId: userId,
      type: 'recommendation_requested',
      data: {
        'budget': context.budget,
        'companion': context.companion,
        'mood': context.mood,
        'favorite_cuisines': context.favoriteCuisines,
      },
    );
    await _flushIfNeeded();
  }

  Future<void> logFoodSelection({
    required String userId,
    required FoodModel food,
  }) async {
    _enqueue(
      userId: userId,
      type: 'food_selected',
      data: {
        'food_id': food.id,
        'cuisine_id': food.cuisineId,
        'price_segment': food.priceSegment,
      },
    );
    await _flushIfNeeded();
  }

  Future<void> logMapClick({
    required String userId,
    required FoodModel food,
  }) async {
    _enqueue(
      userId: userId,
      type: 'map_opened',
      data: {
        'food_id': food.id,
        'map_query': food.mapQuery,
      },
    );
    await _flushIfNeeded();
  }

  void _enqueue({
    required String userId,
    required String type,
    required Map<String, dynamic> data,
  }) {
    _queue.add(_PendingLog(userId: userId, type: type, data: data));
  }

  Future<void> _flushIfNeeded({bool force = false}) async {
    if (_queue.isEmpty) return;
    if (!force && _queue.length < _batchSize) return;
    await _flushBatch();
  }

  Future<void> flush() async {
    await _flushIfNeeded(force: true);
  }

  Future<void> _flushBatch() async {
    if (_flushing || _queue.isEmpty) return;
    _flushing = true;

    final toWrite = List<_PendingLog>.from(_queue);
    _queue.clear();

    try {
      final batch = _firestore.batch();
      for (final log in toWrite) {
        final docRef = _logs(log.userId).doc();
        batch.set(docRef, {
          'type': log.type,
          'data': log.data,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (e, st) {
      AppLogger.warning('Activity log batch failed: $e');
      AppLogger.debug('Stack: $st');
      // Fallback: try writing individually (best-effort)
      for (final log in toWrite) {
        try {
          await _logs(log.userId).add({
            'type': log.type,
            'data': log.data,
            'timestamp': FieldValue.serverTimestamp(),
          });
        } catch (err, errSt) {
          AppLogger.warning('Activity log fallback failed (${log.type}): $err');
          AppLogger.debug('Stack: $errSt');
        }
      }
    } finally {
      _flushing = false;
    }
  }
}

class _PendingLog {
  final String userId;
  final String type;
  final Map<String, dynamic> data;

  _PendingLog({
    required this.userId,
    required this.type,
    required this.data,
  });
}

final activityLogServiceProvider = Provider<ActivityLogService>((ref) {
  return ActivityLogService();
});

