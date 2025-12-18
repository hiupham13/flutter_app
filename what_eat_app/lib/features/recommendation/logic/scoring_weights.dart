import '../../../../core/services/weather_service.dart';

/// Weights for different scoring factors
/// Allows tuning the algorithm without changing code
class ScoringWeights {
  final double weatherWeight;
  final double companionWeight;
  final double moodWeight;
  final double budgetWeight;
  final double timeWeight;
  final double popularityWeight;
  final double personalizationWeight;
  final double diversityWeight;
  
  const ScoringWeights({
    this.weatherWeight = 1.0,
    this.companionWeight = 1.2, // More important
    this.moodWeight = 0.8,
    this.budgetWeight = 1.5, // Very important
    this.timeWeight = 1.0,
    this.popularityWeight = 0.5,
    this.personalizationWeight = 1.3,
    this.diversityWeight = 0.3,
  });
  
  /// Default weights (balanced)
  static const ScoringWeights defaultWeights = ScoringWeights();
  
  /// Weights optimized for budget-conscious users
  static const ScoringWeights budgetFocused = ScoringWeights(
    budgetWeight: 2.0,
    weatherWeight: 0.8,
    companionWeight: 1.0,
  );
  
  /// Weights optimized for social situations
  static const ScoringWeights socialFocused = ScoringWeights(
    companionWeight: 1.8,
    moodWeight: 1.2,
    budgetWeight: 1.0,
  );
  
  /// Weights optimized for personalization
  static const ScoringWeights personalizationFocused = ScoringWeights(
    personalizationWeight: 2.0,
    companionWeight: 1.0,
    weatherWeight: 0.7,
  );
  
  /// Create copy with updated values
  ScoringWeights copyWith({
    double? weatherWeight,
    double? companionWeight,
    double? moodWeight,
    double? budgetWeight,
    double? timeWeight,
    double? popularityWeight,
    double? personalizationWeight,
    double? diversityWeight,
  }) {
    return ScoringWeights(
      weatherWeight: weatherWeight ?? this.weatherWeight,
      companionWeight: companionWeight ?? this.companionWeight,
      moodWeight: moodWeight ?? this.moodWeight,
      budgetWeight: budgetWeight ?? this.budgetWeight,
      timeWeight: timeWeight ?? this.timeWeight,
      popularityWeight: popularityWeight ?? this.popularityWeight,
      personalizationWeight: personalizationWeight ?? this.personalizationWeight,
      diversityWeight: diversityWeight ?? this.diversityWeight,
    );
  }
  
  /// Get context-dependent weights
  static ScoringWeights getContextDependentWeights({
    required int budget,
    required String companion,
    WeatherData? weather,
  }) {
    var weights = ScoringWeights.defaultWeights;
    
    // Adjust based on context
    if (budget == 1) {
      // End of month - budget is critical
      weights = weights.copyWith(budgetWeight: 2.0);
    }
    
    if (companion == 'date') {
      // Date - companion and mood are very important
      weights = weights.copyWith(
        companionWeight: 1.8,
        moodWeight: 1.2,
      );
    }
    
    if (weather?.isRainy == true) {
      // Rainy weather - weather is more important
      weights = weights.copyWith(weatherWeight: 1.5);
    }
    
    return weights;
  }
}

