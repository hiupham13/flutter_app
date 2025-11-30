import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final UserInfo info;
  final UserSettings settings;
  final UserStats stats;
  final String? fcmToken;
  final DateTime createdAt;
  final DateTime? lastLogin;

  UserModel({
    required this.uid,
    required this.info,
    required this.settings,
    required this.stats,
    this.fcmToken,
    required this.createdAt,
    this.lastLogin,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      info: UserInfo.fromMap(data['info'] as Map<String, dynamic>),
      settings: UserSettings.fromMap(data['settings'] as Map<String, dynamic>),
      stats: UserStats.fromMap(data['stats'] as Map<String, dynamic>),
      fcmToken: data['fcm_token'] as String?,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      lastLogin: data['last_login'] != null
          ? (data['last_login'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'info': info.toMap(),
      'settings': settings.toMap(),
      'stats': stats.toMap(),
      'fcm_token': fcmToken,
      'created_at': Timestamp.fromDate(createdAt),
      'last_login': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
    };
  }
}

class UserInfo {
  final String displayName;
  final String email;
  final String? avatarUrl;

  UserInfo({
    required this.displayName,
    required this.email,
    this.avatarUrl,
  });

  factory UserInfo.fromMap(Map<String, dynamic> map) {
    return UserInfo(
      displayName: map['display_name'] as String,
      email: map['email'] as String,
      avatarUrl: map['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'display_name': displayName,
      'email': email,
      'avatar_url': avatarUrl,
    };
  }
}

class UserSettings {
  final int defaultBudget; // 1: Cheap, 2: Mid, 3: High
  final int spiceTolerance; // 0-5
  final bool isVegetarian;
  final List<String> blacklistedFoods;
  final List<String> excludedAllergens;

  UserSettings({
    required this.defaultBudget,
    required this.spiceTolerance,
    required this.isVegetarian,
    required this.blacklistedFoods,
    required this.excludedAllergens,
  });

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      defaultBudget: map['default_budget'] as int? ?? 2,
      spiceTolerance: map['spice_tolerance'] as int? ?? 2,
      isVegetarian: map['is_vegetarian'] as bool? ?? false,
      blacklistedFoods: List<String>.from(map['blacklisted_foods'] as List? ?? []),
      excludedAllergens: List<String>.from(map['excluded_allergens'] as List? ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'default_budget': defaultBudget,
      'spice_tolerance': spiceTolerance,
      'is_vegetarian': isVegetarian,
      'blacklisted_foods': blacklistedFoods,
      'excluded_allergens': excludedAllergens,
    };
  }
}

class UserStats {
  final int streakDays;
  final int totalPicked;

  UserStats({
    required this.streakDays,
    required this.totalPicked,
  });

  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      streakDays: map['streak_days'] as int? ?? 0,
      totalPicked: map['total_picked'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'streak_days': streakDays,
      'total_picked': totalPicked,
    };
  }
}

