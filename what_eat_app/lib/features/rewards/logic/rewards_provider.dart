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
