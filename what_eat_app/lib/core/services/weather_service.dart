import 'package:dio/dio.dart';
import '../utils/logger.dart';

class WeatherService {
  final Dio _dio = Dio();
  // Open-Meteo API - Miễn phí, không cần API key
  static const String _baseUrl = 'https://api.open-meteo.com/v1';

  /// Lấy thông tin thời tiết theo tọa độ
  Future<WeatherData?> getWeatherByCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/forecast',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'current_weather': true,
          'timezone': 'auto',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final currentWeather = data['current_weather'] as Map<String, dynamic>;
        final weatherCode = currentWeather['weathercode'] as int;

        return WeatherData(
          temperature: (currentWeather['temperature'] as num).toDouble(),
          condition: _getWeatherCondition(weatherCode),
          description: _getWeatherDescription(weatherCode),
          humidity: 0, // Open-Meteo không cung cấp humidity trong current_weather
          windSpeed: (currentWeather['windspeed'] as num).toDouble(),
          weatherCode: weatherCode,
        );
      }
    } catch (e) {
      AppLogger.error('Error fetching weather: $e');
    }
    return null;
  }

  /// Lấy thông tin thời tiết theo tên thành phố
  /// Open-Meteo yêu cầu tọa độ, nên method này sẽ cần geocoding service
  /// Tạm thời return null, có thể tích hợp thêm geocoding service sau
  Future<WeatherData?> getWeatherByCity(String cityName) async {
    AppLogger.warning(
      'getWeatherByCity is not supported with Open-Meteo. '
      'Please use getWeatherByCoordinates instead.',
    );
    return null;
  }

  /// Chuyển đổi weather code sang condition string
  String _getWeatherCondition(int weatherCode) {
    // Weather code mapping theo WMO (World Meteorological Organization)
    if (weatherCode == 0) return 'Clear';
    if (weatherCode >= 1 && weatherCode <= 3) return 'PartlyCloudy';
    if (weatherCode == 45 || weatherCode == 48) return 'Fog';
    if (weatherCode >= 51 && weatherCode <= 67) return 'Rain';
    if (weatherCode >= 71 && weatherCode <= 77) return 'Snow';
    if (weatherCode >= 80 && weatherCode <= 82) return 'RainShowers';
    if (weatherCode >= 85 && weatherCode <= 86) return 'SnowShowers';
    if (weatherCode >= 95 && weatherCode <= 99) return 'Thunderstorm';
    return 'Unknown';
  }

  /// Chuyển đổi weather code sang description tiếng Việt
  String _getWeatherDescription(int weatherCode) {
    switch (weatherCode) {
      case 0:
        return 'Trời quang';
      case 1:
        return 'Chủ yếu quang đãng';
      case 2:
        return 'Một phần có mây';
      case 3:
        return 'U ám';
      case 45:
        return 'Sương mù';
      case 48:
        return 'Sương mù đóng băng';
      case 51:
        return 'Mưa phùn nhẹ';
      case 53:
        return 'Mưa phùn vừa';
      case 55:
        return 'Mưa phùn dày đặc';
      case 56:
        return 'Mưa phùn đóng băng nhẹ';
      case 57:
        return 'Mưa phùn đóng băng dày đặc';
      case 61:
        return 'Mưa nhẹ';
      case 63:
        return 'Mưa vừa';
      case 65:
        return 'Mưa nặng';
      case 66:
        return 'Mưa đóng băng nhẹ';
      case 67:
        return 'Mưa đóng băng nặng';
      case 71:
        return 'Tuyết rơi nhẹ';
      case 73:
        return 'Tuyết rơi vừa';
      case 75:
        return 'Tuyết rơi nặng';
      case 77:
        return 'Hạt tuyết';
      case 80:
        return 'Mưa rào nhẹ';
      case 81:
        return 'Mưa rào vừa';
      case 82:
        return 'Mưa rào nặng';
      case 85:
        return 'Tuyết rơi nhẹ';
      case 86:
        return 'Tuyết rơi nặng';
      case 95:
        return 'Dông';
      case 96:
        return 'Dông kèm mưa đá';
      case 99:
        return 'Dông kèm mưa đá nặng';
      default:
        return 'Không xác định';
    }
  }
}

class WeatherData {
  final double temperature;
  final String condition; // "Clear", "Rain", "RainShowers", etc.
  final String description; // Mô tả tiếng Việt
  final int humidity; // Open-Meteo không cung cấp trong current_weather
  final double windSpeed;
  final int weatherCode; // WMO weather code

  WeatherData({
    required this.temperature,
    required this.condition,
    required this.description,
    required this.humidity,
    required this.windSpeed,
    required this.weatherCode,
  });

  bool get isHot => temperature > 32;
  bool get isCold => temperature < 20;
  bool get isRainy => condition.toLowerCase().contains('rain') ||
                      condition.toLowerCase().contains('thunderstorm');
  bool get isSunny => condition == 'Clear';
  bool get isCloudy => condition == 'PartlyCloudy' || condition == 'Overcast';
  bool get isSnowy => condition.toLowerCase().contains('snow');
}

