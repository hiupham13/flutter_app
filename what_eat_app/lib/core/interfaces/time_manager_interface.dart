/// Interface for time management operations
/// Follows Dependency Inversion Principle (DIP)
abstract class ITimeManager {
  /// Get current time of day: "morning", "lunch", "dinner", "late_night"
  String getTimeOfDay();
  
  /// Get Vietnamese label for time of day
  String getTimeOfDayLabel(String timeOfDay);
  
  /// Check if food is available at current time
  bool isFoodAvailableNow(List<String> availableTimes);
  
  /// Get greeting message based on time of day
  String getTimeGreeting();
  
  /// Get current DateTime
  DateTime getCurrentDateTime();
}

