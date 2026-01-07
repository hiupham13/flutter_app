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
  spent, // Spent on redemption (legacy - use redemption instead)
  bonus, // Daily bonus, streak bonus, etc.
  refund, // Refund from cancelled redemption
  redemption, // Spent on coin redemption (voucher/cash/premium)
  redemptionRefund, // Refund from failed/cancelled redemption
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
      case TransactionType.redemption:
        return description ?? 'Redeemed reward';
      case TransactionType.redemptionRefund:
        return description ?? 'Redemption refund';
    }
  }

  /// Is credit transaction (adds coins)
  bool get isCredit =>
      type == TransactionType.earned ||
      type == TransactionType.bonus ||
      type == TransactionType.refund ||
      type == TransactionType.redemptionRefund;
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

// ============================================================================
// REDEMPTION MODELS
// ============================================================================

/// Redemption type enum
enum RedemptionType {
  voucher, // Voucher nhà hàng
  cash, // Rút tiền
  premium, // Premium rewards
  merchandise, // Quà tặng
}

/// Extension for RedemptionType
extension RedemptionTypeExtension on RedemptionType {
  String get displayName {
    switch (this) {
      case RedemptionType.voucher:
        return 'Voucher';
      case RedemptionType.cash:
        return 'Rút tiền';
      case RedemptionType.premium:
        return 'Premium';
      case RedemptionType.merchandise:
        return 'Quà tặng';
    }
  }

  String get emoji {
    switch (this) {
      case RedemptionType.voucher:
        return '🎟️';
      case RedemptionType.cash:
        return '💵';
      case RedemptionType.premium:
        return '👑';
      case RedemptionType.merchandise:
        return '🎁';
    }
  }

  Color get color {
    switch (this) {
      case RedemptionType.voucher:
        return const Color(0xFF4CAF50); // Green
      case RedemptionType.cash:
        return const Color(0xFF2196F3); // Blue
      case RedemptionType.premium:
        return const Color(0xFFFFD700); // Gold
      case RedemptionType.merchandise:
        return const Color(0xFFFF9800); // Orange
    }
  }
}

/// Redemption status enum
enum RedemptionStatus {
  pending, // Chờ xử lý
  processing, // Đang xử lý
  completed, // Hoàn thành
  failed, // Thất bại
  cancelled, // Đã hủy
  used, // Đã sử dụng (for vouchers)
}

/// Extension for RedemptionStatus
extension RedemptionStatusExtension on RedemptionStatus {
  String get displayName {
    switch (this) {
      case RedemptionStatus.pending:
        return 'Chờ xử lý';
      case RedemptionStatus.processing:
        return 'Đang xử lý';
      case RedemptionStatus.completed:
        return 'Hoàn thành';
      case RedemptionStatus.failed:
        return 'Thất bại';
      case RedemptionStatus.cancelled:
        return 'Đã hủy';
      case RedemptionStatus.used:
        return 'Đã sử dụng';
    }
  }

  Color get color {
    switch (this) {
      case RedemptionStatus.pending:
        return const Color(0xFFFFA726); // Orange
      case RedemptionStatus.processing:
        return const Color(0xFF42A5F5); // Blue
      case RedemptionStatus.completed:
        return const Color(0xFF66BB6A); // Green
      case RedemptionStatus.failed:
        return const Color(0xFFEF5350); // Red
      case RedemptionStatus.cancelled:
        return const Color(0xFF9E9E9E); // Gray
      case RedemptionStatus.used:
        return const Color(0xFF78909C); // Blue Gray
    }
  }

  /// Check if status is final (cannot be changed)
  bool get isFinal =>
      this == RedemptionStatus.completed ||
      this == RedemptionStatus.failed ||
      this == RedemptionStatus.cancelled ||
      this == RedemptionStatus.used;
}

/// Redemption offer model (global offers available to all users)
class RedemptionOffer {
  final String id;
  final String title;
  final String description;
  final RedemptionType type;
  final int coinsRequired;
  final int cashValue; // VND value
  final String? imageUrl;
  final bool isActive;
  final DateTime? expiryDate;
  final int? stockRemaining; // Null = unlimited
  final List<String> terms; // Điều kiện sử dụng
  final Map<String, dynamic>? metadata; // Partner info, etc.
  final DateTime createdAt;
  final DateTime updatedAt;

