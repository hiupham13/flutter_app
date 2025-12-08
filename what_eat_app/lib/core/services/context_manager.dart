import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/weather_service.dart';
import '../services/location_service.dart';
import '../services/time_manager.dart';
import '../../features/recommendation/logic/scoring_engine.dart';

/// Service tổng hợp tất cả context (weather, location, time) thành RecommendationContext
class ContextManager {
  final WeatherService _weatherService;
  final LocationService _locationService;
  final TimeManager _timeManager;

  ContextManager({
    WeatherService? weatherService,
    LocationService? locationService,
    TimeManager? timeManager,
  })  : _weatherService = weatherService ?? WeatherService(),
        _locationService = locationService ?? LocationService(),
        _timeManager = timeManager ?? TimeManager();

  /// Tổng hợp context hiện tại (weather, time, location)
  /// và trả về RecommendationContext với user input
  Future<RecommendationContext> getCurrentContext({
    required int budget,
    required String companion,
    String? mood,
    List<String> excludedFoods = const [],
    List<String> excludedAllergens = const [],
    List<String> favoriteCuisines = const [],
    List<String> recentlyEaten = const [],
    List<String> blacklistedFoods = const [],
    bool isVegetarian = false,
    int spiceTolerance = 2,
  }) async {
    // Lấy location
    final position = await _locationService.getCurrentLocation();

    // Lấy weather nếu có location
    WeatherData? weather;
    if (position != null) {
      weather = await _weatherService.getWeatherByCoordinates(
        position.latitude,
        position.longitude,
      );
    }

    // Xác định time of day đã được xử lý trong scoring engine
    // (không cần truyền vào context vì đã được xử lý trong availableTimes filter)

    return RecommendationContext(
      weather: weather,
      budget: budget,
      companion: companion,
      mood: mood,
      excludedFoods: excludedFoods,
      excludedAllergens: excludedAllergens,
      favoriteCuisines: favoriteCuisines,
      recentlyEaten: recentlyEaten,
      blacklistedFoods: blacklistedFoods,
      isVegetarian: isVegetarian,
      spiceTolerance: spiceTolerance,
    );
  }

  /// Lấy context summary để hiển thị trên UI
  Future<ContextSummary> getContextSummary() async {
    final position = await _locationService.getCurrentLocation();
    WeatherData? weather;
    
    if (position != null) {
      weather = await _weatherService.getWeatherByCoordinates(
        position.latitude,
        position.longitude,
      );
    }

    final timeOfDay = _timeManager.getTimeOfDay();
    final timeLabel = _timeManager.getTimeOfDayLabel(timeOfDay);

    return ContextSummary(
      weather: weather,
      timeOfDay: timeOfDay,
      timeLabel: timeLabel,
      location: position != null
          ? '${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}'
          : null,
    );
  }
}

/// Summary của context để hiển thị trên UI
class ContextSummary {
  final WeatherData? weather;
  final String timeOfDay;
  final String timeLabel;
  final String? location;

  ContextSummary({
    this.weather,
    required this.timeOfDay,
    required this.timeLabel,
    this.location,
  });
}

// Providers
final timeManagerProvider = Provider<TimeManager>((ref) => TimeManager());

final contextManagerProvider = Provider<ContextManager>((ref) {
  return ContextManager(
    weatherService: WeatherService(),
    locationService: LocationService(),
    timeManager: ref.watch(timeManagerProvider),
  );
});

