import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/rewards_constants.dart';
import '../../../core/utils/logger.dart';
import '../../../models/reward_model.dart';

/// Repository for managing rewards, mystery boxes, and coins
class RewardsRepository {
  final FirebaseFirestore _firestore;
  final String userId;

  RewardsRepository({
    required this.userId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  // ============================================================================
  // USER STATS
  // ============================================================================

  /// Get user rewards stats
  Future<UserRewardsStats> getUserStats() async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection(RewardsConstants.rewardsStatsCollection)
          .doc('summary')
          .get();

      if (!doc.exists) {
        // Create initial stats
        final initialStats = const UserRewardsStats();
        await _updateUserStats(initialStats);
        return initialStats;
      }

      return UserRewardsStats.fromMap(doc.data()!);
    } catch (e, st) {
      AppLogger.error('Get user stats failed: $e', e, st);
      return const UserRewardsStats();
    }
  }

  /// Watch user stats (real-time)
  Stream<UserRewardsStats> watchUserStats() {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection(RewardsConstants.rewardsStatsCollection)
        .doc('summary')
        .snapshots()
        .map((doc) {
      if (!doc.exists) return const UserRewardsStats();
      return UserRewardsStats.fromMap(doc.data()!);
    }).handleError((error, stackTrace) {
      AppLogger.error('Watch user stats failed: $error', error, stackTrace);
      return const UserRewardsStats();
    });
  }

