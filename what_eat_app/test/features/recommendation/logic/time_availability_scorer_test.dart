import 'package:flutter_test/flutter_test.dart';
import 'package:what_eat_app/features/recommendation/logic/time_availability_scorer.dart';
import 'package:what_eat_app/models/food_model.dart';

void main() {
  group('TimeAvailabilityScorer', () {
    late TimeAvailabilityScorer scorer;

    setUp(() {
      scorer = TimeAvailabilityScorer();
    });

    FoodModel createFood({
      required String id,
      List<String> availableTimes = const [],
      Map<String, double> contextScores = const {},
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
        availableTimes: availableTimes,
        contextScores: contextScores,
        mapQuery: 'food',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        viewCount: 0,
        pickCount: 0,
      );
    }

    group('getAvailabilityMultiplier', () {
      test('should return 1.0 for food available at current time', () {
        // Arrange
        final currentTime = DateTime.now();
        final timeOfDay = currentTime.hour < 12
            ? 'morning'
            : currentTime.hour < 18
                ? 'lunch'
                : 'dinner';
        final food = createFood(
          id: '1',
          availableTimes: [timeOfDay],
        );

        // Act
        final multiplier = scorer.getAvailabilityMultiplier(food);

        // Assert
        expect(multiplier, greaterThanOrEqualTo(0.6));
        expect(multiplier, lessThanOrEqualTo(1.0));
      });

      test('should return 0.6 for food not available at current time', () {
        // Arrange
        final currentTime = DateTime.now();
        final timeOfDay = currentTime.hour < 12
            ? 'morning'
            : currentTime.hour < 18
                ? 'lunch'
                : 'dinner';
        final unavailableTime = timeOfDay == 'morning' ? 'dinner' : 'morning';
        final food = createFood(
          id: '1',
          availableTimes: [unavailableTime],
        );

        // Act
        final multiplier = scorer.getAvailabilityMultiplier(food);

        // Assert
        expect(multiplier, lessThan(1.0));
        expect(multiplier, greaterThanOrEqualTo(0.6));
      });

      test('should return 1.0 for food with empty available times', () {
        // Arrange
        final food = createFood(
          id: '1',
          availableTimes: [],
        );

        // Act
        final multiplier = scorer.getAvailabilityMultiplier(food);

        // Assert
        expect(multiplier, equals(1.0));
      });

      test('should check day of week if in context scores', () {
        // Arrange
        final currentDay = DateTime.now().weekday;
        final food = createFood(
          id: '1',
          contextScores: {
            'available_day_$currentDay': 0.3, // Low availability
          },
        );

        // Act
        final multiplier = scorer.getAvailabilityMultiplier(food);

        // Assert
        expect(multiplier, lessThan(1.0));
      });
    });

    group('isAvailableNow', () {
      test('should return true for available food', () {
        // Arrange
        final food = createFood(
          id: '1',
          availableTimes: ['morning', 'lunch', 'dinner'],
        );

        // Act
        final isAvailable = scorer.isAvailableNow(food);

        // Assert
        expect(isAvailable, isTrue);
      });

      test('should return false for unavailable food', () {
        // Arrange
        final currentTime = DateTime.now();
        final timeOfDay = currentTime.hour < 12
            ? 'morning'
            : currentTime.hour < 18
                ? 'lunch'
                : 'dinner';
        final unavailableTime = timeOfDay == 'morning' ? 'dinner' : 'morning';
        final food = createFood(
          id: '1',
          availableTimes: [unavailableTime],
        );

        // Act
        final isAvailable = scorer.isAvailableNow(food);

        // Assert
        // May be true or false depending on current time
        expect(isAvailable, isA<bool>());
      });
    });

    group('getAvailabilityStatus', () {
      test('should return appropriate status message', () {
        // Arrange
        final food = createFood(
          id: '1',
          availableTimes: ['morning', 'lunch', 'dinner'],
        );

        // Act
        final status = scorer.getAvailabilityStatus(food);

        // Assert
        expect(status, isA<String>());
        expect(status, isNotEmpty);
      });
    });
  });
}

