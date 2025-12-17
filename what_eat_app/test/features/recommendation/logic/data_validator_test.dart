import 'package:flutter_test/flutter_test.dart';
import 'package:what_eat_app/features/recommendation/logic/data_validator.dart';
import 'package:what_eat_app/models/food_model.dart';

void main() {
  group('DataValidator', () {
    late DataValidator validator;

    setUp(() {
      validator = DataValidator();
    });

    group('validateAndFix', () {
      test('should fix missing context scores', () {
        // Arrange
        final food = FoodModel.create(
          id: '1',
          name: 'Phở',
          searchKeywords: ['pho'],
          description: 'Phở bò',
          images: ['image1.jpg'],
          cuisineId: 'vn',
          mealTypeId: 'soup',
          flavorProfile: [],
          allergenTags: [],
          priceSegment: 2,
          availableTimes: ['morning', 'lunch'],
          contextScores: {}, // Empty context scores
          mapQuery: 'pho',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          viewCount: 0,
          pickCount: 0,
        );

        // Act
        final fixed = validator.validateAndFix(food);

        // Assert
        expect(fixed.contextScores, isNotEmpty);
        expect(fixed.contextScores.containsKey('weather_hot'), isTrue);
        expect(fixed.contextScores.containsKey('companion_alone'), isTrue);
        expect(fixed.contextScores.containsKey('time_morning'), isTrue);
      });

      test('should fix invalid price segment', () {
        // Arrange
        final food = FoodModel.create(
          id: '1',
          name: 'Phở',
          searchKeywords: ['pho'],
          description: 'Phở bò',
          images: ['image1.jpg'],
          cuisineId: 'vn',
          mealTypeId: 'soup',
          flavorProfile: [],
          allergenTags: [],
          priceSegment: 5, // Invalid (>3)
          availableTimes: ['morning'],
          contextScores: {'weather_hot': 1.0},
          mapQuery: 'pho',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          viewCount: 0,
          pickCount: 0,
        );

        // Act
        final fixed = validator.validateAndFix(food);

        // Assert
        expect(fixed.priceSegment, greaterThanOrEqualTo(1));
        expect(fixed.priceSegment, lessThanOrEqualTo(3));
      });

      test('should fix missing search keywords', () {
        // Arrange
        final food = FoodModel.create(
          id: '1',
          name: 'Phở',
          searchKeywords: [], // Empty
          description: 'Phở bò',
          images: ['image1.jpg'],
          cuisineId: 'vn',
          mealTypeId: 'soup',
          flavorProfile: [],
          allergenTags: [],
          priceSegment: 2,
          availableTimes: ['morning'],
          contextScores: {'weather_hot': 1.0},
          mapQuery: 'pho',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          viewCount: 0,
          pickCount: 0,
        );

        // Act
        final fixed = validator.validateAndFix(food);

        // Assert
        expect(fixed.searchKeywords, isNotEmpty);
        expect(fixed.searchKeywords.first, contains('phở'));
      });

      test('should fix missing available times', () {
        // Arrange
        final food = FoodModel.create(
          id: '1',
          name: 'Phở',
          searchKeywords: ['pho'],
          description: 'Phở bò',
          images: ['image1.jpg'],
          cuisineId: 'vn',
          mealTypeId: 'soup',
          flavorProfile: [],
          allergenTags: [],
          priceSegment: 2,
          availableTimes: [], // Empty
          contextScores: {'weather_hot': 1.0},
          mapQuery: 'pho',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          viewCount: 0,
          pickCount: 0,
        );

        // Act
        final fixed = validator.validateAndFix(food);

        // Assert
        expect(fixed.availableTimes, isNotEmpty);
        expect(fixed.availableTimes.length, greaterThanOrEqualTo(1));
      });

      test('should clamp context score values to valid range', () {
        // Arrange
        final food = FoodModel.create(
          id: '1',
          name: 'Phở',
          searchKeywords: ['pho'],
          description: 'Phở bò',
          images: ['image1.jpg'],
          cuisineId: 'vn',
          mealTypeId: 'soup',
          flavorProfile: [],
          allergenTags: [],
          priceSegment: 2,
          availableTimes: ['morning'],
          contextScores: {
            'weather_hot': 5.0, // Invalid (>2.0)
            'companion_alone': -1.0, // Invalid (<0.0)
          },
          mapQuery: 'pho',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          viewCount: 0,
          pickCount: 0,
        );

        // Act
        final fixed = validator.validateAndFix(food);

        // Assert
        expect(fixed.contextScores['weather_hot'], lessThanOrEqualTo(2.0));
        expect(fixed.contextScores['weather_hot'], greaterThanOrEqualTo(0.0));
        expect(fixed.contextScores['companion_alone'], lessThanOrEqualTo(2.0));
        expect(fixed.contextScores['companion_alone'], greaterThanOrEqualTo(0.0));
      });
    });

    group('validateAndFixList', () {
      test('should validate and fix list of foods', () {
        // Arrange
        final foods = [
          FoodModel.create(
            id: '1',
            name: 'Phở',
            searchKeywords: [],
            description: 'Phở bò',
            images: [],
            cuisineId: 'vn',
            mealTypeId: 'soup',
            flavorProfile: [],
            allergenTags: [],
            priceSegment: 5,
            availableTimes: [],
            contextScores: {},
            mapQuery: 'pho',
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            viewCount: 0,
            pickCount: 0,
          ),
        ];

        // Act
        final fixed = validator.validateAndFixList(foods);

        // Assert
        expect(fixed.length, equals(1));
        expect(fixed.first.searchKeywords, isNotEmpty);
        expect(fixed.first.priceSegment, lessThanOrEqualTo(3));
        expect(fixed.first.contextScores, isNotEmpty);
      });
    });

    group('calculateQualityScore', () {
      test('should return 1.0 for perfect food', () {
        // Arrange
        final food = FoodModel.create(
          id: '1',
          name: 'Phở',
          searchKeywords: ['pho'],
          description: 'Phở bò',
          images: ['image1.jpg'],
          cuisineId: 'vn',
          mealTypeId: 'soup',
          flavorProfile: [],
          allergenTags: [],
          priceSegment: 2,
          availableTimes: ['morning'],
          contextScores: {'weather_hot': 1.0},
          mapQuery: 'pho',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          viewCount: 0,
          pickCount: 0,
        );

        // Act
        final score = validator.calculateQualityScore(food);

        // Assert
        expect(score, equals(1.0));
      });

      test('should deduct for missing data', () {
        // Arrange
        final food = FoodModel.create(
          id: '1',
          name: 'Phở',
          searchKeywords: [],
          description: 'Phở bò',
          images: [],
          cuisineId: 'vn',
          mealTypeId: 'soup',
          flavorProfile: [],
          allergenTags: [],
          priceSegment: 5,
          availableTimes: [],
          contextScores: {},
          mapQuery: 'pho',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          viewCount: 0,
          pickCount: 0,
        );

        // Act
        final score = validator.calculateQualityScore(food);

        // Assert
        expect(score, lessThan(1.0));
        expect(score, greaterThanOrEqualTo(0.0));
      });
    });
  });
}

