import '../interfaces/time_manager_interface.dart';

/// Service quản lý thời gian và xác định khung giờ ăn
/// Implements ITimeManager interface (DIP)
class TimeManager implements ITimeManager {
  /// Xác định time of day dựa trên giờ hiện tại
  /// Returns: "morning", "lunch", "dinner", "late_night"
  @override
  String getTimeOfDay() {
    final now = DateTime.now();
    final hour = now.hour;

    // Morning: 6:00 - 10:00
    if (hour >= 6 && hour < 10) {
      return 'morning';
    }
    // Lunch: 10:00 - 14:00
    else if (hour >= 10 && hour < 14) {
      return 'lunch';
    }
    // Dinner: 17:00 - 22:00
    else if (hour >= 17 && hour < 22) {
      return 'dinner';
    }
    // Late Night: 22:00 - 6:00
    else {
      return 'late_night';
    }
  }

  /// Lấy label tiếng Việt cho time of day
  @override
  String getTimeOfDayLabel(String timeOfDay) {
    switch (timeOfDay) {
      case 'morning':
        return 'Sáng';
      case 'lunch':
        return 'Trưa';
      case 'dinner':
        return 'Tối';
      case 'late_night':
        return 'Khuya';
      default:
        return 'Không xác định';
    }
  }

  /// Kiểm tra xem món ăn có bán ở thời điểm hiện tại không
  @override
  bool isFoodAvailableNow(List<String> availableTimes) {
    final currentTime = getTimeOfDay();
    return availableTimes.contains(currentTime);
  }

  /// Get current DateTime
  @override
  DateTime getCurrentDateTime() {
    return DateTime.now();
  }

  /// Lấy greeting message theo time of day
  @override
  String getTimeGreeting() {
    final timeOfDay = getTimeOfDay();
    switch (timeOfDay) {
      case 'morning':
        return 'Chào buổi sáng';
      case 'lunch':
        return 'Chào buổi trưa';
      case 'dinner':
        return 'Chào buổi tối';
      case 'late_night':
        return 'Đêm khuya rồi';
      default:
        return 'Xin chào';
    }
  }
}

