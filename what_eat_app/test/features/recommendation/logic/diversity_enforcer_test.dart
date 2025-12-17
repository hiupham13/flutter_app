import 'package:flutter_test/flutter_test.dart';
import 'package:what_eat_app/features/recommendation/logic/diversity_enforcer.dart';
import 'package:what_eat_app/models/food_model.dart';

void main() {
  group('DiversityEnforcer', () {
    late DiversityEnforcer enforcer;

    setUp(() {
      enforcer = DiversityEnforcer();
    });

    FoodModel createFood({
      required String id,
      required String cuisineId,
      required String mealTypeId,
    }) {
      return FoodModel.create(
        id: id,
        name: 'Food $id',
        searchKeywords: ['food'],
        description: 'Description',
        images: ['image.jpg'],
        cuisineId: cuisineId,
        mealTypeId: mealTypeId,
        flavorProfile: [],
        allergenTags: [],
        priceSegment: 2,
        availableTimes: ['morning'],
        contextScores: {},
        mapQuery: 'food',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        viewCount: 0,
        pickCount: 0,
      );
    }

    group('enforceDiversity', () {
      test('should ensure different cuisines and meal types', () {
        // Arrange
        final foods = [
          createFood(id: '1', cuisineId: 'vn', mealTypeId: 'soup'),
          createFood(id: '2', cuisineId: 'vn', mealTypeId: 'soup'), // Duplicate
          createFood(id: '3', cuisineId: 'kr', mealTypeId: 'dry'),
          createFood(id: '4', cuisineId: 'jp', mealTypeId: 'snack'),
        ];

        // Act
        final result = enforcer.enforceDiversity(foods, 3);

        // Assert
        expect(result.length, equals(3));
        final cuisines = result.map((f) => f.cuisineId).toSet();
        final mealTypes = result.map((f) => f.mealTypeId).toSet();
        expect(cuisines.length, greaterThan(1));
        expect(mealTypes.length, greaterThan(1));
      });

      test('should return empty list for empty input', () {
        // Act
        final result = enforcer.enforceDiversity([], 5);

        // Assert
        expect(result, isEmpty);
      });

      test('should respect diversity threshold', () {
        // Arrange
        final foods = List.generate(10, (i) => createFood(
          id: '$i',
          cuisineId: 'vn',
          mealTypeId: 'soup',
        ));

        // Act
        final result = enforcer.enforceDiversity(foods, 5, diversityThreshold: 0.7);

        // Assert
        expect(result.length, equals(5));
        // At least 70% should be diverse (3-4 different items)
      });
    });

    group('balanceCategories', () {
      test('should ensure at least one from each category', () {
        // Arrange
        final foods = [
          createFood(id: '1', cuisineId: 'vn', mealTypeId: 'soup'),
          createFood(id: '2', cuisineId: 'vn', mealTypeId: 'soup'),
          createFood(id: '3', cuisineId: 'vn', mealTypeId: 'dry'),
          createFood(id: '4', cuisineId: 'vn', mealTypeId: 'snack'),
          createFood(id: '5', cuisineId: 'vn', mealTypeId: 'hotpot'),
        ];

        // Act
        final result = enforcer.balanceCategories(foods, 4);

        // Assert
        expect(result.length, equals(4));
        final mealTypes = result.map((f) => f.mealTypeId).toSet();
        expect(mealTypes.length, greaterThanOrEqualTo(2));
      });

      test('should distribute evenly across categories', () {
        // Arrange
        final foods = [
          createFood(id: '1', cuisineId: 'vn', mealTypeId: 'soup'),
          createFood(id: '2', cuisineId: 'vn', mealTypeId: 'soup'),
          createFood(id: '3', cuisineId: 'vn', mealTypeId: 'dry'),
          createFood(id: '4', cuisineId: 'vn', mealTypeId: 'dry'),
          createFood(id: '5', cuisineId: 'vn', mealTypeId: 'snack'),
          createFood(id: '6', cuisineId: 'vn', mealTypeId: 'snack'),
        ];

        // Act
        final result = enforcer.balanceCategories(foods, 6);

        // Assert
        expect(result.length, equals(6));
        // Should have representation from multiple categories
      });
    });

    group('ensureMinimumVariety', () {
      test('should ensure minimum cuisines', () {
        // Arrange
        final foods = [
          createFood(id: '1', cuisineId: 'vn', mealTypeId: 'soup'),
          createFood(id: '2', cuisineId: 'vn', mealTypeId: 'soup'),
          createFood(id: '3', cuisineId: 'kr', mealTypeId: 'soup'),
          createFood(id: '4', cuisineId: 'vn', mealTypeId: 'soup'),
        ];

        // Act
        final result = enforcer.ensureMinimumVariety(
          foods,
          3,
          minCuisines: 2,
          minMealTypes: 1,
        );

        // Assert
        expect(result.length, equals(3));
        final cuisines = result.map((f) => f.cuisineId).toSet();
        expect(cuisines.length, greaterThanOrEqualTo(2));
      });

      test('should ensure minimum meal types', () {
        // Arrange
        final foods = [
          createFood(id: '1', cuisineId: 'vn', mealTypeId: 'soup'),
          createFood(id: '2', cuisineId: 'vn', mealTypeId: 'soup'),
          createFood(id: '3', cuisineId: 'vn', mealTypeId: 'dry'),
          createFood(id: '4', cuisineId: 'vn', mealTypeId: 'soup'),
        ];

        // Act
        final result = enforcer.ensureMinimumVariety(
          foods,
          3,
          minCuisines: 1,
          minMealTypes: 2,
        );

        // Assert
        expect(result.length, equals(3));
        final mealTypes = result.map((f) => f.mealTypeId).toSet();
        expect(mealTypes.length, greaterThanOrEqualTo(2));
      });
    });

    group('enforceDiversityWithBalancing', () {
      test('should combine all diversity methods', () {
        // Arrange
        final foods = [
          createFood(id: '1', cuisineId: 'vn', mealTypeId: 'soup'),
          createFood(id: '2', cuisineId: 'vn', mealTypeId: 'dry'),
          createFood(id: '3', cuisineId: 'kr', mealTypeId: 'snack'),
          createFood(id: '4', cuisineId: 'jp', mealTypeId: 'hotpot'),
        ];

        // Act
        final result = enforcer.enforceDiversityWithBalancing(
          foods,
          4,
          minCuisines: 2,
          minMealTypes: 2,
          balanceCategories: true,
        );

        // Assert
        expect(result.length, equals(4));
        final cuisines = result.map((f) => f.cuisineId).toSet();
        final mealTypes = result.map((f) => f.mealTypeId).toSet();
        expect(cuisines.length, greaterThanOrEqualTo(2));
        expect(mealTypes.length, greaterThanOrEqualTo(2));
      });
    });

    group('calculateDiversityScore', () {
      test('should return 1.0 for perfectly diverse list', () {
        // Arrange
        final foods = [
          createFood(id: '1', cuisineId: 'vn', mealTypeId: 'soup'),
          createFood(id: '2', cuisineId: 'kr', mealTypeId: 'dry'),
          createFood(id: '3', cuisineId: 'jp', mealTypeId: 'snack'),
        ];

        // Act
        final score = enforcer.calculateDiversityScore(foods);

        // Assert
        expect(score, equals(1.0));
      });

      test('should return lower score for less diverse list', () {
        // Arrange
        final foods = [
          createFood(id: '1', cuisineId: 'vn', mealTypeId: 'soup'),
          createFood(id: '2', cuisineId: 'vn', mealTypeId: 'soup'),
          createFood(id: '3', cuisineId: 'vn', mealTypeId: 'soup'),
        ];

        // Act
        final score = enforcer.calculateDiversityScore(foods);

        // Assert
        expect(score, lessThan(1.0));
        expect(score, greaterThanOrEqualTo(0.0));
      });

      test('should return 0.0 for empty list', () {
        // Act
        final score = enforcer.calculateDiversityScore([]);

        // Assert
        expect(score, equals(0.0));
      });
    });
  });
}

