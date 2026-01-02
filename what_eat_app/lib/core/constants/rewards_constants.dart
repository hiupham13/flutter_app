/// Coin economy constants for the rewards system
class RewardsConstants {
  RewardsConstants._();

  // ============================================================================
  // COIN DROP RATES
  // ============================================================================

  /// Bronze box coin range
  static const int bronzeMinCoins = 10;
  static const int bronzeMaxCoins = 100;

  /// Silver box coin range
  static const int silverMinCoins = 100;
  static const int silverMaxCoins = 500;

  /// Gold box coin range
  static const int goldMinCoins = 500;
  static const int goldMaxCoins = 1000;

  /// Diamond box coin range
  static const int diamondMinCoins = 1000;
  static const int diamondMaxCoins = 5000;

  // ============================================================================
  // BOX DROP PROBABILITIES
  // ============================================================================

  /// Bronze box drop rate (70%)
  static const double bronzeProbability = 0.70;

  /// Silver box drop rate (20%)
  static const double silverProbability = 0.20;

  /// Gold box drop rate (8%)
  static const double goldProbability = 0.08;

  /// Diamond box drop rate (2%)
  static const double diamondProbability = 0.02;

  // ============================================================================
  // VERIFICATION REQUIREMENTS
  // ============================================================================

  /// Minimum distance to restaurant (meters)
  static const double minimumDistanceMeters = 50.0;

  /// Maximum distance to restaurant (meters)
  static const double maximumDistanceMeters = 500.0;

  /// Minimum time at location (minutes)
  static const int minimumTimeAtLocationMinutes = 15;

  /// Cooldown between boxes (hours)
  static const int boxCooldownHours = 2;

  /// Maximum boxes per day (anti-fraud)
  static const int maxBoxesPerDay = 5;

  // ============================================================================
  // STREAK & BONUS
  // ============================================================================

  /// Daily login bonus coins
  static const int dailyLoginBonus = 10;

  /// Streak multipliers
  static const Map<int, double> streakMultipliers = {
    3: 1.1, // 3 days: +10%
    7: 1.25, // 7 days: +25%
    14: 1.5, // 14 days: +50%
    30: 2.0, // 30 days: +100%
  };

  /// First time bonus
  static const int firstTimeBonus = 100;

  // ============================================================================
  // COIN EXPIRY
  // ============================================================================

  /// Coins expire after X days (0 = never)
  static const int coinExpiryDays = 90;

  /// Warning before expiry (days)
  static const int expiryWarningDays = 7;

  // ============================================================================
  // REDEMPTION
  // ============================================================================

  /// Minimum coins to redeem
  static const int minimumRedemptionCoins = 50;

  /// Coin to VND exchange rate (1000 coins = X VND)
  static const int coinsPerVND = 20; // 1000 coins = 50,000 VND

  // ============================================================================
  // UI ANIMATIONS
  // ============================================================================

  /// Box opening animation duration (milliseconds)
  static const int boxOpeningDurationMs = 3000;

  /// Coin fly animation duration (milliseconds)
  static const int coinFlyDurationMs = 1000;

  /// Confetti duration for big wins (milliseconds)
  static const int confettiDurationMs = 3000;

  // ============================================================================
  // FIREBASE COLLECTIONS
  // ============================================================================

  /// User rewards stats subcollection
  static const String rewardsStatsCollection = 'rewards_stats';

  /// Mystery boxes subcollection
  static const String mysteryBoxesCollection = 'mystery_boxes';

  /// Coin transactions subcollection
  static const String coinTransactionsCollection = 'coin_transactions';

  /// Redemptions subcollection
  static const String redemptionsCollection = 'redemptions';

  // ============================================================================
  // ANTI-FRAUD
  // ============================================================================

  /// Max boxes from same location per day
  static const int maxBoxesFromSameLocationPerDay = 2;

  /// Min time between boxes from same location (hours)
  static const int minTimeBetweenSameLocationBoxesHours = 4;

  /// Suspicious activity threshold (boxes per hour)
  static const int suspiciousBoxesPerHour = 3;

  // ============================================================================
  // ACHIEVEMENTS
  // ============================================================================

  /// Achievement milestones
  static const Map<String, int> achievementMilestones = {
    'first_box': 1,
    'box_opener': 10,
    'box_master': 50,
    'box_legend': 100,
    'coin_collector': 1000,
    'coin_millionaire': 10000,
    'streak_beginner': 3,
    'streak_dedicated': 7,
    'streak_champion': 30,
  };

  // ============================================================================
  // HELPERS
  // ============================================================================

  /// Get streak multiplier for given streak days
  static double getStreakMultiplier(int streakDays) {
    double multiplier = 1.0;
    for (final entry in streakMultipliers.entries) {
      if (streakDays >= entry.key) {
        multiplier = entry.value;
      }
    }
    return multiplier;
  }

  /// Calculate coins value in VND
  static int coinsToVND(int coins) {
    return (coins / coinsPerVND * 1000).round();
  }

  /// Calculate VND to coins
  static int vndToCoins(int vnd) {
    return ((vnd / 1000) * coinsPerVND).round();
  }

  /// Check if amount is big win (top 10%)
  static bool isBigWin(int coins) {
    return coins >= goldMinCoins;
  }

  /// Check if amount is jackpot (top 2%)
  static bool isJackpot(int coins) {
    return coins >= diamondMinCoins;
  }
}
