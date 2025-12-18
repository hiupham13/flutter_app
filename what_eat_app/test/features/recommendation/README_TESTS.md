# Unit Tests for Recommendation Algorithm Improvements

## Overview

This directory contains comprehensive unit tests for all High Priority and Medium Priority improvements to the recommendation algorithm.

## Test Files

### High Priority Improvements

1. **`data_validator_test.dart`**
   - Tests data validation and fallback logic
   - Validates context scores, price segments, search keywords
   - Tests quality score calculation

2. **`scoring_weights_test.dart`**
   - Tests weighted scoring system
   - Validates context-dependent weights
   - Tests predefined weight sets

3. **`diversity_enforcer_test.dart`**
   - Tests diversity enforcement
   - Tests category balancing
   - Tests minimum variety guarantee
   - Tests combined diversity methods

### Medium Priority Improvements

4. **`popularity_scorer_test.dart`**
   - Tests popularity multiplier calculation
   - Tests trending multiplier
   - Tests combined multiplier
   - Tests popularity score normalization

5. **`dietary_restriction_scorer_test.dart`**
   - Tests dietary restriction filtering
   - Tests multiple restrictions
   - Tests string conversion utilities

6. **`location_scorer_test.dart`**
   - Tests location-based scoring
   - Tests keyword matching
   - Tests batch multiplier calculation

7. **`time_availability_scorer_test.dart`**
   - Tests time availability checking
   - Tests day of week and seasonal availability
   - Tests availability status messages

8. **`scoring_cache_test.dart`**
   - Tests scoring result caching
   - Tests cache expiration
   - Tests cache cleanup

9. **`user_preference_learner_test.dart`**
   - Tests preference learning logic
   - Tests context enhancement
   - Tests confidence calculation

10. **`graceful_degradation_test.dart`**
    - Tests fallback strategies
    - Tests filter relaxation
    - Tests minimal filter application

11. **`anti_repetition_filter_test.dart`**
    - Tests recent recommendation filtering
    - Tests new vs recent food prioritization

12. **`cold_start_handler_test.dart`**
    - Tests new user handling
    - Tests popular/trending food selection

## Running Tests

### Run all tests
```bash
cd what_eat_app
flutter test
```

### Run specific test file
```bash
flutter test test/features/recommendation/logic/data_validator_test.dart
```

### Run with coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## Test Coverage Goals

- **Business Logic:** 80%+ coverage
- **Scoring Algorithms:** 85%+ coverage
- **Data Validation:** 90%+ coverage
- **Diversity Enforcement:** 80%+ coverage

## Test Structure

Each test file follows this structure:

```dart
group('ClassName', () {
  late ClassName instance;
  
  setUp(() {
    instance = ClassName();
  });
  
  group('methodName', () {
    test('should do something when condition', () {
      // Arrange
      // Act
      // Assert
    });
  });
});
```

## Mocking

For tests that require external dependencies (Firestore, repositories), use:
- `mockito` package for creating mocks
- `fake_async` for time-based tests
- `testWidgets` for widget tests

## Notes

- Some tests require mocking Firestore/repositories (marked with comments)
- Time-based tests may be flaky - use `fake_async` when possible
- Integration tests should be in `integration_test/` directory

## Future Improvements

- Add integration tests for full recommendation flow
- Add performance tests for scoring algorithms
- Add stress tests for large datasets
- Add edge case tests for all improvements

