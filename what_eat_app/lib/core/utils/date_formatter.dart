import 'package:intl/intl.dart';

class DateFormatter {
  /// Format ngày giờ thành chuỗi tiếng Việt
  /// Ví dụ: "30/11/2024 14:30"
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm', 'vi').format(dateTime);
  }

  /// Format ngày thành chuỗi
  /// Ví dụ: "30/11/2024"
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'vi').format(date);
  }

  /// Format giờ thành chuỗi
  /// Ví dụ: "14:30"
  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm', 'vi').format(dateTime);
  }

  /// Format relative time (ví dụ: "2 giờ trước", "Hôm qua")
  static String formatRelative(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Vừa xong';
        }
        return '${difference.inMinutes} phút trước';
      }
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays == 1) {
      return 'Hôm qua';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return formatDate(dateTime);
    }
  }
}

