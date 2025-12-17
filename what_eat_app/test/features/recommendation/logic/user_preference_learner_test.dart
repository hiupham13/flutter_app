import 'package:flutter_test/flutter_test.dart';
import 'package:what_eat_app/features/recommendation/logic/user_preference_learner.dart';
import 'package:what_eat_app/features/recommendation/logic/scoring_engine.dart';

void main() {
  group('UserPreferenceLearner', () {
    // Note: These tests would require mocking Firestore and repositories
    // For now, we'll test the logic that doesn't require external dependencies

    group('LearnedPreferences', () {
      test('empty should return empty preferences', () {
        // Act
        final prefs = LearnedPreferences.empty();

        // Assert
        expect(prefs.isEmpty, isTrue);
        expect(prefs.favoriteCuisines, isEmpty);
        expect(prefs.preferredMealTypes, isEmpty);
        expect(prefs.confidence, equals(0.0));
      });

      test('should not be empty when has preferences', () {
        // Arrange
        final prefs = LearnedPreferences(
          favoriteCuisines: ['vn'],
          preferredMealTypes: ['soup'],
          confidence: 0.5,
        );

        // Assert
        expect(prefs.isEmpty, isFalse);
        expect(prefs.favoriteCuisines, contains('vn'));
      });
    });

    group('applyLearnedPreferences', () {
      test('should merge favorite cuisines', () {
        // Arrange
        final learner = UserPreferenceLearner();
        final baseContext = RecommendationContext(
          budget: 2,
          companion: 'alone',
          favoriteCuisines: ['kr'],
        );
        final learned = LearnedPreferences(
          favoriteCuisines: ['vn', 'jp'],
          confidence: 0.8,
        );

        // Act
        final enhanced = learner.applyLearnedPreferences(baseContext, learned);

        // Assert
        expect(enhanced.favoriteCuisines.length, greaterThanOrEqualTo(2));
        expect(enhanced.favoriteCuisines, contains('vn'));
        expect(enhanced.favoriteCuisines, contains('kr'));
      });

      test('should adjust budget when confidence is high', () {
        // Arrange
        final learner = UserPreferenceLearner();
        final baseContext = RecommendationContext(
          budget: 2,
          companion: 'alone',
        );
        final learned = LearnedPreferences(
          preferredPriceSegment: 1,
          confidence: 0.8, // High confidence
        );

        // Act
        final enhanced = learner.applyLearnedPreferences(baseContext, learned);

        // Assert
        expect(enhanced.budget, equals(1));
      });

      test('should not adjust budget when confidence is low', () {
        // Arrange
        final learner = UserPreferenceLearner();
        final baseContext = RecommendationContext(
          budget: 2,
          companion: 'alone',
        );
        final learned = LearnedPreferences(
          preferredPriceSegment: 1,
          confidence: 0.3, // Low confidence
        );

        // Act
        final enhanced = learner.applyLearnedPreferences(baseContext, learned);

        // Assert
        expect(enhanced.budget, equals(2)); // Unchanged
      });
    });
  });
}

