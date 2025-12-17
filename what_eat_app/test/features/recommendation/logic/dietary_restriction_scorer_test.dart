import 'package:flutter_test/flutter_test.dart';
import 'package:what_eat_app/features/recommendation/logic/dietary_restriction_scorer.dart';
import 'package:what_eat_app/models/food_model.dart';

void main() {
  group('DietaryRestrictionScorer', () {
    late DietaryRestrictionScorer scorer;

    setUp(() {
      scorer = DietaryRestrictionScorer();
    });

    FoodModel createFood({
      required String id,
      List<String> flavorProfile = const [],
      Map<String, double> contextScores = const {},
      List<String> allergenTags = const [],
    }) {
      return FoodModel.create(
        id: id,
        name: 'Food $id',
        searchKeywords: ['food'],
        description: 'Description',
        images: ['image.jpg'],
        cuisineId: 'vn',
        mealTypeId: 'soup',
        flavorProfile: flavorProfile,
        allergenTags: allergenTags,
        priceSegment: 2,
        availableTimes: ['morning'],
        contextScores: contextScores,
        mapQuery: 'food',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        viewCount: 0,
        pickCount: 0,
      );
    }

    group('getDietaryMultiplier', () {
      test('should return 1.0 when no restrictions', () {
        // Arrange
        final food = createFood(id: '1');
        final restrictions = <DietaryRestriction>[];

        // Act
        final multiplier = scorer.getDietaryMultiplier(food, restrictions);

        // Assert
        expect(multiplier, equals(1.0));
      });

      test('should return 0.1 for non-keto food when keto required', () {
        // Arrange
        final food = createFood(id: '1');
        final restrictions = [DietaryRestriction.keto];

        // Act
        final multiplier = scorer.getDietaryMultiplier(food, restrictions);

        // Assert
        expect(multiplier, equals(0.1));
      });

      test('should return 1.0 for keto food when keto required', () {
        // Arrange
        final food = createFood(
          id: '1',
          flavorProfile: ['keto'],
        );
        final restrictions = [DietaryRestriction.keto];

        // Act
        final multiplier = scorer.getDietaryMultiplier(food, restrictions);

        // Assert
        expect(multiplier, equals(1.0));
      });

      test('should return 0.1 for non-vegan food when vegan required', () {
        // Arrange
        final food = createFood(id: '1');
        final restrictions = [DietaryRestriction.vegan];

        // Act
        final multiplier = scorer.getDietaryMultiplier(food, restrictions);

        // Assert
        expect(multiplier, equals(0.1));
      });

      test('should return 0.1 for non-halal food when halal required', () {
        // Arrange
        final food = createFood(id: '1');
        final restrictions = [DietaryRestriction.halal];

        // Act
        final multiplier = scorer.getDietaryMultiplier(food, restrictions);

        // Assert
        expect(multiplier, equals(0.1));
      });

      test('should return 0.1 for gluten-containing food when gluten-free required', () {
        // Arrange
        final food = createFood(
          id: '1',
          allergenTags: ['gluten'],
        );
        final restrictions = [DietaryRestriction.glutenFree];

        // Act
        final multiplier = scorer.getDietaryMultiplier(food, restrictions);

        // Assert
        expect(multiplier, equals(0.1));
      });

      test('should return 1.0 for gluten-free food when gluten-free required', () {
        // Arrange
        final food = createFood(id: '1'); // No gluten
        final restrictions = [DietaryRestriction.glutenFree];

        // Act
        final multiplier = scorer.getDietaryMultiplier(food, restrictions);

        // Assert
        expect(multiplier, equals(1.0));
      });

      test('should handle multiple restrictions', () {
        // Arrange
        final food = createFood(
          id: '1',
          flavorProfile: ['vegan'],
        );
        final restrictions = [
          DietaryRestriction.vegan,
          DietaryRestriction.glutenFree,
        ];

        // Act
        final multiplier = scorer.getDietaryMultiplier(food, restrictions);

        // Assert
        expect(multiplier, equals(1.0)); // Vegan OK, gluten-free OK
      });

      test('should return 0.1 when any restriction fails', () {
        // Arrange
        final food = createFood(
          id: '1',
          flavorProfile: ['vegan'],
          allergenTags: ['gluten'],
        );
        final restrictions = [
          DietaryRestriction.vegan,
          DietaryRestriction.glutenFree,
        ];

        // Act
        final multiplier = scorer.getDietaryMultiplier(food, restrictions);

        // Assert
        expect(multiplier, equals(0.1)); // Has gluten
      });
    });

    group('matchesRestrictions', () {
      test('should return true when food matches all restrictions', () {
        // Arrange
        final food = createFood(
          id: '1',
          flavorProfile: ['vegan'],
        );
        final restrictions = [DietaryRestriction.vegan];

        // Act
        final matches = scorer.matchesRestrictions(food, restrictions);

        // Assert
        expect(matches, isTrue);
      });

      test('should return false when food does not match restrictions', () {
        // Arrange
        final food = createFood(id: '1');
        final restrictions = [DietaryRestriction.vegan];

        // Act
        final matches = scorer.matchesRestrictions(food, restrictions);

        // Assert
        expect(matches, isFalse);
      });
    });

    group('fromString', () {
      test('should convert string to DietaryRestriction', () {
        expect(DietaryRestrictionScorer.fromString('keto'), equals(DietaryRestriction.keto));
        expect(DietaryRestrictionScorer.fromString('vegan'), equals(DietaryRestriction.vegan));
        expect(DietaryRestrictionScorer.fromString('halal'), equals(DietaryRestriction.halal));
        expect(DietaryRestrictionScorer.fromString('gluten-free'), equals(DietaryRestriction.glutenFree));
      });

      test('should return null for invalid string', () {
        expect(DietaryRestrictionScorer.fromString('invalid'), isNull);
      });
    });

    group('fromStringList', () {
      test('should convert list of strings to DietaryRestriction list', () {
        // Act
        final restrictions = DietaryRestrictionScorer.fromStringList([
          'keto',
          'vegan',
          'invalid', // Should be filtered out
        ]);

        // Assert
        expect(restrictions.length, equals(2));
        expect(restrictions, contains(DietaryRestriction.keto));
        expect(restrictions, contains(DietaryRestriction.vegan));
      });
    });
  });
}

