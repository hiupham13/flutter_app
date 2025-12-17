import 'package:flutter_test/flutter_test.dart';
import 'package:what_eat_app/features/recommendation/logic/scoring_cache.dart';
import 'package:what_eat_app/features/recommendation/logic/scoring_engine.dart';
import 'package:what_eat_app/models/food_model.dart';

void main() {
  group('ScoringCache', () {
    late ScoringCache cache;

    setUp(() {
      cache = ScoringCache(maxAge: const Duration(minutes: 5));
    });

    FoodModel createFood({required String id}) {
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
        viewCount: 0,
        pickCount: 0,
      );
    }

    RecommendationContext createContext({
      int budget = 2,
      String companion = 'alone',
    }) {
      return RecommendationContext(
        budget: budget,
        companion: companion,
      );
    }

    group('getCachedResult', () {
      test('should return null when no cache exists', () {
        // Arrange
        final foods = [createFood(id: '1')];
        final context = createContext();

        // Act
        final result = cache.getCachedResult(foods, context, 5);

        // Assert
        expect(result, isNull);
      });

      test('should return cached result when available and valid', () {
        // Arrange
        final foods = [createFood(id: '1')];
        final context = createContext();
        final cachedResult = [createFood(id: '1')];
        cache.cacheResult(foods, context, 5, cachedResult);

        // Act
        final result = cache.getCachedResult(foods, context, 5);

        // Assert
        expect(result, isNotNull);
        expect(result!.length, equals(1));
        expect(result.first.id, equals('1'));
      });

      test('should return null when context does not match', () {
        // Arrange
        final foods = [createFood(id: '1')];
        final context1 = createContext(budget: 1);
        final context2 = createContext(budget: 2);
        cache.cacheResult(foods, context1, 5, [createFood(id: '1')]);

        // Act
        final result = cache.getCachedResult(foods, context2, 5);

        // Assert
        expect(result, isNull);
      });

      test('should return null when topN does not match', () {
        // Arrange
        final foods = [createFood(id: '1')];
        final context = createContext();
        cache.cacheResult(foods, context, 5, [createFood(id: '1')]);

        // Act
        final result = cache.getCachedResult(foods, context, 10);

        // Assert
        expect(result, isNull);
      });
    });

    group('cacheResult', () {
      test('should store result in cache', () {
        // Arrange
        final foods = [createFood(id: '1')];
        final context = createContext();
        final result = [createFood(id: '1')];

        // Act
        cache.cacheResult(foods, context, 5, result);

        // Assert
        final cached = cache.getCachedResult(foods, context, 5);
        expect(cached, isNotNull);
        expect(cached!.length, equals(1));
      });

      test('should cleanup old entries when cache is too large', () {
        // Arrange
        final foods = [createFood(id: '1')];
        final shortCache = ScoringCache(maxAge: const Duration(milliseconds: 100));

        // Create many entries
        for (int i = 0; i < 60; i++) {
          final context = createContext(budget: i);
          shortCache.cacheResult(foods, context, 5, [createFood(id: '$i')]);
        }

        // Wait for expiration
        // Note: This test may be flaky, but demonstrates cleanup logic
        final stats = shortCache.getStats();
        expect(stats['size'], lessThanOrEqualTo(50));
      });
    });

    group('clear', () {
      test('should clear all cache entries', () {
        // Arrange
        final foods = [createFood(id: '1')];
        final context = createContext();
        cache.cacheResult(foods, context, 5, [createFood(id: '1')]);

        // Act
        cache.clear();

        // Assert
        final result = cache.getCachedResult(foods, context, 5);
        expect(result, isNull);
      });
    });

    group('getStats', () {
      test('should return cache statistics', () {
        // Act
        final stats = cache.getStats();

        // Assert
        expect(stats['size'], isA<int>());
        expect(stats['maxAge'], isA<int>());
      });
    });
  });
}

