import 'package:flutter_test/flutter_test.dart';

import 'package:what_eat_app/features/recommendation/logic/scoring_engine.dart';
import 'package:what_eat_app/models/food_model.dart';
import 'package:what_eat_app/core/services/weather_service.dart';

void main() {
  final engine = ScoringEngine();

  FoodModel buildFood({
    String id = 'pho_bo',
    int priceSegment = 2,
    List<String> allergenTags = const [],
    String cuisineId = 'vn',
    Map<String, double> contextScores = const {},
  }) {
    return FoodModel.create(
      id: id,
      name: id,
      searchKeywords: const [],
      description: '',
      images: const [],
      cuisineId: cuisineId,
      mealTypeId: 'lunch',
      flavorProfile: const [],
      allergenTags: allergenTags,
      priceSegment: priceSegment,
      avgCalories: null,
      availableTimes: const [],
      contextScores: contextScores,
      mapQuery: id,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      viewCount: 0,
      pickCount: 0,
    );
  }

  test('Hard filter: allergen should be filtered out', () {
    final foodWithAllergen = buildFood(id: 'peanut_dish', allergenTags: ['peanut']);
    final foodSafe = buildFood(id: 'safe_dish', allergenTags: []);
    
    final ctx = RecommendationContext(
      budget: 2,
      companion: 'alone',
      excludedAllergens: const ['peanut'],
    );

    // Test via getTopFoods - food with allergen should be filtered out
    final results = engine.getTopFoods([foodWithAllergen, foodSafe], ctx, 5);
    expect(results.length, 1);
    expect(results.first.id, 'safe_dish');
  });

  test('Budget filter removes items far above budget', () {
    final expensiveFood = buildFood(id: 'expensive', priceSegment: 4);
    final affordableFood = buildFood(id: 'affordable', priceSegment: 2);
    
    final ctx = RecommendationContext(budget: 1, companion: 'alone');

    // Test via getTopFoods - expensive food should be filtered out
    final results = engine.getTopFoods([expensiveFood, affordableFood], ctx, 5);
    expect(results.length, 1);
    expect(results.first.id, 'affordable');
  });

  test('Favorite cuisine boosts score and ranks higher', () {
    final favFood = buildFood(
      id: 'bun_cha',
      cuisineId: 'vn',
      contextScores: const {'weather_hot': 1.4},
    );
    final normalFood = buildFood(
      id: 'ramen',
      cuisineId: 'jp',
      contextScores: const {'weather_hot': 1.2},
    );

    final ctx = RecommendationContext(
      budget: 2,
      companion: 'alone',
      weather: WeatherData(
        temperature: 35,
        condition: 'Clear',
        description: 'Hot',
        humidity: 50,
        windSpeed: 1,
        weatherCode: 0,
      ),
      favoriteCuisines: const ['vn'],
    );

    final scores = [
      engine.calculateScore(favFood, ctx),
      engine.calculateScore(normalFood, ctx),
    ];

    expect(scores[0], greaterThan(scores[1]));
  });

  test('Recently eaten food scores lower than fresh choice', () {
    final food = buildFood(id: 'pho_bo');
    final ctxFresh = RecommendationContext(
      budget: 2,
      companion: 'alone',
    );
    final ctxRecent = RecommendationContext(
      budget: 2,
      companion: 'alone',
      recentlyEaten: const ['pho_bo'],
    );

    final freshScore = engine.calculateScore(food, ctxFresh);
    final recentScore = engine.calculateScore(food, ctxRecent);

    expect(recentScore, lessThan(freshScore));
    expect(recentScore, greaterThan(0));
  });
}