  const RedemptionOffer({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.coinsRequired,
    required this.cashValue,
    this.imageUrl,
    this.isActive = true,
    this.expiryDate,
    this.stockRemaining,
    this.terms = const [],
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Firestore document
  factory RedemptionOffer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RedemptionOffer(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      type: RedemptionType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => RedemptionType.voucher,
      ),
      coinsRequired: data['coins_required'] as int? ?? 0,
      cashValue: data['cash_value'] as int? ?? 0,
      imageUrl: data['image_url'] as String?,
      isActive: data['is_active'] as bool? ?? true,
      expiryDate: (data['expiry_date'] as Timestamp?)?.toDate(),
      stockRemaining: data['stock_remaining'] as int?,
      terms: (data['terms'] as List<dynamic>?)?.cast<String>() ?? [],
      metadata: data['metadata'] as Map<String, dynamic>?,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'type': type.name,
      'coins_required': coinsRequired,
      'cash_value': cashValue,
      'image_url': imageUrl,
      'is_active': isActive,
      'expiry_date': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'stock_remaining': stockRemaining,
      'terms': terms,
      'metadata': metadata,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  /// Check if offer is available
  bool get isAvailable {
    if (!isActive) return false;
    if (expiryDate != null && DateTime.now().isAfter(expiryDate!)) return false;
    if (stockRemaining != null && stockRemaining! <= 0) return false;
    return true;
  }

  /// Copy with method
  RedemptionOffer copyWith({
    String? id,
    String? title,
    String? description,
    RedemptionType? type,
    int? coinsRequired,
    int? cashValue,
    String? imageUrl,
    bool? isActive,
    DateTime? expiryDate,
    int? stockRemaining,
    List<String>? terms,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RedemptionOffer(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      coinsRequired: coinsRequired ?? this.coinsRequired,
      cashValue: cashValue ?? this.cashValue,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      expiryDate: expiryDate ?? this.expiryDate,
      stockRemaining: stockRemaining ?? this.stockRemaining,
      terms: terms ?? this.terms,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// User redemption model (user's redeemed rewards)
class UserRedemption {
  final String id;
  final String userId;
  final String offerId;
  final String offerTitle; // Cached from offer
  final RedemptionType type;
  final int coinsSpent;
  final int cashValue;
  final RedemptionStatus status;
  final DateTime redeemedAt;
  final DateTime? completedAt;
  final DateTime? expiryDate; // For vouchers
  final String? voucherCode; // For voucher type
  final String? qrCodeData; // QR code data for in-store use
  final String? bankInfo; // For cash type (encrypted in production)
  final String? failureReason;
  final Map<String, dynamic>? metadata;

  const UserRedemption({
    required this.id,
    required this.userId,
    required this.offerId,
    required this.offerTitle,
    required this.type,
    required this.coinsSpent,
    required this.cashValue,
    required this.status,
    required this.redeemedAt,
    this.completedAt,
    this.expiryDate,
    this.voucherCode,
    this.qrCodeData,
    this.bankInfo,
    this.failureReason,
    this.metadata,
  });

  /// Create from Firestore document
  factory UserRedemption.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserRedemption(
      id: doc.id,
      userId: data['user_id'] as String? ?? '',
      offerId: data['offer_id'] as String? ?? '',
      offerTitle: data['offer_title'] as String? ?? '',
      type: RedemptionType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => RedemptionType.voucher,
      ),
      coinsSpent: data['coins_spent'] as int? ?? 0,
      cashValue: data['cash_value'] as int? ?? 0,
      status: RedemptionStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => RedemptionStatus.pending,
      ),
      redeemedAt:
          (data['redeemed_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completed_at'] as Timestamp?)?.toDate(),
      expiryDate: (data['expiry_date'] as Timestamp?)?.toDate(),
      voucherCode: data['voucher_code'] as String?,
      qrCodeData: data['qr_code_data'] as String?,
      bankInfo: data['bank_info'] as String?,
      failureReason: data['failure_reason'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'offer_id': offerId,
      'offer_title': offerTitle,
      'type': type.name,
      'coins_spent': coinsSpent,
      'cash_value': cashValue,
      'status': status.name,
      'redeemed_at': Timestamp.fromDate(redeemedAt),
      'completed_at':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'expiry_date':
          expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'voucher_code': voucherCode,
      'qr_code_data': qrCodeData,
      'bank_info': bankInfo,
      'failure_reason': failureReason,
      'metadata': metadata,
    };
  }

  /// Check if voucher is expired
  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  /// Check if voucher is usable
  bool get isUsable {
    if (type != RedemptionType.voucher) return false;
    if (status != RedemptionStatus.completed) return false;
    if (isExpired) return false;
    return true;
  }

  /// Copy with method
  UserRedemption copyWith({
    String? id,
    String? userId,
    String? offerId,
    String? offerTitle,
    RedemptionType? type,
    int? coinsSpent,
    int? cashValue,
    RedemptionStatus? status,
    DateTime? redeemedAt,
    DateTime? completedAt,
    DateTime? expiryDate,
    String? voucherCode,
    String? qrCodeData,
    String? bankInfo,
    String? failureReason,
    Map<String, dynamic>? metadata,
  }) {
    return UserRedemption(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      offerId: offerId ?? this.offerId,
      offerTitle: offerTitle ?? this.offerTitle,
      type: type ?? this.type,
      coinsSpent: coinsSpent ?? this.coinsSpent,
      cashValue: cashValue ?? this.cashValue,
      status: status ?? this.status,
      redeemedAt: redeemedAt ?? this.redeemedAt,
      completedAt: completedAt ?? this.completedAt,
      expiryDate: expiryDate ?? this.expiryDate,
      voucherCode: voucherCode ?? this.voucherCode,
      qrCodeData: qrCodeData ?? this.qrCodeData,
      bankInfo: bankInfo ?? this.bankInfo,
      failureReason: failureReason ?? this.failureReason,
      metadata: metadata ?? this.metadata,
    );
  }
}
