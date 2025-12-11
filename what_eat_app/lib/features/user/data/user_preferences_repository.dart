import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/user_model.dart';
import '../../../core/utils/logger.dart';

class UserPreferencesRepository {
  final FirebaseFirestore _firestore;

  UserPreferencesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<UserSettings?> fetchUserSettings(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null || data['settings'] == null) return null;

      return UserSettings.fromMap(
        Map<String, dynamic>.from(data['settings'] as Map),
      );
    } catch (e) {
      AppLogger.error('Failed to fetch user settings: $e');
      return null;
    }
  }

  Future<void> upsertUserSettings(String userId, UserSettings settings) async {
    try {
      await _firestore.collection('users').doc(userId).set(
        {
          'settings': settings.toMap(),
          'updated_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      AppLogger.error('Failed to upsert user settings: $e');
      rethrow;
    }
  }

  Future<void> updateOnboardingCompletion(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).set(
        {
          'settings': {
            'onboarding_completed': true,
          },
          'updated_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      AppLogger.error('Failed to update onboarding completion: $e');
      rethrow;
    }
  }
}

