import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../models/user_model.dart';
import '../../../../core/constants/firebase_collections.dart';
import '../../../../core/utils/logger.dart';

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirebaseCollections.users);

  Future<void> createUserProfile({
    required String uid,
    required UserInfo info,
    required UserSettings settings,
  }) async {
    final model = UserModel.create(
      uid: uid,
      info: info,
      settings: settings,
      stats: UserStats(streakDays: 0, totalPicked: 0),
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
    );
    await _col.doc(uid).set(model.toFirestore(), SetOptions(merge: true));
  }

  Future<void> updateUserProfile({
    required String uid,
    UserInfo? info,
    UserSettings? settings,
    UserStats? stats,
    String? fcmToken,
  }) async {
    final data = <String, dynamic>{};
    if (info != null) data['info'] = info.toMap();
    if (settings != null) data['settings'] = settings.toMap();
    if (stats != null) data['stats'] = stats.toMap();
    if (fcmToken != null) data['fcm_token'] = fcmToken;
    data['updated_at'] = FieldValue.serverTimestamp();

    await _col.doc(uid).set(data, SetOptions(merge: true));
  }

  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _col.doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (e, st) {
      AppLogger.error('getUserProfile failed: $e', e, st);
      return null;
    }
  }

  Future<void> updatePreferences(String uid, UserSettings settings) async {
    await updateUserProfile(uid: uid, settings: settings);
  }

  Stream<UserModel?> watchUserProfile(String uid) {
    return _col.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }
}

