import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 1)
class UserModel extends HiveObject {
  @HiveField(0)
  final String uid;
  
  @HiveField(1)
  final UserInfo info;
  
  @HiveField(2)
  final UserSettings settings;
  
  @HiveField(3)
  final UserStats stats;
  
  @HiveField(4)
  final String? fcmToken;
  
  @HiveField(5)
  final int createdAtMillis;
  
  @HiveField(6)
  final int? lastLoginMillis;
  
  // Computed properties
  DateTime get createdAt => DateTime.fromMillisecondsSinceEpoch(createdAtMillis);
  DateTime? get lastLogin => lastLoginMillis != null
      ? DateTime.fromMillisecondsSinceEpoch(lastLoginMillis!)
      : null;

  UserModel({
    required this.uid,
    required this.info,
    required this.settings,
    required this.stats,
    this.fcmToken,
    required this.createdAtMillis,
    this.lastLoginMillis,
  });
  
  // Factory constructor for easy creation
  factory UserModel.create({
    required String uid,
    required UserInfo info,
    required UserSettings settings,
    required UserStats stats,
    String? fcmToken,
    required DateTime createdAt,
    DateTime? lastLogin,
  }) {
    return UserModel(
      uid: uid,
      info: info,
      settings: settings,
      stats: stats,
      fcmToken: fcmToken,
      createdAtMillis: createdAt.millisecondsSinceEpoch,
      lastLoginMillis: lastLogin?.millisecondsSinceEpoch,
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    
    if (data == null) {
      throw Exception('User document data is null');
    }
    
    // Handle created_at with fallback to now
    final createdAt = data['created_at'] != null
        ? (data['created_at'] as Timestamp).toDate()
        : DateTime.now();
    
    // Handle last_login - can be null
    final lastLogin = data['last_login'] != null
        ? (data['last_login'] as Timestamp).toDate()
        : null;
    
    // Safe cast for nested maps with fallbacks
    final infoData = data['info'] is Map<String, dynamic>
        ? data['info'] as Map<String, dynamic>
        : <String, dynamic>{};
    
    final settingsData = data['settings'] is Map<String, dynamic>
        ? data['settings'] as Map<String, dynamic>
        : <String, dynamic>{};
    
    final statsData = data['stats'] is Map<String, dynamic>
        ? data['stats'] as Map<String, dynamic>
        : <String, dynamic>{};
    
    return UserModel(
      uid: doc.id,
      info: UserInfo.fromMap(infoData),
      settings: UserSettings.fromMap(settingsData),
      stats: UserStats.fromMap(statsData),
      fcmToken: data['fcm_token'] as String?,
      createdAtMillis: createdAt.millisecondsSinceEpoch,
      lastLoginMillis: lastLogin?.millisecondsSinceEpoch,
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

@HiveType(typeId: 2)
class UserInfo {
  @HiveField(0)
  final String displayName;
  
  @HiveField(1)
  final String email;
  
  @HiveField(2)
  final String? avatarUrl;

  UserInfo({
    required this.displayName,
    required this.email,
    this.avatarUrl,
  });

  factory UserInfo.fromMap(Map<String, dynamic> map) {
    return UserInfo(
      displayName: map['display_name'] as String? ?? 'User',
      email: map['email'] as String? ?? 'no-email@example.com',
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

@HiveType(typeId: 3)
class UserSettings {
  @HiveField(0)
  final int defaultBudget; // 1: Cheap, 2: Mid, 3: High
  
  @HiveField(1)
  final int spiceTolerance; // 0-5
  
  @HiveField(2)
  final bool isVegetarian;
  
  @HiveField(3)
  final List<String> blacklistedFoods;
  
  @HiveField(4)
  final List<String> excludedAllergens;
  
  @HiveField(5)
  final List<String> favoriteCuisines;
  
  @HiveField(6)
  final bool onboardingCompleted;

  UserSettings({
    required this.defaultBudget,
    required this.spiceTolerance,
    required this.isVegetarian,
    required this.blacklistedFoods,
    required this.excludedAllergens,
    required this.favoriteCuisines,
    required this.onboardingCompleted,
  });

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      defaultBudget: map['default_budget'] as int? ?? 2,
      spiceTolerance: map['spice_tolerance'] as int? ?? 2,
      isVegetarian: map['is_vegetarian'] as bool? ?? false,
      blacklistedFoods: List<String>.from(map['blacklisted_foods'] as List? ?? []),
      excludedAllergens: List<String>.from(map['excluded_allergens'] as List? ?? []),
      favoriteCuisines: List<String>.from(map['favorite_cuisines'] as List? ?? []),
      onboardingCompleted: map['onboarding_completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'default_budget': defaultBudget,
      'spice_tolerance': spiceTolerance,
      'is_vegetarian': isVegetarian,
      'blacklisted_foods': blacklistedFoods,
      'excluded_allergens': excludedAllergens,
      'favorite_cuisines': favoriteCuisines,
      'onboarding_completed': onboardingCompleted,
    };
  }
}

@HiveType(typeId: 4)
class UserStats {
  @HiveField(0)
  final int streakDays;
  
  @HiveField(1)
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

