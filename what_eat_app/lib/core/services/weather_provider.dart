import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'weather_service.dart';
import 'location_service.dart';
import '../utils/logger.dart';

/// Cache duration cho weather data (15 phút)
const Duration _weatherCacheDuration = Duration(minutes: 15);

/// Provider cho LocationService
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Provider cho WeatherService (có thể inject Dio cho testing)
final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService(dio: Dio());
});

/// Provider cho current user location
/// Tự động lấy location khi được watch
final currentLocationProvider = FutureProvider<Position?>((ref) async {
  final locationService = ref.watch(locationServiceProvider);
  return await locationService.getCurrentLocation();
});

/// Global weather provider - loads once, caches for 15 minutes
/// Sử dụng location từ currentLocationProvider và tự động fetch weather
/// Cache được invalidate sau 15 phút
final currentWeatherProvider = FutureProvider<WeatherData?>((ref) async {
  // Watch location provider
  final locationAsync = await ref.watch(currentLocationProvider.future);
  
  if (locationAsync == null) {
    AppLogger.warning('Location not available, cannot fetch weather');
    return null;
  }
  
  // Keep alive for cache duration (15 minutes)
  final link = ref.keepAlive();
  Future.delayed(_weatherCacheDuration, () {
    link.close(); // Invalidate cache after 15 minutes
  });
  
  // Use existing weatherDataProvider family with coordinates
  try {
    final weather = await ref.read(
      weatherDataProvider(
        WeatherCoordinates(
          latitude: locationAsync.latitude,
          longitude: locationAsync.longitude,
        ),
      ).future,
    );
    
    return weather;
  } catch (e, st) {
    AppLogger.error('Error in currentWeatherProvider: $e', e, st);
    return null;
  }
});

/// Coordinates model cho weather provider family
class WeatherCoordinates {
  final double latitude;
  final double longitude;

  const WeatherCoordinates({
    required this.latitude,
    required this.longitude,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeatherCoordinates &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
}

/// Provider cho weather data với caching
/// Tự động fetch và cache weather data theo tọa độ
/// Cache TTL: 30 phút (Riverpod tự động cache, invalidate sau 30 phút)
final weatherDataProvider = FutureProvider.family<WeatherData?, WeatherCoordinates>(
  (ref, coordinates) async {
    final weatherService = ref.watch(weatherServiceProvider);
    
    // Keep alive for 30 minutes
    final link = ref.keepAlive();
    Future.delayed(const Duration(minutes: 30), () {
      link.close();
    });
    
    try {
      final weather = await weatherService.getWeatherByCoordinates(
        coordinates.latitude,
        coordinates.longitude,
      );
      
      return weather;
    } catch (e, st) {
      AppLogger.error('Error fetching weather in provider: $e', e, st);
      return null;
    }
  },
);

/// StateNotifier để quản lý weather state với manual refresh
class WeatherNotifier extends StateNotifier<AsyncValue<WeatherData?>> {
  final WeatherService _weatherService;
  WeatherCoordinates? _lastCoordinates;

  WeatherNotifier(this._weatherService) : super(const AsyncValue.loading());

  /// Fetch weather data
  Future<void> fetchWeather(double latitude, double longitude) async {
    _lastCoordinates = WeatherCoordinates(
      latitude: latitude,
      longitude: longitude,
    );

    state = const AsyncValue.loading();

    try {
      final weather = await _weatherService.getWeatherByCoordinates(
        latitude,
        longitude,
      );
      state = AsyncValue.data(weather);
    } catch (e, st) {
      AppLogger.error('Error in WeatherNotifier: $e', e, st);
      state = AsyncValue.error(e, st);
    }
  }

  /// Refresh weather data (force fetch)
  Future<void> refresh() async {
    if (_lastCoordinates != null) {
      await fetchWeather(
        _lastCoordinates!.latitude,
        _lastCoordinates!.longitude,
      );
    }
  }

  /// Clear weather data
  void clear() {
    state = const AsyncValue.data(null);
    _lastCoordinates = null;
  }
}

/// Provider cho WeatherNotifier
final weatherNotifierProvider = StateNotifierProvider<WeatherNotifier, AsyncValue<WeatherData?>>(
  (ref) {
    final weatherService = ref.watch(weatherServiceProvider);
    return WeatherNotifier(weatherService);
  },
);

