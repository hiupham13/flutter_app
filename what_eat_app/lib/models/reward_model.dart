import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Enum for mystery box rarity tiers
enum BoxRarity {
  bronze, // Common - 70%
  silver, // Rare - 20%
  gold, // Epic - 8%
  diamond, // Legendary - 2%
}

/// Extension for BoxRarity
extension BoxRarityExtension on BoxRarity {
  String get displayName {
    switch (this) {
      case BoxRarity.bronze:
        return 'Đồng';
      case BoxRarity.silver:
        return 'Bạc';
      case BoxRarity.gold:
        return 'Vàng';
      case BoxRarity.diamond:
        return 'Kim Cương';
    }
  }

  String get emoji {
    switch (this) {
      case BoxRarity.bronze:
        return '📦';
      case BoxRarity.silver:
        return '🎁';
      case BoxRarity.gold:
        return '💎';
      case BoxRarity.diamond:
        return '✨';
    }
  }

  /// Get color for this rarity
  Color get color {
    switch (this) {
      case BoxRarity.bronze:
        return const Color(0xFFCD7F32);
      case BoxRarity.silver:
        return const Color(0xFFC0C0C0);
      case BoxRarity.gold:
        return const Color(0xFFFFD700);
      case BoxRarity.diamond:
        return const Color(0xFFB9F2FF);
    }
  }

  /// Get coin range for this rarity
  (int min, int max) get coinRange {
    switch (this) {
      case BoxRarity.bronze:
        return (10, 100);
      case BoxRarity.silver:
        return (100, 500);
      case BoxRarity.gold:
        return (500, 1000);
      case BoxRarity.diamond:
        return (1000, 5000);
    }
  }

  /// Get drop probability (0.0 to 1.0)
  double get dropProbability {
    switch (this) {
      case BoxRarity.bronze:
        return 0.70; // 70%
      case BoxRarity.silver:
        return 0.20; // 20%
      case BoxRarity.gold:
        return 0.08; // 8%
      case BoxRarity.diamond:
        return 0.02; // 2%
    }
  }
}

/// Mystery Box model
class RewardBox {
  final String id;
  final BoxRarity rarity;
  final int coinsAwarded;
  final DateTime earnedAt;
  final bool isOpened;
  final DateTime? openedAt;
  final String? sourceRecommendationId; // Which recommendation earned this box

  const RewardBox({
    required this.id,
    required this.rarity,
    required this.coinsAwarded,
    required this.earnedAt,
    this.isOpened = false,
    this.openedAt,
    this.sourceRecommendationId,
  });

  /// Create from Firestore document
  factory RewardBox.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RewardBox(
      id: doc.id,
      rarity: BoxRarity.values.firstWhere(
        (e) => e.name == data['rarity'],
        orElse: () => BoxRarity.bronze,
      ),
      coinsAwarded: data['coins_awarded'] as int? ?? 0,
      earnedAt: (data['earned_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isOpened: data['is_opened'] as bool? ?? false,
      openedAt: (data['opened_at'] as Timestamp?)?.toDate(),
      sourceRecommendationId: data['source_recommendation_id'] as String?,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'rarity': rarity.name,
      'coins_awarded': coinsAwarded,
      'earned_at': Timestamp.fromDate(earnedAt),
      'is_opened': isOpened,
      'opened_at': openedAt != null ? Timestamp.fromDate(openedAt!) : null,
      'source_recommendation_id': sourceRecommendationId,
    };
  }

  /// Copy with method
  RewardBox copyWith({
    String? id,
    BoxRarity? rarity,
    int? coinsAwarded,
    DateTime? earnedAt,
    bool? isOpened,
    DateTime? openedAt,
    String? sourceRecommendationId,
  }) {
    return RewardBox(
      id: id ?? this.id,
      rarity: rarity ?? this.rarity,
      coinsAwarded: coinsAwarded ?? this.coinsAwarded,
      earnedAt: earnedAt ?? this.earnedAt,
      isOpened: isOpened ?? this.isOpened,
      openedAt: openedAt ?? this.openedAt,
      sourceRecommendationId:
          sourceRecommendationId ?? this.sourceRecommendationId,
    );
  }
}

/// Transaction type enum
enum TransactionType {
  earned, // Earned from opening box
  spent, // Spent on redemption
  bonus, // Daily bonus, streak bonus, etc.
  refund, // Refund from cancelled redemption
}

/// Coin transaction model
class CoinTransaction {
  final String id;
  final TransactionType type;
  final int amount;
  final DateTime timestamp;
  final String? description;
  final String? relatedBoxId; // If earned from box
  final String? relatedRedemptionId; // If spent on redemption

