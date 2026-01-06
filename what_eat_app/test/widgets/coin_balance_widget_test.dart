import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:what_eat_app/core/widgets/coin_balance_widget.dart';
import 'package:what_eat_app/features/rewards/logic/rewards_provider.dart';

void main() {
  group('CoinBalanceWidget Tests', () {
    testWidgets('should display initial coin balance', (WidgetTester tester) async {
      // Arrange
      const testBalance = 1000;
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            coinBalanceProvider.overrideWith((ref) => testBalance),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CoinBalanceWidget(),
            ),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(CoinBalanceWidget), findsOneWidget);
      expect(find.byIcon(Icons.monetization_on), findsOneWidget);
      expect(find.text('1.0K'), findsOneWidget); // Formatted number
    });

    testWidgets('should display compact size correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            coinBalanceProvider.overrideWith((ref) => 500),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CoinBalanceWidget(
                size: CoinBalanceSize.compact,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the widget
      final widget = tester.widget<CoinBalanceWidget>(
        find.byType(CoinBalanceWidget),
      );
      
      expect(widget.size, CoinBalanceSize.compact);
      expect(find.text('500'), findsOneWidget);
    });

    testWidgets('should display medium size correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            coinBalanceProvider.overrideWith((ref) => 250),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CoinBalanceWidget(
                size: CoinBalanceSize.medium,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final widget = tester.widget<CoinBalanceWidget>(
        find.byType(CoinBalanceWidget),
      );
      
      expect(widget.size, CoinBalanceSize.medium);
    });

    testWidgets('should display large size correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            coinBalanceProvider.overrideWith((ref) => 750),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CoinBalanceWidget(
                size: CoinBalanceSize.large,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final widget = tester.widget<CoinBalanceWidget>(
        find.byType(CoinBalanceWidget),
      );
      
      expect(widget.size, CoinBalanceSize.large);
    });

    testWidgets('should show label when showLabel is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            coinBalanceProvider.overrideWith((ref) => 100),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CoinBalanceWidget(
                showLabel: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Coins'), findsOneWidget);
    });

    testWidgets('should not show label when showLabel is false', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            coinBalanceProvider.overrideWith((ref) => 100),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CoinBalanceWidget(
                showLabel: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Coins'), findsNothing);
    });

    testWidgets('should call onTap callback when tapped', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            coinBalanceProvider.overrideWith((ref) => 100),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CoinBalanceWidget(
                onTap: () {
                  tapped = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the widget
      await tester.tap(find.byType(CoinBalanceWidget));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('should have gradient background', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            coinBalanceProvider.overrideWith((ref) => 100),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CoinBalanceWidget(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find Container with gradient
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(CoinBalanceWidget),
          matching: find.byType(Container),
        ).first,
      );

      expect(container.decoration, isA<BoxDecoration>());
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.gradient, isA<LinearGradient>());
    });
  });

  group('AnimatedFlipCounter Tests', () {
    testWidgets('should display initial value', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedFlipCounter(
              value: 42,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('should animate when value changes', (WidgetTester tester) async {
      int testValue = 100;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    AnimatedFlipCounter(value: testValue),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => testValue = 200);
                      },
                      child: const Text('Increase'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('100'), findsOneWidget);

      // Tap button to change value
      await tester.tap(find.text('Increase'));
      await tester.pump(); // Start animation
      await tester.pump(const Duration(milliseconds: 250)); // Mid animation
      await tester.pumpAndSettle(); // Complete animation

      expect(find.text('200'), findsOneWidget);
    });

    testWidgets('should format large numbers correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedFlipCounter(
              value: 1500,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('1.5K'), findsOneWidget);
    });

    testWidgets('should format million numbers correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedFlipCounter(
              value: 2500000,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('2.5M'), findsOneWidget);
    });

    testWidgets('should apply custom text style', (WidgetTester tester) async {
      const testStyle = TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.red,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedFlipCounter(
              value: 100,
              textStyle: testStyle,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final text = tester.widget<Text>(
        find.descendant(
          of: find.byType(AnimatedFlipCounter),
          matching: find.byType(Text),
        ),
      );

      expect(text.style?.fontSize, testStyle.fontSize);
      expect(text.style?.fontWeight, testStyle.fontWeight);
      expect(text.style?.color, testStyle.color);
    });
  });

  group('CoinFormatExtension Tests', () {
    test('should format small numbers correctly', () {
      expect(99.toFormattedCoinString(), '99');
      expect(500.toFormattedCoinString(), '500');
    });

    test('should format thousands correctly', () {
      expect(1000.toFormattedCoinString(), '1.0K');
      expect(1500.toFormattedCoinString(), '1.5K');
      expect(15000.toFormattedCoinString(), '15.0K');
    });

    test('should format millions correctly', () {
      expect(1000000.toFormattedCoinString(), '1.0M');
      expect(2500000.toFormattedCoinString(), '2.5M');
      expect(15000000.toFormattedCoinString(), '15.0M');
    });
  });
}
