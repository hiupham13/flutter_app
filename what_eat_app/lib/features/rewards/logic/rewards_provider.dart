import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/reward_model.dart';
import '../../auth/logic/auth_provider.dart';
import '../data/rewards_repository.dart';

// ============================================================================
// REPOSITORY PROVIDERS
// ============================================================================

/// Provider for RewardsRepository
final rewardsRepositoryProvider = Provider<RewardsRepository?>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) =>
        user != null ? RewardsRepository(userId: user.uid) : null,
    loading: () => null,
    error: (_, __) => null,
  );
});

// ============================================================================
// STATS PROVIDERS
// ============================================================================

/// Stream provider for user rewards stats (real-time)
final userRewardsStatsProvider = StreamProvider<UserRewardsStats>((ref) {
  final repository = ref.watch(rewardsRepositoryProvider);

  if (repository == null) {
    return Stream.value(const UserRewardsStats());
  }

  return repository.watchUserStats();
});

/// Future provider for user stats (one-time)
final userRewardsStatsOnceProvider = FutureProvider<UserRewardsStats>((ref) async {
  final repository = ref.watch(rewardsRepositoryProvider);

  if (repository == null) {
    return const UserRewardsStats();
  }

  return repository.getUserStats();
});

/// Provider for current coin balance (derived from stats)
final coinBalanceProvider = Provider<int>((ref) {
  final stats = ref.watch(userRewardsStatsProvider);

  return stats.when(
    data: (data) => data.totalCoins,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider for current streak (derived from stats)
final currentStreakProvider = Provider<int>((ref) {
  final stats = ref.watch(userRewardsStatsProvider);

  return stats.when(
    data: (data) => data.currentStreak,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// ============================================================================
// MYSTERY BOXES PROVIDERS
// ============================================================================

/// Future provider for pending (unopened) boxes
final pendingBoxesProvider = FutureProvider<List<RewardBox>>((ref) async {
  final repository = ref.watch(rewardsRepositoryProvider);

  if (repository == null) {
    return [];
  }

  return repository.getPendingBoxes();
});

/// Provider for pending boxes count
final pendingBoxesCountProvider = Provider<int>((ref) {
  final boxes = ref.watch(pendingBoxesProvider);

  return boxes.when(
    data: (data) => data.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Future provider for box history
final boxHistoryProvider = FutureProvider<List<RewardBox>>((ref) async {
  final repository = ref.watch(rewardsRepositoryProvider);

  if (repository == null) {
    return [];
  }

  return repository.getBoxHistory();
});

// ============================================================================
// TRANSACTION PROVIDERS
// ============================================================================

/// Future provider for transaction history
final transactionHistoryProvider =
    FutureProvider<List<CoinTransaction>>((ref) async {
  final repository = ref.watch(rewardsRepositoryProvider);

  if (repository == null) {
    return [];
  }

  return repository.getTransactionHistory();
});

// ============================================================================
// CAN CLAIM PROVIDER
// ============================================================================

/// Future provider to check if user can claim a box
final canClaimBoxProvider = FutureProvider<bool>((ref) async {
  final repository = ref.watch(rewardsRepositoryProvider);

  if (repository == null) {
    return false;
  }

  return repository.canClaimBox();
});

// ============================================================================
// REWARDS CONTROLLER
// ============================================================================

/// Controller for rewards operations (user actions)
final rewardsControllerProvider = Provider<RewardsController>((ref) {
  return RewardsController(ref);
});

/// Rewards controller class
class RewardsController {
  final Ref _ref;

  RewardsController(this._ref);

  /// Get repository
  RewardsRepository? get _repository =>
      _ref.read(rewardsRepositoryProvider);

  /// Generate a mystery box for user
  Future<RewardBox?> generateMysteryBox({
    String? sourceRecommendationId,
  }) async {
    final repository = _repository;
    if (repository == null) {
      throw Exception('User not authenticated');
    }

    // Check if user can claim
    final canClaim = await repository.canClaimBox();
    if (!canClaim) {
      throw Exception('Cannot claim box at this time');
    }

    // Generate box
    final box = await repository.generateMysteryBox(
      sourceRecommendationId: sourceRecommendationId,
    );

    // Invalidate pending boxes to refresh
    _ref.invalidate(pendingBoxesProvider);

    return box;
  }

  /// Open a mystery box
  Future<int> openMysteryBox(String boxId) async {
    final repository = _repository;
    if (repository == null) {
      throw Exception('User not authenticated');
    }

    // Open box and get coins awarded
    final coinsAwarded = await repository.openMysteryBox(boxId);

    // Invalidate providers to refresh
    _ref.invalidate(pendingBoxesProvider);
    _ref.invalidate(boxHistoryProvider);
    _ref.invalidate(transactionHistoryProvider);
    // Stats will auto-update via stream

    return coinsAwarded;
  }

  /// Check and update daily streak
  Future<void> checkDailyStreak() async {
    final repository = _repository;
    if (repository == null) return;

    await repository.checkAndUpdateStreak();
  }

  /// Award daily bonus
  Future<void> awardDailyBonus() async {
    final repository = _repository;
    if (repository == null) return;

    await repository.awardDailyBonus();

    // Invalidate transaction history
    _ref.invalidate(transactionHistoryProvider);
  }

  /// Refresh all rewards data
  void refreshAll() {
    _ref.invalidate(pendingBoxesProvider);
    _ref.invalidate(boxHistoryProvider);
    _ref.invalidate(transactionHistoryProvider);
    _ref.invalidate(canClaimBoxProvider);
  }
}

// ============================================================================
// STATE NOTIFIER FOR BOX OPENING FLOW
// ============================================================================

/// State for box opening flow
class BoxOpeningState {
  final bool isOpening;
  final RewardBox? currentBox;
  final int? coinsAwarded;
  final String? error;

  const BoxOpeningState({
    this.isOpening = false,
    this.currentBox,
    this.coinsAwarded,
    this.error,
  });

  BoxOpeningState copyWith({
    bool? isOpening,
    RewardBox? currentBox,
    int? coinsAwarded,
    String? error,
  }) {
    return BoxOpeningState(
      isOpening: isOpening ?? this.isOpening,
      currentBox: currentBox ?? this.currentBox,
      coinsAwarded: coinsAwarded ?? this.coinsAwarded,
      error: error ?? this.error,
    );
  }
}

/// State notifier for box opening flow
class BoxOpeningNotifier extends StateNotifier<BoxOpeningState> {
  final Ref _ref;

  BoxOpeningNotifier(this._ref) : super(const BoxOpeningState());

  /// Get repository
  RewardsRepository? get _repository =>
      _ref.read(rewardsRepositoryProvider);

  /// Start box opening animation
  Future<void> openBox(RewardBox box) async {
    if (state.isOpening) return;

    state = state.copyWith(
      isOpening: true,
      currentBox: box,
      error: null,
    );

    try {
      final repository = _repository;
      if (repository == null) {
        throw Exception('Not authenticated');
      }

      // Simulate animation delay (3 seconds)
      await Future.delayed(const Duration(milliseconds: 3000));

      // Actually open the box
      final coins = await repository.openMysteryBox(box.id);

      state = state.copyWith(
        isOpening: false,
        coinsAwarded: coins,
      );

      // Invalidate providers
      _ref.invalidate(pendingBoxesProvider);
      _ref.invalidate(boxHistoryProvider);
      _ref.invalidate(transactionHistoryProvider);
    } catch (e) {
      state = state.copyWith(
        isOpening: false,
        error: e.toString(),
      );
    }
  }

  /// Reset state
  void reset() {
    state = const BoxOpeningState();
  }
}

/// Provider for box opening state notifier
final boxOpeningProvider =
    StateNotifierProvider<BoxOpeningNotifier, BoxOpeningState>((ref) {
  return BoxOpeningNotifier(ref);
});

// ============================================================================
// REDEMPTION OFFERS PROVIDERS
// ============================================================================

/// Future provider for all redemption offers
final redemptionOffersProvider =
    FutureProvider<List<RedemptionOffer>>((ref) async {
  final repository = ref.watch(rewardsRepositoryProvider);

  if (repository == null) {
    return [];
  }

  return repository.getRedemptionOffers();
});

/// Family provider for offers filtered by type
final redemptionOffersByTypeProvider = FutureProvider.family<
    List<RedemptionOffer>, RedemptionType?>((ref, type) async {
  final repository = ref.watch(rewardsRepositoryProvider);

  if (repository == null) {
    return [];
  }

  return repository.getRedemptionOffers(type: type);
});

/// Provider for offers user can afford
final affordableOffersProvider =
    FutureProvider<List<RedemptionOffer>>((ref) async {
  final repository = ref.watch(rewardsRepositoryProvider);
  final coinBalance = ref.watch(coinBalanceProvider);

  if (repository == null) {
    return [];
  }

  return repository.getRedemptionOffers(maxCoins: coinBalance);
});

/// Provider for voucher offers only
final voucherOffersProvider = Provider<AsyncValue<List<RedemptionOffer>>>((ref) {
  return ref.watch(redemptionOffersByTypeProvider(RedemptionType.voucher));
});

/// Provider for cash offers only
final cashOffersProvider = Provider<AsyncValue<List<RedemptionOffer>>>((ref) {
  return ref.watch(redemptionOffersByTypeProvider(RedemptionType.cash));
});

/// Provider for premium offers only
final premiumOffersProvider = Provider<AsyncValue<List<RedemptionOffer>>>((ref) {
  return ref.watch(redemptionOffersByTypeProvider(RedemptionType.premium));
});

// ============================================================================
// USER REDEMPTIONS PROVIDERS
// ============================================================================

/// Future provider for user's redemption history
final userRedemptionsProvider =
    FutureProvider<List<UserRedemption>>((ref) async {
  final repository = ref.watch(rewardsRepositoryProvider);

  if (repository == null) {
    return [];
  }

  return repository.getRedemptionHistory();
});

/// Family provider for redemptions filtered by type
final redemptionsByTypeProvider = FutureProvider.family<List<UserRedemption>,
    RedemptionType?>((ref, type) async {
  final repository = ref.watch(rewardsRepositoryProvider);

  if (repository == null) {
    return [];
  }

  return repository.getRedemptionHistory(type: type);
});

/// Family provider for redemptions filtered by status
final redemptionsByStatusProvider = FutureProvider.family<
    List<UserRedemption>, RedemptionStatus?>((ref, status) async {
  final repository = ref.watch(rewardsRepositoryProvider);

  if (repository == null) {
    return [];
  }

  return repository.getRedemptionHistory(status: status);
});

/// Provider for active vouchers (usable)
final activeVouchersProvider =
    FutureProvider<List<UserRedemption>>((ref) async {
  final repository = ref.watch(rewardsRepositoryProvider);

  if (repository == null) {
    return [];
  }

  return repository.getActiveVouchers();
});

/// Provider for active vouchers count
final activeVouchersCountProvider = Provider<int>((ref) {
  final vouchers = ref.watch(activeVouchersProvider);

  return vouchers.when(
    data: (data) => data.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// ============================================================================
// REDEMPTION CONTROLLER
// ============================================================================

/// Controller for redemption operations
final redemptionControllerProvider = Provider<RedemptionController>((ref) {
  return RedemptionController(ref);
});

/// Redemption controller class
class RedemptionController {
  final Ref _ref;

  RedemptionController(this._ref);

  /// Get repository
  RewardsRepository? get _repository =>
      _ref.read(rewardsRepositoryProvider);

  /// Redeem an offer
  Future<UserRedemption> redeemOffer(String offerId) async {
    final repository = _repository;
    if (repository == null) {
      throw Exception('User not authenticated');
    }

    // Redeem the offer
    final redemption = await repository.redeemOffer(offerId);

    // Invalidate providers to refresh
    _ref.invalidate(userRedemptionsProvider);
    _ref.invalidate(activeVouchersProvider);
    _ref.invalidate(transactionHistoryProvider);
    _ref.invalidate(redemptionOffersProvider);
    // Stats will auto-update via stream

    return redemption;
  }

  /// Cancel a redemption
  Future<void> cancelRedemption(String redemptionId) async {
    final repository = _repository;
    if (repository == null) {
      throw Exception('User not authenticated');
    }

    await repository.cancelRedemption(redemptionId);

    // Invalidate providers to refresh
    _ref.invalidate(userRedemptionsProvider);
    _ref.invalidate(activeVouchersProvider);
    _ref.invalidate(transactionHistoryProvider);
    _ref.invalidate(redemptionOffersProvider);
    // Stats will auto-update via stream
  }

  /// Use a voucher
  Future<void> useVoucher(String redemptionId) async {
    final repository = _repository;
    if (repository == null) {
      throw Exception('User not authenticated');
    }

    await repository.useVoucher(redemptionId);

    // Invalidate providers to refresh
    _ref.invalidate(userRedemptionsProvider);
    _ref.invalidate(activeVouchersProvider);
  }

  /// Refresh all redemption data
  void refreshAll() {
    _ref.invalidate(redemptionOffersProvider);
    _ref.invalidate(userRedemptionsProvider);
    _ref.invalidate(activeVouchersProvider);
  }
}

// ============================================================================
// STATE NOTIFIER FOR REDEMPTION FLOW
// ============================================================================

/// State for redemption flow
class RedemptionState {
  final bool isRedeeming;
  final UserRedemption? currentRedemption;
  final String? error;

  const RedemptionState({
    this.isRedeeming = false,
    this.currentRedemption,
    this.error,
  });

  RedemptionState copyWith({
    bool? isRedeeming,
    UserRedemption? currentRedemption,
    String? error,
  }) {
    return RedemptionState(
      isRedeeming: isRedeeming ?? this.isRedeeming,
      currentRedemption: currentRedemption ?? this.currentRedemption,
      error: error ?? this.error,
    );
  }
}

/// State notifier for redemption flow
class RedemptionNotifier extends StateNotifier<RedemptionState> {
  final Ref _ref;

  RedemptionNotifier(this._ref) : super(const RedemptionState());

  /// Get repository
  RewardsRepository? get _repository =>
      _ref.read(rewardsRepositoryProvider);

  /// Start redemption process
  Future<void> redeemOffer(String offerId) async {
    if (state.isRedeeming) return;

    state = state.copyWith(
      isRedeeming: true,
      error: null,
    );

    try {
      final repository = _repository;
      if (repository == null) {
        throw Exception('Not authenticated');
      }

      // Redeem the offer
      final redemption = await repository.redeemOffer(offerId);

      state = state.copyWith(
        isRedeeming: false,
        currentRedemption: redemption,
      );

      // Invalidate providers
      _ref.invalidate(userRedemptionsProvider);
      _ref.invalidate(activeVouchersProvider);
      _ref.invalidate(transactionHistoryProvider);
      _ref.invalidate(redemptionOffersProvider);
    } catch (e) {
      state = state.copyWith(
        isRedeeming: false,
        error: e.toString(),
      );
    }
  }

  /// Reset state
  void reset() {
    state = const RedemptionState();
  }
}

/// Provider for redemption state notifier
final redemptionProvider =
    StateNotifierProvider<RedemptionNotifier, RedemptionState>((ref) {
  return RedemptionNotifier(ref);
});
