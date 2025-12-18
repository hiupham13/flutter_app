import 'package:flutter_test/flutter_test.dart';
import 'package:what_eat_app/features/recommendation/logic/scoring_weights.dart';
import 'package:what_eat_app/core/services/weather_service.dart';

void main() {
  group('ScoringWeights', () {
    test('defaultWeights should have balanced values', () {
      // Act
      final weights = ScoringWeights.defaultWeights;

      // Assert
      expect(weights.weatherWeight, equals(1.0));
      expect(weights.companionWeight, equals(1.2));
      expect(weights.budgetWeight, equals(1.5));
      expect(weights.personalizationWeight, equals(1.3));
    });

    test('budgetFocused should prioritize budget', () {
      // Act
      final weights = ScoringWeights.budgetFocused;

      // Assert
      expect(weights.budgetWeight, equals(2.0));
      expect(weights.weatherWeight, equals(0.8));
    });

    test('socialFocused should prioritize companion and mood', () {
      // Act
      final weights = ScoringWeights.socialFocused;

      // Assert
      expect(weights.companionWeight, equals(1.8));
      expect(weights.moodWeight, equals(1.2));
    });

    test('personalizationFocused should prioritize personalization', () {
      // Act
      final weights = ScoringWeights.personalizationFocused;

      // Assert
      expect(weights.personalizationWeight, equals(2.0));
    });

    test('copyWith should create new instance with updated values', () {
      // Arrange
      final original = ScoringWeights.defaultWeights;

      // Act
      final updated = original.copyWith(budgetWeight: 2.5);

      // Assert
      expect(updated.budgetWeight, equals(2.5));
      expect(updated.weatherWeight, equals(original.weatherWeight));
      expect(updated.companionWeight, equals(original.companionWeight));
    });

    group('getContextDependentWeights', () {
      test('should increase budget weight for budget=1', () {
        // Act
        final weights = ScoringWeights.getContextDependentWeights(
          budget: 1,
          companion: 'alone',
        );

        // Assert
        expect(weights.budgetWeight, equals(2.0));
      });

      test('should increase companion and mood weights for date', () {
        // Act
        final weights = ScoringWeights.getContextDependentWeights(
          budget: 2,
          companion: 'date',
        );

        // Assert
        expect(weights.companionWeight, equals(1.8));
        expect(weights.moodWeight, equals(1.2));
      });

      test('should increase weather weight for rainy weather', () {
        // Arrange
        final weather = WeatherData(
          temperature: 25.0,
          condition: 'rainy',
          description: 'Rainy',
          humidity: 80,
          windSpeed: 5.0,
          weatherCode: 500,
        );

        // Act
        final weights = ScoringWeights.getContextDependentWeights(
          budget: 2,
          companion: 'alone',
          weather: weather,
        );

        // Assert
        expect(weights.weatherWeight, equals(1.5));
      });

      test('should use default weights when no special conditions', () {
        // Act
        final weights = ScoringWeights.getContextDependentWeights(
          budget: 2,
          companion: 'alone',
        );

        // Assert
        expect(weights.budgetWeight, equals(ScoringWeights.defaultWeights.budgetWeight));
        expect(weights.companionWeight, equals(ScoringWeights.defaultWeights.companionWeight));
      });
    });
  });
}

