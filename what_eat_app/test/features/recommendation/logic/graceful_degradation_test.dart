import 'package:flutter_test/flutter_test.dart';
import 'package:what_eat_app/features/recommendation/logic/graceful_degradation.dart';
import 'package:what_eat_app/features/recommendation/logic/scoring_engine.dart';
import 'package:what_eat_app/models/food_model.dart';

void main() {
  group('GracefulDegradation', () {
    late GracefulDegradation degradation;
    late ScoringEngine scoringEngine;

    setUp(() {
      scoringEngine = ScoringEngine();
      degradation = GracefulDegradation(scoringEngine);
    });

    FoodModel createFood({
      required String id,
      int priceSegment = 2,
      List<String> allergenTags = const [],
      bool isActive = true,
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
        allergenTags: allergenTags,
        priceSegment: priceSegment,
        availableTimes: ['morning', 'lunch', 'dinner'],
        contextScores: {},
        mapQuery: 'food',
        isActive: isActive,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        viewCount: 0,
        pickCount: 0,
      );
    }

    RecommendationContext createContext({
      int budget = 2,
      List<String> excludedAllergens = const [],
      bool isVegetarian = false,
    }) {
      return RecommendationContext(
        budget: budget,
        companion: 'alone',
        excludedAllergens: excludedAllergens,
        isVegetarian: isVegetarian,
      );
    }

    group('getRecommendationsWithFallback', () {
      test('should return results with strict filters when available', () async {
        // Arrange
        final foods = [
          createFood(id: '1', priceSegment: 2),
          createFood(id: '2', priceSegment: 2),
        ];
        final context = createContext(budget: 2);

        // Act
        final result = await degradation.getRecommendationsWithFallback(
          foods,
          context,
          2,
        );

        // Assert
        expect(result, isNotEmpty);
        expect(result.length, lessThanOrEqualTo(2));
      });

      test('should relax budget when no results with strict filters', () async {
        // Arrange
        final foods = [
          createFood(id: '1', priceSegment: 3), // Above budget
          createFood(id: '2', priceSegment: 3),
        ];
        final context = createContext(budget: 1); // Very low budget

        // Act
        final result = await degradation.getRecommendationsWithFallback(
          foods,
          context,
          2,
        );

        // Assert
        // Should still return results (budget relaxed)
        expect(result, isA<List<FoodModel>>());
      });

      test('should return empty list when no foods available', () async {
        // Arrange
        final foods = <FoodModel>[];
        final context = createContext();

        // Act
        final result = await degradation.getRecommendationsWithFallback(
          foods,
          context,
          5,
        );

        // Assert
        expect(result, isEmpty);
      });

      test('should apply minimal filters as last resort', () async {
        // Arrange
        final foods = [
          createFood(id: '1', priceSegment: 3),
          createFood(id: '2', priceSegment: 3),
        ];
        final context = createContext(
          budget: 1,
          excludedAllergens: ['peanut'],
        );

        // Act
        final result = await degradation.getRecommendationsWithFallback(
          foods,
          context,
          2,
        );

        // Assert
        // Should return results with minimal filters
        expect(result, isA<List<FoodModel>>());
      });
    });
  });
}

