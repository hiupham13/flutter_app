import 'package:flutter_test/flutter_test.dart';
import 'package:what_eat_app/features/recommendation/logic/location_scorer.dart';
import 'package:what_eat_app/models/food_model.dart';

void main() {
  group('LocationScorer', () {
    late LocationScorer scorer;

    setUp(() {
      scorer = LocationScorer();
    });

    FoodModel createFood({
      required String id,
      List<String> searchKeywords = const [],
      String mapQuery = '',
    }) {
      return FoodModel.create(
        id: id,
        name: 'Food $id',
        searchKeywords: searchKeywords,
        description: 'Description',
        images: ['image.jpg'],
        cuisineId: 'vn',
        mealTypeId: 'soup',
        flavorProfile: [],
        allergenTags: [],
        priceSegment: 2,
        availableTimes: ['morning'],
        contextScores: {},
        mapQuery: mapQuery,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        viewCount: 0,
        pickCount: 0,
      );
    }

    group('getLocationMultiplier', () {
      test('should return 1.2 for food with location keywords', () async {
        // Arrange
        final food = createFood(
          id: '1',
          searchKeywords: ['phở', 'gần đây'],
        );

        // Act
        final multiplier = await scorer.getLocationMultiplier(food);

        // Assert
        expect(multiplier, equals(1.2));
      });

      test('should return 1.15 for food with nearby map query', () async {
        // Arrange
        final food = createFood(
          id: '1',
          mapQuery: 'phở quanh đây',
        );

        // Act
        final multiplier = await scorer.getLocationMultiplier(food);

        // Assert
        expect(multiplier, equals(1.15));
      });

      test('should return 1.0 for food without location indicators', () async {
        // Arrange
        final food = createFood(
          id: '1',
          searchKeywords: ['phở'],
          mapQuery: 'phở',
        );

        // Act
        final multiplier = await scorer.getLocationMultiplier(food);

        // Assert
        expect(multiplier, equals(1.0));
      });

      test('should handle multiple location keywords', () async {
        // Arrange
        final food = createFood(
          id: '1',
          searchKeywords: ['phở', 'quanh', 'đây'],
        );

        // Act
        final multiplier = await scorer.getLocationMultiplier(food);

        // Assert
        expect(multiplier, equals(1.2));
      });
    });

    group('getLocationMultipliers', () {
      test('should return multipliers for all foods', () async {
        // Arrange
        final foods = [
          createFood(id: '1', searchKeywords: ['gần']),
          createFood(id: '2', searchKeywords: ['phở']),
        ];

        // Act
        final multipliers = await scorer.getLocationMultipliers(foods);

        // Assert
        expect(multipliers.length, equals(2));
        expect(multipliers['1'], equals(1.2));
        expect(multipliers['2'], equals(1.0));
      });

      test('should return neutral multipliers on error', () async {
        // Arrange
        final foods = [createFood(id: '1')];

        // Act
        final multipliers = await scorer.getLocationMultipliers(foods);

        // Assert
        expect(multipliers['1'], equals(1.0));
      });
    });
  });
}