  /// Update user stats
  Future<void> _updateUserStats(UserRewardsStats stats) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection(RewardsConstants.rewardsStatsCollection)
          .doc('summary')
          .set(stats.toMap(), SetOptions(merge: true));
    } catch (e, st) {
      AppLogger.error('Update user stats failed: $e', e, st);
    }
  }

  // ============================================================================
  // MYSTERY BOXES
  // ============================================================================

  /// Generate a mystery box with random rarity
  Future<RewardBox> generateMysteryBox({
    String? sourceRecommendationId,
  }) async {
    try {
      // Determine rarity based on probability
      final rarity = _determineBoxRarity();

      // Generate random coin amount within range
      final (min, max) = rarity.coinRange;
      final coinsAwarded = _random.nextInt(max - min + 1) + min;

      // Create box document
      final boxRef = _firestore
          .collection('users')
          .doc(userId)
          .collection(RewardsConstants.mysteryBoxesCollection)
          .doc();

      final box = RewardBox(
        id: boxRef.id,
        rarity: rarity,
        coinsAwarded: coinsAwarded,
        earnedAt: DateTime.now(),
        sourceRecommendationId: sourceRecommendationId,
      );

      await boxRef.set(box.toFirestore());

      AppLogger.info('Mystery box generated: ${rarity.displayName}, $coinsAwarded coins');

      return box;
    } catch (e, st) {
      AppLogger.error('Generate mystery box failed: $e', e, st);
      rethrow;
    }
  }

  /// Random number generator
  static final _random = Random();

  /// Determine box rarity based on probability
  BoxRarity _determineBoxRarity() {
    final roll = _random.nextDouble();
    double cumulative = 0.0;

    // Check each rarity in order (bronze -> diamond)
    for (final rarity in BoxRarity.values) {
      cumulative += rarity.dropProbability;
      if (roll < cumulative) {
        return rarity;
      }
    }

    // Fallback (should never reach)
    return BoxRarity.bronze;
  }

  /// Open a mystery box
  Future<int> openMysteryBox(String boxId) async {
    try {
      final boxRef = _firestore
          .collection('users')
          .doc(userId)
          .collection(RewardsConstants.mysteryBoxesCollection)
          .doc(boxId);

      // Get box
      final boxDoc = await boxRef.get();
      if (!boxDoc.exists) {
        throw Exception('Box not found');
      }

      final box = RewardBox.fromFirestore(boxDoc);

      if (box.isOpened) {
        throw Exception('Box already opened');
      }

      // Mark as opened
      await boxRef.update({
        'is_opened': true,
        'opened_at': Timestamp.now(),
      });

      // Add coins to user balance
      await _addCoins(
        amount: box.coinsAwarded,
        type: TransactionType.earned,
        description: 'Opened ${box.rarity.displayName}',
        relatedBoxId: boxId,
      );

      // Update stats
      await _updateStatsAfterBoxOpened(box);

      AppLogger.info('Box opened: $boxId, ${box.coinsAwarded} coins earned');

      return box.coinsAwarded;
    } catch (e, st) {
      AppLogger.error('Open mystery box failed: $e', e, st);
      rethrow;
    }
  }

  /// Get pending (unopened) boxes
  Future<List<RewardBox>> getPendingBoxes() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection(RewardsConstants.mysteryBoxesCollection)
          .where('is_opened', isEqualTo: false)
          .orderBy('earned_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => RewardBox.fromFirestore(doc))
          .toList();
    } catch (e, st) {
      AppLogger.error('Get pending boxes failed: $e', e, st);
      return [];
    }
  }

  /// Get box history
  Future<List<RewardBox>> getBoxHistory({int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection(RewardsConstants.mysteryBoxesCollection)
          .orderBy('earned_at', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => RewardBox.fromFirestore(doc))
          .toList();
    } catch (e, st) {
      AppLogger.error('Get box history failed: $e', e, st);
      return [];
    }
  }

  // ============================================================================
  // COIN MANAGEMENT
  // ============================================================================

  /// Add coins (internal method)
  Future<void> _addCoins({
    required int amount,
    required TransactionType type,
    String? description,
    String? relatedBoxId,
    String? relatedRedemptionId,
  }) async {
    try {
      // Create transaction
      final txnRef = _firestore
          .collection('users')
          .doc(userId)
          .collection(RewardsConstants.coinTransactionsCollection)
          .doc();

      final transaction = CoinTransaction(
        id: txnRef.id,
        type: type,
        amount: amount,
        timestamp: DateTime.now(),
        description: description,
        relatedBoxId: relatedBoxId,
        relatedRedemptionId: relatedRedemptionId,
      );

      await txnRef.set(transaction.toFirestore());

      // Update user stats
      final stats = await getUserStats();
      final newStats = stats.copyWith(
        totalCoins: stats.totalCoins + amount,
        totalCoinsEarned: stats.totalCoinsEarned + amount,
      );
      await _updateUserStats(newStats);
    } catch (e, st) {
      AppLogger.error('Add coins failed: $e', e, st);
      rethrow;
    }
  }

  /// Spend coins (internal method)
  Future<void> _spendCoins({
    required int amount,
    String? description,
    String? relatedRedemptionId,
  }) async {
    try {
      // Check balance
      final stats = await getUserStats();
      if (stats.totalCoins < amount) {
        throw Exception('Insufficient coins');
      }

      // Create transaction
      final txnRef = _firestore
          .collection('users')
          .doc(userId)
          .collection(RewardsConstants.coinTransactionsCollection)
          .doc();

      final transaction = CoinTransaction(
        id: txnRef.id,
        type: TransactionType.spent,
        amount: -amount,
        timestamp: DateTime.now(),
        description: description,
        relatedRedemptionId: relatedRedemptionId,
      );

      await txnRef.set(transaction.toFirestore());

      // Update user stats
      final newStats = stats.copyWith(
        totalCoins: stats.totalCoins - amount,
        totalCoinsSpent: stats.totalCoinsSpent + amount,
      );
      await _updateUserStats(newStats);
    } catch (e, st) {
      AppLogger.error('Spend coins failed: $e', e, st);
      rethrow;
    }
  }

  /// Get transaction history
  Future<List<CoinTransaction>> getTransactionHistory({
    int limit = 100,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection(RewardsConstants.coinTransactionsCollection)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => CoinTransaction.fromFirestore(doc))
          .toList();
    } catch (e, st) {
      AppLogger.error('Get transaction history failed: $e', e, st);
      return [];
    }
  }

  // ============================================================================
  // STREAK & BONUSES
  // ============================================================================

  /// Check and update streak
  Future<void> checkAndUpdateStreak() async {
    try {
      final stats = await getUserStats();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      if (stats.lastActivityDate == null) {
        // First activity
        final newStats = stats.copyWith(
          currentStreak: 1,
          longestStreak: 1,
          lastActivityDate: today,
        );
        await _updateUserStats(newStats);

        // Award first time bonus
        await _addCoins(
          amount: RewardsConstants.firstTimeBonus,
          type: TransactionType.bonus,
          description: 'First time bonus',
        );

        AppLogger.info('First time bonus awarded: ${RewardsConstants.firstTimeBonus} coins');
        return;
      }

      final lastActivity =
          DateTime(stats.lastActivityDate!.year, stats.lastActivityDate!.month,
              stats.lastActivityDate!.day);

      final daysDiff = today.difference(lastActivity).inDays;

      if (daysDiff == 0) {
        // Same day, no streak update
        return;
      } else if (daysDiff == 1) {
        // Consecutive day
        final newStreak = stats.currentStreak + 1;
        final newLongest = newStreak > stats.longestStreak
            ? newStreak
            : stats.longestStreak;

        final newStats = stats.copyWith(
          currentStreak: newStreak,
          longestStreak: newLongest,
          lastActivityDate: today,
        );
        await _updateUserStats(newStats);

        AppLogger.info('Streak updated: $newStreak days');
      } else {
        // Streak broken
        final newStats = stats.copyWith(
          currentStreak: 1,
          lastActivityDate: today,
        );
        await _updateUserStats(newStats);

        AppLogger.info('Streak broken, reset to 1');
      }
    } catch (e, st) {
      AppLogger.error('Check and update streak failed: $e', e, st);
    }
  }

  /// Award daily bonus
  Future<void> awardDailyBonus() async {
    try {
      await _addCoins(
        amount: RewardsConstants.dailyLoginBonus,
        type: TransactionType.bonus,
        description: 'Daily login bonus',
      );

      AppLogger.info('Daily bonus awarded: ${RewardsConstants.dailyLoginBonus} coins');
    } catch (e, st) {
      AppLogger.error('Award daily bonus failed: $e', e, st);
    }
  }

  // ============================================================================
  // ANTI-FRAUD
  // ============================================================================

  /// Check if user can claim box (anti-fraud)
  Future<bool> canClaimBox() async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      // Check boxes opened today
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection(RewardsConstants.mysteryBoxesCollection)
          .where('earned_at', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .get();

      if (snapshot.docs.length >= RewardsConstants.maxBoxesPerDay) {
        AppLogger.warning('Max boxes per day reached');
        return false;
      }

      // Check cooldown
      if (snapshot.docs.isNotEmpty) {
        final lastBox = RewardBox.fromFirestore(snapshot.docs.first);
        final timeSinceLastBox = now.difference(lastBox.earnedAt);

        if (timeSinceLastBox.inHours < RewardsConstants.boxCooldownHours) {
          AppLogger.warning('Box cooldown active');
          return false;
        }
      }

      return true;
    } catch (e, st) {
      AppLogger.error('Can claim box check failed: $e', e, st);
      return false;
    }
  }

  // ============================================================================
  // REDEMPTION MANAGEMENT
  // ============================================================================

  /// Get available redemption offers
  Future<List<RedemptionOffer>> getRedemptionOffers({
    RedemptionType? type,
    int? maxCoins,
  }) async {
    try {
      Query query = _firestore.collection('redemption_offers');

      // Filter by type if specified
      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }

      // Filter by active status
      query = query.where('is_active', isEqualTo: true);

      final snapshot = await query.get();
      AppLogger.info('📦 Fetched ${snapshot.docs.length} offers from Firestore');
      
      final offers = snapshot.docs
          .map((doc) {
            try {
              return RedemptionOffer.fromFirestore(doc);
            } catch (e) {
              AppLogger.error('Error parsing offer ${doc.id}: $e');
              return null;
            }
          })
          .whereType<RedemptionOffer>()
          .where((offer) => offer.isAvailable)
          .toList();

      AppLogger.info('✅ Parsed ${offers.length} available offers');

      // Filter by max coins if specified
      if (maxCoins != null) {
        offers.removeWhere((offer) => offer.coinsRequired > maxCoins);
      }

      // Sort by coins required (ascending)
      offers.sort((a, b) => a.coinsRequired.compareTo(b.coinsRequired));

      return offers;
    } catch (e, st) {
      AppLogger.error('Get redemption offers failed: $e', e, st);
      return [];
    }
  }

  /// Redeem an offer
  Future<UserRedemption> redeemOffer(String offerId) async {
    try {
      // Get offer details
      final offerDoc =
          await _firestore.collection('redemption_offers').doc(offerId).get();

      if (!offerDoc.exists) {
        throw Exception('Offer not found');
      }

      final offer = RedemptionOffer.fromFirestore(offerDoc);

      // Validate offer availability
      if (!offer.isAvailable) {
        throw Exception('Offer is not available');
      }

      // Check user balance
      final stats = await getUserStats();
      if (stats.totalCoins < offer.coinsRequired) {
        throw Exception('Insufficient coins');
      }

      // Check redemption limits
      await _validateRedemptionLimits(offer.type);

      // Check account requirements for cash
      if (offer.type == RedemptionType.cash) {
        await _validateCashWithdrawalRequirements();
      }

      // Create redemption record
      final redemptionRef = _firestore
          .collection('users')
          .doc(userId)
          .collection(RewardsConstants.redemptionsCollection)
          .doc();

      final now = DateTime.now();
      final redemption = UserRedemption(
        id: redemptionRef.id,
        userId: userId,
        offerId: offerId,
        offerTitle: offer.title,
        type: offer.type,
        coinsSpent: offer.coinsRequired,
        cashValue: offer.cashValue,
        status: RedemptionStatus.pending,
        redeemedAt: now,
        expiryDate: offer.type == RedemptionType.voucher
            ? now.add(Duration(days: RewardsConstants.voucherValidityDays))
            : null,
        voucherCode: offer.type == RedemptionType.voucher
            ? _generateVoucherCode()
            : null,
        qrCodeData: offer.type == RedemptionType.voucher
            ? _generateQRCodeData(redemptionRef.id)
            : null,
      );

      // Save redemption
      await redemptionRef.set(redemption.toFirestore());

      // Spend coins
      await _spendCoins(
        amount: offer.coinsRequired,
        description: 'Redeemed: ${offer.title}',
        relatedRedemptionId: redemptionRef.id,
      );

      // Update offer stock if limited
      if (offer.stockRemaining != null) {
        await _firestore.collection('redemption_offers').doc(offerId).update({
          'stock_remaining': FieldValue.increment(-1),
          'updated_at': Timestamp.now(),
        });
      }

      // Auto-complete for vouchers (instant), pending for cash
      if (offer.type == RedemptionType.voucher) {
        await _completeRedemption(redemptionRef.id);
        return redemption.copyWith(status: RedemptionStatus.completed);
      }

      AppLogger.info('Redemption created: ${offer.title}, ${offer.coinsRequired} coins');

      return redemption;
    } catch (e, st) {
      AppLogger.error('Redeem offer failed: $e', e, st);
      rethrow;
    }
  }

  /// Get user redemption history
  Future<List<UserRedemption>> getRedemptionHistory({
    int limit = 50,
    RedemptionType? type,
    RedemptionStatus? status,
  }) async {
    try {
      Query query = _firestore
          .collection('users')
          .doc(userId)
          .collection(RewardsConstants.redemptionsCollection);

      // Filter by type if specified
      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }

      // Filter by status if specified
      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      query = query.orderBy('redeemed_at', descending: true).limit(limit);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => UserRedemption.fromFirestore(doc))
          .toList();
    } catch (e, st) {
      AppLogger.error('Get redemption history failed: $e', e, st);
      return [];
    }
  }

  /// Get active vouchers (completed, not expired, not used)
  Future<List<UserRedemption>> getActiveVouchers() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection(RewardsConstants.redemptionsCollection)
          .where('type', isEqualTo: RedemptionType.voucher.name)
          .where('status', isEqualTo: RedemptionStatus.completed.name)
          .orderBy('redeemed_at', descending: true)
          .get();

      // Filter out expired vouchers
      return snapshot.docs
          .map((doc) => UserRedemption.fromFirestore(doc))
          .where((v) => v.expiryDate != null && v.expiryDate!.isAfter(now))
          .toList();
    } catch (e, st) {
      AppLogger.error('Get active vouchers failed: $e', e, st);
      return [];
    }
  }

  /// Use a voucher (mark as used)
  Future<void> useVoucher(String redemptionId) async {
    try {
      final redemptionRef = _firestore
          .collection('users')
          .doc(userId)
          .collection(RewardsConstants.redemptionsCollection)
          .doc(redemptionId);

      final doc = await redemptionRef.get();
      if (!doc.exists) {
        throw Exception('Redemption not found');
      }

      final redemption = UserRedemption.fromFirestore(doc);

      // Validate
      if (redemption.type != RedemptionType.voucher) {
        throw Exception('Not a voucher redemption');
      }

      if (redemption.status != RedemptionStatus.completed) {
        throw Exception('Voucher is not ready to use');
      }

      if (redemption.isExpired) {
        throw Exception('Voucher has expired');
      }

      // Mark as used
      await redemptionRef.update({
        'status': RedemptionStatus.used.name,
        'completed_at': Timestamp.now(),
      });

      AppLogger.info('Voucher used: $redemptionId');
    } catch (e, st) {
      AppLogger.error('Use voucher failed: $e', e, st);
      rethrow;
    }
  }

  /// Cancel a redemption (refund coins)
  Future<void> cancelRedemption(String redemptionId) async {
    try {
      final redemptionRef = _firestore
          .collection('users')
          .doc(userId)
          .collection(RewardsConstants.redemptionsCollection)
          .doc(redemptionId);

      final doc = await redemptionRef.get();
      if (!doc.exists) {
        throw Exception('Redemption not found');
      }

      final redemption = UserRedemption.fromFirestore(doc);

      // Validate - can only cancel pending or processing
      if (redemption.status.isFinal) {
        throw Exception('Cannot cancel completed/used/failed redemption');
      }

      // Mark as cancelled
      await redemptionRef.update({
        'status': RedemptionStatus.cancelled.name,
        'completed_at': Timestamp.now(),
        'failure_reason': 'Cancelled by user',
      });

      // Refund coins
      await _addCoins(
        amount: redemption.coinsSpent,
        type: TransactionType.redemptionRefund,
        description: 'Refund: ${redemption.offerTitle}',
        relatedRedemptionId: redemptionId,
      );

      // Restore stock if it was limited
      final offerDoc = await _firestore
          .collection('redemption_offers')
          .doc(redemption.offerId)
          .get();

      if (offerDoc.exists) {
        final offer = RedemptionOffer.fromFirestore(offerDoc);
        if (offer.stockRemaining != null) {
          await offerDoc.reference.update({
            'stock_remaining': FieldValue.increment(1),
          });
        }
      }

      AppLogger.info('Redemption cancelled: $redemptionId');
    } catch (e, st) {
      AppLogger.error('Cancel redemption failed: $e', e, st);
      rethrow;
    }
  }

  // ============================================================================
  // REDEMPTION VALIDATION & HELPERS
  // ============================================================================

  /// Validate redemption limits
  Future<void> _validateRedemptionLimits(RedemptionType type) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    // Get redemptions for period
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection(RewardsConstants.redemptionsCollection)
        .where('redeemed_at', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .get();

    final todayRedemptions = snapshot.docs
        .map((doc) => UserRedemption.fromFirestore(doc))
        .toList();

    // Check daily limits
    if (type == RedemptionType.voucher) {
      final todayVouchers =
          todayRedemptions.where((r) => r.type == RedemptionType.voucher).length;
      if (todayVouchers >= RewardsConstants.maxVouchersPerDay) {
        throw Exception('Daily voucher limit reached');
      }
    }

    if (type == RedemptionType.cash) {
      final todayCash = todayRedemptions
          .where((r) => r.type == RedemptionType.cash)
          .fold<int>(0, (sum, r) => sum + r.cashValue);
      if (todayCash >= RewardsConstants.maxCashPerDay) {
        throw Exception('Daily cash limit reached');
      }
    }

    // Check weekly limits (simplified - checking last 7 days)
    final weekSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection(RewardsConstants.redemptionsCollection)
        .where('redeemed_at', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
        .get();

    final weekRedemptions = weekSnapshot.docs
        .map((doc) => UserRedemption.fromFirestore(doc))
        .toList();

    if (type == RedemptionType.voucher) {
      final weekVouchers =
          weekRedemptions.where((r) => r.type == RedemptionType.voucher).length;
      if (weekVouchers >= RewardsConstants.maxVouchersPerWeek) {
        throw Exception('Weekly voucher limit reached');
      }
    }

    if (type == RedemptionType.cash) {
      final weekCash = weekRedemptions
          .where((r) => r.type == RedemptionType.cash)
          .fold<int>(0, (sum, r) => sum + r.cashValue);
      if (weekCash >= RewardsConstants.maxCashPerWeek) {
        throw Exception('Weekly cash limit reached');
      }
    }
  }

  /// Validate cash withdrawal requirements
  Future<void> _validateCashWithdrawalRequirements() async {
    // Check account age
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      final createdAt = (userDoc.data()?['created_at'] as Timestamp?)?.toDate();
      if (createdAt != null) {
        final accountAge = DateTime.now().difference(createdAt).inDays;
        if (accountAge < RewardsConstants.minAccountAgeDaysForCash) {
          throw Exception('Account too new for cash withdrawal');
        }
      }
    }

    // Check boxes opened
    final stats = await getUserStats();
    if (stats.totalBoxesOpened < RewardsConstants.minBoxesOpenedForCash) {
      throw Exception('Need to open more boxes for cash withdrawal');
    }
  }

  /// Complete a redemption (for testing/admin)
  Future<void> _completeRedemption(String redemptionId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection(RewardsConstants.redemptionsCollection)
          .doc(redemptionId)
          .update({
        'status': RedemptionStatus.completed.name,
        'completed_at': Timestamp.now(),
      });
    } catch (e, st) {
      AppLogger.error('Complete redemption failed: $e', e, st);
    }
  }

  /// Generate voucher code
  String _generateVoucherCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final code = List.generate(
      8,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
    return 'VCH-$code';
  }

  /// Generate QR code data
  String _generateQRCodeData(String redemptionId) {
    // Format: REDEMPTION:userId:redemptionId:timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'REDEMPTION:$userId:$redemptionId:$timestamp';
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Update stats after box opened
  Future<void> _updateStatsAfterBoxOpened(RewardBox box) async {
    try {
      final stats = await getUserStats();

      // Increment box count by rarity
      int bronze = stats.bronzeBoxesOpened;
      int silver = stats.silverBoxesOpened;
      int gold = stats.goldBoxesOpened;
      int diamond = stats.diamondBoxesOpened;

      switch (box.rarity) {
        case BoxRarity.bronze:
          bronze++;
          break;
        case BoxRarity.silver:
          silver++;
          break;
        case BoxRarity.gold:
          gold++;
          break;
        case BoxRarity.diamond:
          diamond++;
          break;
      }

      final newStats = stats.copyWith(
        totalBoxesOpened: stats.totalBoxesOpened + 1,
        lastBoxOpenedAt: box.openedAt ?? DateTime.now(),
        bronzeBoxesOpened: bronze,
        silverBoxesOpened: silver,
        goldBoxesOpened: gold,
        diamondBoxesOpened: diamond,
      );

      await _updateUserStats(newStats);
    } catch (e, st) {
      AppLogger.error('Update stats after box opened failed: $e', e, st);
    }
  }
}