  const CoinTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.timestamp,
    this.description,
    this.relatedBoxId,
    this.relatedRedemptionId,
  });

  /// Create from Firestore document
  factory CoinTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CoinTransaction(
      id: doc.id,
      type: TransactionType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => TransactionType.earned,
      ),
      amount: data['amount'] as int? ?? 0,
      timestamp:
          (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      description: data['description'] as String?,
      relatedBoxId: data['related_box_id'] as String?,
      relatedRedemptionId: data['related_redemption_id'] as String?,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'type': type.name,
      'amount': amount,
      'timestamp': Timestamp.fromDate(timestamp),
      'description': description,
      'related_box_id': relatedBoxId,
      'related_redemption_id': relatedRedemptionId,
    };
  }

  /// Get display text for transaction
  String get displayText {
    switch (type) {
      case TransactionType.earned:
        return 'Earned from ${relatedBoxId != null ? 'mystery box' : 'reward'}';
      case TransactionType.spent:
        return description ?? 'Spent on redemption';
      case TransactionType.bonus:
        return description ?? 'Bonus reward';
      case TransactionType.refund:
        return description ?? 'Refund';
    }
  }

  /// Is credit transaction (adds coins)
  bool get isCredit =>
      type == TransactionType.earned ||
      type == TransactionType.bonus ||
      type == TransactionType.refund;
}

/// User rewards stats model
class UserRewardsStats {
  final int totalCoins; // Current balance
  final int totalBoxesOpened;
  final int totalCoinsEarned; // Lifetime
  final int totalCoinsSpent; // Lifetime
  final DateTime? lastBoxOpenedAt;
  final int currentStreak; // Days with activity
  final int longestStreak;
  final DateTime? lastActivityDate;

  // Box stats by rarity
  final int bronzeBoxesOpened;
  final int silverBoxesOpened;
  final int goldBoxesOpened;
  final int diamondBoxesOpened;

  const UserRewardsStats({
    this.totalCoins = 0,
    this.totalBoxesOpened = 0,
    this.totalCoinsEarned = 0,
    this.totalCoinsSpent = 0,
    this.lastBoxOpenedAt,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActivityDate,
    this.bronzeBoxesOpened = 0,
    this.silverBoxesOpened = 0,
    this.goldBoxesOpened = 0,
    this.diamondBoxesOpened = 0,
  });

  /// Create from Firestore data
  factory UserRewardsStats.fromMap(Map<String, dynamic> data) {
    return UserRewardsStats(
      totalCoins: data['total_coins'] as int? ?? 0,
      totalBoxesOpened: data['total_boxes_opened'] as int? ?? 0,
      totalCoinsEarned: data['total_coins_earned'] as int? ?? 0,
      totalCoinsSpent: data['total_coins_spent'] as int? ?? 0,
      lastBoxOpenedAt:
          (data['last_box_opened_at'] as Timestamp?)?.toDate(),
      currentStreak: data['current_streak'] as int? ?? 0,
      longestStreak: data['longest_streak'] as int? ?? 0,
      lastActivityDate:
          (data['last_activity_date'] as Timestamp?)?.toDate(),
      bronzeBoxesOpened: data['bronze_boxes_opened'] as int? ?? 0,
      silverBoxesOpened: data['silver_boxes_opened'] as int? ?? 0,
      goldBoxesOpened: data['gold_boxes_opened'] as int? ?? 0,
      diamondBoxesOpened: data['diamond_boxes_opened'] as int? ?? 0,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'total_coins': totalCoins,
      'total_boxes_opened': totalBoxesOpened,
      'total_coins_earned': totalCoinsEarned,
      'total_coins_spent': totalCoinsSpent,
      'last_box_opened_at': lastBoxOpenedAt != null
          ? Timestamp.fromDate(lastBoxOpenedAt!)
          : null,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'last_activity_date': lastActivityDate != null
          ? Timestamp.fromDate(lastActivityDate!)
          : null,
      'bronze_boxes_opened': bronzeBoxesOpened,
      'silver_boxes_opened': silverBoxesOpened,
      'gold_boxes_opened': goldBoxesOpened,
      'diamond_boxes_opened': diamondBoxesOpened,
    };
  }

  /// Copy with method
  UserRewardsStats copyWith({
    int? totalCoins,
    int? totalBoxesOpened,
    int? totalCoinsEarned,
    int? totalCoinsSpent,
    DateTime? lastBoxOpenedAt,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActivityDate,
    int? bronzeBoxesOpened,
    int? silverBoxesOpened,
    int? goldBoxesOpened,
    int? diamondBoxesOpened,
  }) {
    return UserRewardsStats(
      totalCoins: totalCoins ?? this.totalCoins,
      totalBoxesOpened: totalBoxesOpened ?? this.totalBoxesOpened,
      totalCoinsEarned: totalCoinsEarned ?? this.totalCoinsEarned,
      totalCoinsSpent: totalCoinsSpent ?? this.totalCoinsSpent,
      lastBoxOpenedAt: lastBoxOpenedAt ?? this.lastBoxOpenedAt,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      bronzeBoxesOpened: bronzeBoxesOpened ?? this.bronzeBoxesOpened,
      silverBoxesOpened: silverBoxesOpened ?? this.silverBoxesOpened,
      goldBoxesOpened: goldBoxesOpened ?? this.goldBoxesOpened,
      diamondBoxesOpened: diamondBoxesOpened ?? this.diamondBoxesOpened,
    );
  }
}
