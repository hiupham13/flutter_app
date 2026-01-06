import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:what_eat_app/core/constants/rewards_constants.dart';
import 'package:what_eat_app/features/rewards/data/rewards_repository.dart';
import 'package:what_eat_app/models/reward_model.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late RewardsRepository repository;
  const testUserId = 'test_user_123';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repository = RewardsRepository(
      userId: testUserId,
      firestore: fakeFirestore,
    );
  });

  group('RewardsRepository - User Stats', () {
    test('getUserStats returns initial stats when document does not exist', () async {
      final stats = await repository.getUserStats();

      expect(stats.totalCoins, 0);
      expect(stats.totalCoinsEarned, 0);
      expect(stats.totalCoinsSpent, 0);
      expect(stats.totalBoxesOpened, 0);
      expect(stats.currentStreak, 0);
    });

    test('getUserStats returns existing stats', () async {
      // Setup: Create initial stats
      final initialStats = const UserRewardsStats(
        totalCoins: 500,
        totalCoinsEarned: 1000,
        totalCoinsSpent: 500,
        totalBoxesOpened: 10,
      );

      await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection(RewardsConstants.rewardsStatsCollection)
          .doc('summary')
          .set(initialStats.toMap());

      // Test
      final stats = await repository.getUserStats();

      expect(stats.totalCoins, 500);
      expect(stats.totalCoinsEarned, 1000);
      expect(stats.totalCoinsSpent, 500);
      expect(stats.totalBoxesOpened, 10);
    });

    test('watchUserStats streams real-time updates', () async {
      // Setup initial stats
      final initialStats = const UserRewardsStats(totalCoins: 100);
      await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection(RewardsConstants.rewardsStatsCollection)
          .doc('summary')
          .set(initialStats.toMap());

      // Test stream
      final stream = repository.watchUserStats();
      
      expect(
        stream,
        emitsInOrder([
          predicate<UserRewardsStats>((stats) => stats.totalCoins == 100),
        ]),
      );
    });
  });

  group('RewardsRepository - Mystery Box Generation', () {
    test('generateMysteryBox creates box with valid rarity', () async {
      final box = await repository.generateMysteryBox(
        sourceRecommendationId: 'rec_123',
      );

      expect(box.id, isNotEmpty);
      expect(box.rarity, isIn(BoxRarity.values));
      expect(box.coinsAwarded, greaterThan(0));
      expect(box.isOpened, false);
      expect(box.sourceRecommendationId, 'rec_123');
      expect(box.earnedAt, isNotNull);
    });

    test('generateMysteryBox respects rarity coin ranges', () async {
      // Generate multiple boxes to test ranges
      for (int i = 0; i < 20; i++) {
        final box = await repository.generateMysteryBox();

        switch (box.rarity) {
          case BoxRarity.bronze:
            expect(box.coinsAwarded, greaterThanOrEqualTo(RewardsConstants.bronzeMinCoins));
            expect(box.coinsAwarded, lessThanOrEqualTo(RewardsConstants.bronzeMaxCoins));
            break;
          case BoxRarity.silver:
            expect(box.coinsAwarded, greaterThanOrEqualTo(RewardsConstants.silverMinCoins));
            expect(box.coinsAwarded, lessThanOrEqualTo(RewardsConstants.silverMaxCoins));
            break;
          case BoxRarity.gold:
            expect(box.coinsAwarded, greaterThanOrEqualTo(RewardsConstants.goldMinCoins));
            expect(box.coinsAwarded, lessThanOrEqualTo(RewardsConstants.goldMaxCoins));
            break;
          case BoxRarity.diamond:
            expect(box.coinsAwarded, greaterThanOrEqualTo(RewardsConstants.diamondMinCoins));
            expect(box.coinsAwarded, lessThanOrEqualTo(RewardsConstants.diamondMaxCoins));
            break;
        }
      }
    });

    test('generateMysteryBox saves to Firestore', () async {
      final box = await repository.generateMysteryBox();

      final doc = await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection(RewardsConstants.mysteryBoxesCollection)
          .doc(box.id)
          .get();

      expect(doc.exists, true);
      expect(doc.data()!['rarity'], box.rarity.name);
      expect(doc.data()!['coins_awarded'], box.coinsAwarded);
      expect(doc.data()!['is_opened'], false);
    });
  });

  group('RewardsRepository - Mystery Box Opening', () {
    test('openMysteryBox marks box as opened and awards coins', () async {
      // Setup: Create a box
      final box = await repository.generateMysteryBox();
      final initialCoins = box.coinsAwarded;

      // Test: Open the box
      final coinsEarned = await repository.openMysteryBox(box.id);

      expect(coinsEarned, initialCoins);

      // Verify box is marked as opened
      final doc = await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection(RewardsConstants.mysteryBoxesCollection)
          .doc(box.id)
          .get();

      expect(doc.data()!['is_opened'], true);
      expect(doc.data()!['opened_at'], isNotNull);

      // Verify coins were added to balance
      final stats = await repository.getUserStats();
      expect(stats.totalCoins, initialCoins);
      expect(stats.totalCoinsEarned, initialCoins);
    });

    test('openMysteryBox throws when box not found', () async {
      expect(
        () => repository.openMysteryBox('non_existent_box'),
        throwsA(isA<Exception>()),
      );
    });

    test('openMysteryBox throws when box already opened', () async {
      // Setup: Create and open a box
      final box = await repository.generateMysteryBox();
      await repository.openMysteryBox(box.id);

      // Test: Try to open again
      expect(
        () => repository.openMysteryBox(box.id),
        throwsA(isA<Exception>()),
      );
    });

    test('openMysteryBox updates user stats correctly', () async {
      // Setup: Create bronze box
      final bronzeBox = await repository.generateMysteryBox();
      
      // Manually set rarity to bronze for testing
      await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection(RewardsConstants.mysteryBoxesCollection)
          .doc(bronzeBox.id)
          .update({'rarity': BoxRarity.bronze.name});

      // Test: Open box
      await repository.openMysteryBox(bronzeBox.id);

      // Verify stats
      final stats = await repository.getUserStats();
      expect(stats.totalBoxesOpened, 1);
      expect(stats.bronzeBoxesOpened, 1);
      expect(stats.lastBoxOpenedAt, isNotNull);
    });

    test('openMysteryBox creates transaction record', () async {
      // Setup: Create box
      final box = await repository.generateMysteryBox();

      // Test: Open box
      await repository.openMysteryBox(box.id);

      // Verify transaction was created
      final transactions = await repository.getTransactionHistory();
      expect(transactions.length, 1);
      expect(transactions.first.type, TransactionType.earned);
      expect(transactions.first.amount, box.coinsAwarded);
      expect(transactions.first.relatedBoxId, box.id);
    });
  });

  group('RewardsRepository - Pending Boxes', () {
    test('getPendingBoxes returns only unopened boxes', () async {
      // Setup: Create boxes
      final box1 = await repository.generateMysteryBox();
      final box2 = await repository.generateMysteryBox();
      final box3 = await repository.generateMysteryBox();

      // Open one box
      await repository.openMysteryBox(box2.id);

      // Test: Get pending boxes
      final pending = await repository.getPendingBoxes();

      expect(pending.length, 2);
      expect(pending.any((b) => b.id == box1.id), true);
      expect(pending.any((b) => b.id == box3.id), true);
      expect(pending.any((b) => b.id == box2.id), false);
    });

    test('getPendingBoxes returns empty list when all boxes opened', () async {
      // Setup: Create and open boxes
      final box = await repository.generateMysteryBox();
      await repository.openMysteryBox(box.id);

      // Test
      final pending = await repository.getPendingBoxes();
      expect(pending.isEmpty, true);
    });

    test('getPendingBoxes returns boxes sorted by earned_at descending', () async {
      // Setup: Create boxes with delays
      final box1 = await repository.generateMysteryBox();
      await Future.delayed(const Duration(milliseconds: 100));
      final box2 = await repository.generateMysteryBox();
      await Future.delayed(const Duration(milliseconds: 100));
      final box3 = await repository.generateMysteryBox();

      // Test
      final pending = await repository.getPendingBoxes();

      expect(pending.length, 3);
      // Most recent first
      expect(pending[0].id, box3.id);
      expect(pending[1].id, box2.id);
      expect(pending[2].id, box1.id);
    });
  });

  group('RewardsRepository - Box History', () {
    test('getBoxHistory returns all boxes', () async {
      // Setup: Create boxes
      await repository.generateMysteryBox();
      await repository.generateMysteryBox();
      final box3 = await repository.generateMysteryBox();
      
      // Open one
      await repository.openMysteryBox(box3.id);

      // Test
      final history = await repository.getBoxHistory();

      expect(history.length, 3);
    });

    test('getBoxHistory respects limit', () async {
      // Setup: Create many boxes
      for (int i = 0; i < 10; i++) {
        await repository.generateMysteryBox();
      }

      // Test
      final history = await repository.getBoxHistory(limit: 5);

      expect(history.length, 5);
    });
  });

  group('RewardsRepository - Transaction History', () {
    test('getTransactionHistory returns transactions sorted by timestamp', () async {
      // Setup: Create and open multiple boxes
      final box1 = await repository.generateMysteryBox();
      await repository.openMysteryBox(box1.id);
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      final box2 = await repository.generateMysteryBox();
      await repository.openMysteryBox(box2.id);

      // Test
      final transactions = await repository.getTransactionHistory();

      expect(transactions.length, 2);
      // Most recent first
      expect(transactions[0].relatedBoxId, box2.id);
      expect(transactions[1].relatedBoxId, box1.id);
    });

    test('getTransactionHistory respects limit', () async {
      // Setup: Create many transactions
      for (int i = 0; i < 10; i++) {
        final box = await repository.generateMysteryBox();
        await repository.openMysteryBox(box.id);
      }

      // Test
      final transactions = await repository.getTransactionHistory(limit: 5);

      expect(transactions.length, 5);
    });
  });

  group('RewardsRepository - Streak System', () {
    test('checkAndUpdateStreak awards first time bonus', () async {
      // Test: First activity
      await repository.checkAndUpdateStreak();

      // Verify
      final stats = await repository.getUserStats();
      expect(stats.currentStreak, 1);
      expect(stats.longestStreak, 1);
      expect(stats.totalCoins, RewardsConstants.firstTimeBonus);
      expect(stats.lastActivityDate, isNotNull);
    });

    test('checkAndUpdateStreak does not update on same day', () async {
      // Setup: First activity
      await repository.checkAndUpdateStreak();
      final initialStats = await repository.getUserStats();

      // Test: Second activity same day
      await repository.checkAndUpdateStreak();
      final newStats = await repository.getUserStats();

      expect(newStats.currentStreak, initialStats.currentStreak);
    });

    test('checkAndUpdateStreak increments on consecutive day', () async {
      // Setup: First activity
      await repository.checkAndUpdateStreak();

      // Simulate next day by manually updating lastActivityDate
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection(RewardsConstants.rewardsStatsCollection)
          .doc('summary')
          .update({'last_activity_date': Timestamp.fromDate(yesterday)});

      // Test: Activity on next day
      await repository.checkAndUpdateStreak();

      final stats = await repository.getUserStats();
      expect(stats.currentStreak, 2);
      expect(stats.longestStreak, 2);
    });

    test('checkAndUpdateStreak resets streak when broken', () async {
      // Setup: Build a streak
      await repository.checkAndUpdateStreak();
      
      // Simulate 2 days ago
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection(RewardsConstants.rewardsStatsCollection)
          .doc('summary')
          .update({'last_activity_date': Timestamp.fromDate(twoDaysAgo)});

      // Test: Activity after streak break
      await repository.checkAndUpdateStreak();

      final stats = await repository.getUserStats();
      expect(stats.currentStreak, 1);
    });

    test('checkAndUpdateStreak preserves longest streak', () async {
      // Setup: Build a streak of 5
      await repository.checkAndUpdateStreak();
      for (int i = 0; i < 4; i++) {
        final date = DateTime.now().subtract(Duration(days: 4 - i));
        await fakeFirestore
            .collection('users')
            .doc(testUserId)
            .collection(RewardsConstants.rewardsStatsCollection)
            .doc('summary')
            .update({
          'current_streak': i + 1,
          'longest_streak': i + 1,
          'last_activity_date': Timestamp.fromDate(date),
        });
      }

      // Break streak
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection(RewardsConstants.rewardsStatsCollection)
          .doc('summary')
          .update({'last_activity_date': Timestamp.fromDate(threeDaysAgo)});

      await repository.checkAndUpdateStreak();

      final stats = await repository.getUserStats();
      expect(stats.currentStreak, 1);
      expect(stats.longestStreak, 5); // Preserved
    });
  });

  group('RewardsRepository - Daily Bonus', () {
    test('awardDailyBonus adds bonus coins', () async {
      // Test
      await repository.awardDailyBonus();

      // Verify
      final stats = await repository.getUserStats();
      expect(stats.totalCoins, RewardsConstants.dailyLoginBonus);
      expect(stats.totalCoinsEarned, RewardsConstants.dailyLoginBonus);

      final transactions = await repository.getTransactionHistory();
      expect(transactions.length, 1);
      expect(transactions.first.type, TransactionType.bonus);
      expect(transactions.first.amount, RewardsConstants.dailyLoginBonus);
    });
  });

  group('RewardsRepository - Anti-Fraud', () {
    test('canClaimBox returns true when no boxes claimed today', () async {
      final canClaim = await repository.canClaimBox();
      expect(canClaim, true);
    });

    test('canClaimBox returns false when max boxes per day reached', () async {
      // Setup: Claim max boxes
      for (int i = 0; i < RewardsConstants.maxBoxesPerDay; i++) {
        await repository.generateMysteryBox();
      }

      // Test
      final canClaim = await repository.canClaimBox();
      expect(canClaim, false);
    });

    test('canClaimBox returns false during cooldown period', () async {
      // Setup: Claim one box
      await repository.generateMysteryBox();

      // Test immediately (within cooldown)
      final canClaim = await repository.canClaimBox();
      expect(canClaim, false);
    });

    test('canClaimBox returns true after cooldown period', () async {
      // Setup: Claim box with old timestamp
      final box = await repository.generateMysteryBox();
      
      // Manually set earned_at to past cooldown
      final pastCooldown = DateTime.now().subtract(
        Duration(hours: RewardsConstants.boxCooldownHours + 1),
      );
      
      await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection(RewardsConstants.mysteryBoxesCollection)
          .doc(box.id)
          .update({'earned_at': Timestamp.fromDate(pastCooldown)});

      // Test
      final canClaim = await repository.canClaimBox();
      expect(canClaim, true);
    });
  });

  group('RewardsRepository - Coin Management', () {
    test('opening box increases total coins', () async {
      // Setup
      final box = await repository.generateMysteryBox();
      final coinsAwarded = box.coinsAwarded;

      // Test
      await repository.openMysteryBox(box.id);

      // Verify
      final stats = await repository.getUserStats();
      expect(stats.totalCoins, coinsAwarded);
      expect(stats.totalCoinsEarned, coinsAwarded);
      expect(stats.totalCoinsSpent, 0);
    });

    test('opening multiple boxes accumulates coins', () async {
      // Setup
      final box1 = await repository.generateMysteryBox();
      final box2 = await repository.generateMysteryBox();

      // Test
      await repository.openMysteryBox(box1.id);
      await repository.openMysteryBox(box2.id);

      // Verify
      final stats = await repository.getUserStats();
      final expectedTotal = box1.coinsAwarded + box2.coinsAwarded;
      expect(stats.totalCoins, expectedTotal);
      expect(stats.totalCoinsEarned, expectedTotal);
    });
  });

  group('RewardsRepository - Edge Cases', () {
    test('handles concurrent box generation gracefully', () async {
      // Test: Generate multiple boxes concurrently
      final futures = List.generate(
        5,
        (_) => repository.generateMysteryBox(),
      );

      final boxes = await Future.wait(futures);

      expect(boxes.length, 5);
      // All boxes have unique IDs
      final ids = boxes.map((b) => b.id).toSet();
      expect(ids.length, 5);
    });

    test('handles empty transaction history', () async {
      final transactions = await repository.getTransactionHistory();
      expect(transactions, isEmpty);
    });

    test('handles empty box history', () async {
      final history = await repository.getBoxHistory();
      expect(history, isEmpty);
    });

    test('getUserStats creates document if not exists', () async {
      final stats = await repository.getUserStats();
      
      // Verify document was created in Firestore
      final doc = await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection(RewardsConstants.rewardsStatsCollection)
          .doc('summary')
          .get();

      expect(doc.exists, true);
      expect(stats.totalCoins, 0);
    });
  });

  group('RewardsRepository - Rarity Distribution', () {
    test('rarity distribution roughly matches probability', () async {
      // Generate many boxes to test probability distribution
      final boxes = <RewardBox>[];
      for (int i = 0; i < 100; i++) {
        boxes.add(await repository.generateMysteryBox());
      }

      // Count each rarity
      final bronzeCount = boxes.where((b) => b.rarity == BoxRarity.bronze).length;
      final silverCount = boxes.where((b) => b.rarity == BoxRarity.silver).length;
      final goldCount = boxes.where((b) => b.rarity == BoxRarity.gold).length;
      final diamondCount = boxes.where((b) => b.rarity == BoxRarity.diamond).length;

      // Bronze should be ~70% (55-85% acceptable due to variance)
      expect(bronzeCount, greaterThan(55));
      expect(bronzeCount, lessThan(85));

      // Silver should be ~20% (10-35% acceptable due to variance)
      expect(silverCount, greaterThan(5));
      expect(silverCount, lessThan(40));

      // Gold should be ~8% (0-20% acceptable due to variance)
      expect(goldCount, greaterThanOrEqualTo(0));
      expect(goldCount, lessThan(20));

      // Diamond should be ~2% (0-10% acceptable due to variance)
      expect(diamondCount, greaterThanOrEqualTo(0));
      expect(diamondCount, lessThan(10));

      // Total should equal 100
      expect(bronzeCount + silverCount + goldCount + diamondCount, 100);
      
      // Print actual distribution for debugging
      print('Distribution: Bronze=$bronzeCount, Silver=$silverCount, Gold=$goldCount, Diamond=$diamondCount');
    });
  });
}
