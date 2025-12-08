import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/logger.dart';
import 'weather_service.dart';
import 'dart:math';

/// Service quản lý copywriting (jokes, greetings, reasons) từ Firestore
class CopywritingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Fallback data nếu Firestore không có hoặc lỗi
  final Map<String, List<String>> _fallbackData = {
    'greetings_weather_hot': [
      'Trời nóng thế này chỉ có ăn kem!',
      'Nóng chảy mỡ, đừng ăn lẩu nhé!',
      '35 độ rồi, kiếm gì mát mát ăn đi!',
    ],
    'greetings_weather_rain': [
      'Trời mưa thế này, lẩu nóng là nhất!',
      'Mưa rồi, ăn gì ấm ấm cho đỡ lạnh!',
    ],
    'greetings_weather_cold': [
      'Trời lạnh, cần món nóng hổi!',
      'Lạnh quá, kiếm lẩu hay nướng ăn thôi!',
    ],
    'reasons_weather_hot': [
      'Trời nóng nên gợi ý món mát, dễ ăn',
      'Nhiệt độ cao, món này sẽ giúp bạn mát mẻ hơn',
    ],
    'reasons_weather_rain': [
      'Trời mưa, món này sẽ làm ấm bụng bạn',
      'Mưa rồi, cần món nóng để chống lạnh',
    ],
    'reasons_companion_alone': [
      'Đi một mình, món này vừa nhanh vừa ngon',
      'Một mình thì món này là lựa chọn hoàn hảo',
    ],
    'reasons_companion_date': [
      'Hẹn hò thì món này rất phù hợp',
      'Date thì nên chọn món này, không nặng mùi',
    ],
    'reasons_companion_group': [
      'Đi nhóm thì món này rất hợp để chia sẻ',
      'Nhóm bạn, món này sẽ vui hơn',
    ],
    'reasons_mood_stress': [
      'Stress thì cần món này để giải tỏa',
      'Tâm trạng không tốt, món này sẽ giúp bạn vui hơn',
    ],
    'reasons_mood_sick': [
      'Ốm rồi, món này dễ tiêu và bổ dưỡng',
      'Mệt mỏi, món này sẽ giúp bạn hồi phục',
    ],
    'jokes_general': [
      'Nhớ xin thêm trà đá nhé, món này hơi cay đấy!',
      'Ăn xong nhớ đánh răng, không thì hơi thở sẽ...',
      'Món này ngon lắm, nhưng đừng ăn quá no nhé!',
      'Gợi ý này 99% chính xác, 1% còn lại là do bạn không thích!',
    ],
  };

  /// Lấy greeting message theo weather
  Future<String> getGreetingMessage(WeatherData? weather) async {
    if (weather == null) {
      return 'Xin chào! Hôm nay ăn gì nhỉ?';
    }

    String key;
    if (weather.isHot) {
      key = 'greetings_weather_hot';
    } else if (weather.isRainy) {
      key = 'greetings_weather_rain';
    } else if (weather.isCold) {
      key = 'greetings_weather_cold';
    } else {
      return 'Xin chào! Hôm nay ăn gì nhỉ?';
    }

    return await _getRandomMessage('greetings', key);
  }

  /// Lấy lý do gợi ý món ăn
  Future<String> getRecommendationReason({
    WeatherData? weather,
    String? companion,
    String? mood,
  }) async {
    List<String> reasons = [];

    // Lấy reason theo weather
    if (weather != null) {
      if (weather.isHot) {
        reasons.add(await _getRandomMessage('reasons', 'reasons_weather_hot'));
      } else if (weather.isRainy) {
        reasons.add(await _getRandomMessage('reasons', 'reasons_weather_rain'));
      }
    }

    // Lấy reason theo companion
    if (companion != null) {
      reasons.add(await _getRandomMessage('reasons', 'reasons_companion_$companion'));
    }

    // Lấy reason theo mood
    if (mood != null && mood != 'normal') {
      reasons.add(await _getRandomMessage('reasons', 'reasons_mood_$mood'));
    }

    if (reasons.isEmpty) {
      return 'Món này phù hợp với bạn lúc này';
    }

    return reasons.join('. ');
  }

  /// Lấy câu joke ngẫu nhiên
  Future<String> getJokeMessage() async {
    return await _getRandomMessage('jokes', 'jokes_general');
  }

  /// Lấy message ngẫu nhiên từ Firestore hoặc fallback
  Future<String> _getRandomMessage(String category, String key) async {
    try {
      // Thử lấy từ Firestore
      final doc = await _firestore
          .collection('app_configs')
          .doc('copywriting')
          .get();

      if (doc.exists) {
        final data = doc.data();
        final categoryData = data?[category] as Map<String, dynamic>?;
        final messages = categoryData?[key] as List<dynamic>?;

        if (messages != null && messages.isNotEmpty) {
          final random = Random();
          return messages[random.nextInt(messages.length)].toString();
        }
      }
    } catch (e) {
      AppLogger.warning('Error getting copywriting from Firestore: $e');
    }

    // Fallback to local data
    final fallbackMessages = _fallbackData[key];
    if (fallbackMessages != null && fallbackMessages.isNotEmpty) {
      final random = Random();
      return fallbackMessages[random.nextInt(fallbackMessages.length)];
    }

    // Ultimate fallback
    return 'Hôm nay ăn gì nhỉ?';
  }
}

// Provider
final copywritingServiceProvider = Provider<CopywritingService>((ref) {
  return CopywritingService();
});

