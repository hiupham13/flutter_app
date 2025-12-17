import 'package:flutter_test/flutter_test.dart';
import 'package:what_eat_app/features/recommendation/logic/popularity_scorer.dart';
import 'package:what_eat_app/models/food_model.dart';

void main() {
  group('PopularityScorer', () {
    late PopularityScorer scorer;

    setUp(() {
      scorer = PopularityScorer();
    });

    FoodModel createFood({
      required String id,
      required int viewCount,
      required int pickCount,
    }) {
      return FoodModel.create(
        id: id,
        name: 'Food $id',
        searchKeywords: ['food'],
        description: 'Description',
        images: ['image.jpg'],
        cuisineId: 'vn',
        mealTypeId: 'soup',
        flavorProfile: [],
        allergenTags: [],
        priceSegment: 2,
        availableTimes: ['morning'],
        contextScores: {},
        mapQuery: 'food',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        viewCount: viewCount,
        pickCount: pickCount,
      );
    }

    group('getPopularityMultiplier', () {
      test('should return 1.0 for new food with no views', () {
        // Arrange
        final food = createFood(id: '1', viewCount: 0, pickCount: 0);

        // Act
        final multiplier = scorer.getPopularityMultiplier(food);

        // Assert
        expect(multiplier, equals(1.0));
      });

      test('should return 1.3 for very popular food (pick rate >20%)', () {
        // Arrange
        final food = createFood(id: '1', viewCount: 100, pickCount: 25); // 25% pick rate

        // Act
        final multiplier = scorer.getPopularityMultiplier(food);

        // Assert
        expect(multiplier, equals(1.3));
      });

      test('should return 1.15 for popular food (pick rate >10%)', () {
        // Arrange
        final food = createFood(id: '1', viewCount: 100, pickCount: 15); // 15% pick rate

        // Act
        final multiplier = scorer.getPopularityMultiplier(food);

        // Assert
        expect(multiplier, equals(1.15));
      });

      test('should return 1.05 for somewhat popular food (pick rate >5%)', () {
        // Arrange
        final food = createFood(id: '1', viewCount: 100, pickCount: 8); // 8% pick rate

        // Act
        final multiplier = scorer.getPopularityMultiplier(food);

        // Assert
        expect(multiplier, equals(1.05));
      });

      test('should return 0.95 for low engagement food', () {
        // Arrange
        final food = createFood(id: '1', viewCount: 100, pickCount: 0); // 0% pick rate

        // Act
        final multiplier = scorer.getPopularityMultiplier(food);

        // Assert
        expect(multiplier, equals(0.95));
      });
    });

    group('getTrendingMultiplier', () {
      test('should return 1.2 for trending food (pick rate >15%)', () {
        // Arrange
        final food = createFood(id: '1', viewCount: 100, pickCount: 20); // 20% pick rate

        // Act
        final multiplier = scorer.getTrendingMultiplier(food);

        // Assert
        expect(multiplier, equals(1.2));
      });

      test('should return 1.1 for somewhat trending food (pick rate >8%)', () {
        // Arrange
        final food = createFood(id: '1', viewCount: 100, pickCount: 10); // 10% pick rate

        // Act
        final multiplier = scorer.getTrendingMultiplier(food);

        // Assert
        expect(multiplier, equals(1.1));
      });

      test('should return 1.0 for non-trending food', () {
        // Arrange
        final food = createFood(id: '1', viewCount: 100, pickCount: 5); // 5% pick rate

        // Act
        final multiplier = scorer.getTrendingMultiplier(food);

        // Assert
        expect(multiplier, equals(1.0));
      });
    });

    group('getCombinedMultiplier', () {
      test('should combine popularity and trending', () {
        // Arrange
        final food = createFood(id: '1', viewCount: 100, pickCount: 20);

        // Act
        final multiplier = scorer.getCombinedMultiplier(food);

        // Assert
        expect(multiplier, greaterThan(1.0));
        expect(multiplier, lessThanOrEqualTo(1.3));
      });
    });

    group('getPopularityScore', () {
      test('should return 1.0 for 20% pick rate', () {
        // Arrange
        final food = createFood(id: '1', viewCount: 100, pickCount: 20);

        // Act
        final score = scorer.getPopularityScore(food);

        // Assert
        expect(score, equals(1.0));
      });

      test('should return 0.5 for 10% pick rate', () {
        // Arrange
        final food = createFood(id: '1', viewCount: 100, pickCount: 10);

        // Act
        final score = scorer.getPopularityScore(food);

        // Assert
        expect(score, equals(0.5));
      });

      test('should return 0.5 for new food', () {
        // Arrange
        final food = createFood(id: '1', viewCount: 0, pickCount: 0);

        // Act
        final score = scorer.getPopularityScore(food);

        // Assert
        expect(score, equals(0.5));
      });

      test('should clamp to 1.0 for very high pick rate', () {
        // Arrange
        final food = createFood(id: '1', viewCount: 100, pickCount: 50); // 50% pick rate

        // Act
        final score = scorer.getPopularityScore(food);

        // Assert
        expect(score, lessThanOrEqualTo(1.0));
      });
    });
  });
}

