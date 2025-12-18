import '../../../../models/food_model.dart';
import '../../../../core/interfaces/time_manager_interface.dart';
import '../../../../core/services/time_manager.dart';
import '../interfaces/scorer_interfaces.dart';

/// Enhanced time availability scoring
/// Implements ITimeAvailabilityScorer interface (DIP)
class TimeAvailabilityScorer implements ITimeAvailabilityScorer {
  final ITimeManager _timeManager;
  
  TimeAvailabilityScorer({ITimeManager? timeManager})
      : _timeManager = timeManager ?? TimeManager();
  
  /// Get availability multiplier based on current time
  /// Returns 1.0 if available, lower if not available
  @override
  double getAvailabilityMultiplier(FoodModel food) {
    final currentTime = DateTime.now();
    final currentTimeOfDay = _timeManager.getTimeOfDay();
    
    // Check 1: Basic time of day availability
    if (food.availableTimes.isNotEmpty) {
      if (!food.availableTimes.contains(currentTimeOfDay)) {
        // Not available at current time, but still allow with penalty
        return 0.6; // 40% penalty
      }
    }
    
    // Check 2: Day of week (if food has specific days)
    // This would require adding availableDays to FoodModel
    // For now, we'll use context scores if available
    final dayOfWeek = currentTime.weekday; // 1 = Monday, 7 = Sunday
    final dayKey = 'available_day_$dayOfWeek';
    if (food.contextScores.containsKey(dayKey)) {
      final dayScore = food.contextScores[dayKey] ?? 0.0;
      if (dayScore < 0.5) {
        return 0.7; // 30% penalty for less available days
      }
    }
    
    // Check 3: Seasonal availability (if food is seasonal)
    // This would require adding seasonalAvailability to FoodModel
    // For now, we'll use context scores if available
    final season = _getSeason(currentTime);
    final seasonKey = 'available_season_$season';
    if (food.contextScores.containsKey(seasonKey)) {
      final seasonScore = food.contextScores[seasonKey] ?? 0.0;
      if (seasonScore < 0.5) {
        return 0.8; // 20% penalty for out-of-season
      }
    }
    
    // Available - full score
    return 1.0;
  }
  
  /// Get season from date
  String _getSeason(DateTime date) {
    final month = date.month;
    
    // Vietnam seasons (approximate)
    if (month >= 3 && month <= 5) {
      return 'spring'; // Xuân
    } else if (month >= 6 && month <= 8) {
      return 'summer'; // Hè
    } else if (month >= 9 && month <= 11) {
      return 'autumn'; // Thu
    } else {
      return 'winter'; // Đông
    }
  }
  
  /// Check if food is available right now
  @override
  bool isAvailableNow(FoodModel food) {
    return getAvailabilityMultiplier(food) >= 0.8;
  }
  
  /// Get availability status message
  @override
  String getAvailabilityStatus(FoodModel food) {
    final multiplier = getAvailabilityMultiplier(food);
    
    if (multiplier >= 0.9) {
      return 'Có sẵn ngay';
    } else if (multiplier >= 0.7) {
      return 'Có thể có sẵn';
    } else if (multiplier >= 0.5) {
      return 'Khó tìm';
    } else {
      return 'Không có sẵn';
    }
  }
}

