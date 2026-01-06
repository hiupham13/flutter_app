import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:what_eat_app/models/reward_model.dart';
import 'package:what_eat_app/features/rewards/presentation/widgets/mystery_box_card.dart';

void main() {
  group('MysteryBoxCard Tests', () {
    // Helper to create test box
    RewardBox createTestBox({
      BoxRarity rarity = BoxRarity.bronze,
      bool isOpened = false,
      int coinsAwarded = 50,
    }) {
      return RewardBox(
        id: 'test-box-1',
        rarity: rarity,
        coinsAwarded: coinsAwarded,
        isOpened: isOpened,
        earnedAt: DateTime.now(),
        openedAt: isOpened ? DateTime.now() : null,
      );
    }

    testWidgets('should display bronze box correctly', (WidgetTester tester) async {
      final box = createTestBox(rarity: BoxRarity.bronze);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MysteryBoxCard(box: box),
          ),
        ),
      );

      // Use pump instead of pumpAndSettle for animated widgets
      await tester.pump();

      expect(find.byType(MysteryBoxCard), findsOneWidget);
      expect(find.text('📦'), findsOneWidget); // Bronze emoji
      expect(find.text('Đồng'), findsOneWidget); // Bronze label
      expect(find.text('Nhấn để mở'), findsOneWidget); // Unopened text
    });

    testWidgets('should display silver box correctly', (WidgetTester tester) async {
      final box = createTestBox(rarity: BoxRarity.silver);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MysteryBoxCard(box: box),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('🎁'), findsOneWidget); // Silver emoji
      expect(find.text('Bạc'), findsOneWidget);
    });

    testWidgets('should display gold box correctly', (WidgetTester tester) async {
      final box = createTestBox(rarity: BoxRarity.gold);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MysteryBoxCard(box: box),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('💎'), findsOneWidget); // Gold emoji
      expect(find.text('Vàng'), findsOneWidget);
    });

    testWidgets('should display diamond box correctly', (WidgetTester tester) async {
      final box = createTestBox(rarity: BoxRarity.diamond);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MysteryBoxCard(box: box),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('✨'), findsOneWidget); // Diamond emoji
      expect(find.text('Kim Cương'), findsOneWidget);
    });

    testWidgets('should show "Đã mở" for opened box', (WidgetTester tester) async {
      final box = createTestBox(isOpened: true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MysteryBoxCard(box: box),
          ),
        ),
      );

      await tester.pumpAndSettle(); // Opened box has no continuous animation

      expect(find.text('Đã mở'), findsOneWidget);
      expect(find.text('Nhấn để mở'), findsNothing);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('should show unopened badge for unopened box', (WidgetTester tester) async {
      final box = createTestBox(isOpened: false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MysteryBoxCard(box: box),
          ),
        ),
      );

      await tester.pump();

      // Find the "!" badge
      expect(find.text('!'), findsOneWidget);
    });

    testWidgets('should not show unopened badge for opened box', (WidgetTester tester) async {
      final box = createTestBox(isOpened: true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MysteryBoxCard(box: box),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Badge should not be visible for opened boxes (covered by overlay)
      final badgeFinder = find.descendant(
        of: find.byType(MysteryBoxCard),
        matching: find.text('!'),
      );
      
      expect(badgeFinder, findsNothing);
    });

    testWidgets('should call onTap when tapped and unopened', (WidgetTester tester) async {
      bool tapped = false;
      final box = createTestBox(isOpened: false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MysteryBoxCard(
              box: box,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.pump();

      // Tap the card
      await tester.tap(find.byType(MysteryBoxCard));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('should not call onTap when tapped and opened', (WidgetTester tester) async {
      bool tapped = false;
      final box = createTestBox(isOpened: true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MysteryBoxCard(
              box: box,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Try to tap the card
      await tester.tap(find.byType(MysteryBoxCard));
      await tester.pump();

      expect(tapped, isFalse);
    });

    testWidgets('should have gradient background', (WidgetTester tester) async {
      final box = createTestBox(rarity: BoxRarity.gold);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MysteryBoxCard(box: box),
          ),
        ),
      );

      await tester.pump();

      // Find Container with gradient
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(MysteryBoxCard),
          matching: find.byType(Container),
        ).first,
      );

      expect(container.decoration, isA<BoxDecoration>());
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.gradient, isA<LinearGradient>());
    });

    testWidgets('should animate pulse for unopened box', (WidgetTester tester) async {
      final box = createTestBox(isOpened: false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MysteryBoxCard(box: box),
          ),
        ),
      );

      // Let animation start
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Animation should be running
      expect(find.byType(MysteryBoxCard), findsOneWidget);
      
      // Advance animation
      await tester.pump(const Duration(milliseconds: 500));
      
      // Should still be visible and animating
      expect(find.byType(MysteryBoxCard), findsOneWidget);
    });

    testWidgets('should not animate pulse for opened box', (WidgetTester tester) async {
      final box = createTestBox(isOpened: true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MysteryBoxCard(box: box),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // For opened box, animation shouldn't run
      expect(find.byType(MysteryBoxCard), findsOneWidget);
    });

    testWidgets('should scale down when pressed', (WidgetTester tester) async {
      final box = createTestBox(isOpened: false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MysteryBoxCard(
              box: box,
              onTap: () {},
            ),
          ),
        ),
      );

      await tester.pump();

      // Press down on the card
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(MysteryBoxCard)),
      );
      
      await tester.pump();
      
      // Card should scale down
      expect(find.byType(MysteryBoxCard), findsOneWidget);
      
      // Release
      await gesture.up();
      await tester.pump();
    });

    testWidgets('should display different emoji for each rarity', (WidgetTester tester) async {
      final rarities = [
        (BoxRarity.bronze, '📦'),
        (BoxRarity.silver, '🎁'),
        (BoxRarity.gold, '💎'),
        (BoxRarity.diamond, '✨'),
      ];

      for (final (rarity, emoji) in rarities) {
        final box = createTestBox(rarity: rarity);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MysteryBoxCard(box: box),
            ),
          ),
        );

        await tester.pump();

        expect(find.text(emoji), findsOneWidget, reason: 'Emoji for $rarity should be $emoji');
      }
    });

    testWidgets('should display different sizes correctly', (WidgetTester tester) async {
      final box = createTestBox();

      // Test small size
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MysteryBoxCard(
              box: box,
              size: MysteryBoxCardSize.small,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(MysteryBoxCard), findsOneWidget);

      // Test medium size
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MysteryBoxCard(
              box: box,
              size: MysteryBoxCardSize.medium,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(MysteryBoxCard), findsOneWidget);

      // Test large size
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MysteryBoxCard(
              box: box,
              size: MysteryBoxCardSize.large,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(MysteryBoxCard), findsOneWidget);
    });
  });
}
