import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/rewards_constants.dart';
import '../../../core/utils/logger.dart';

/// Result of location verification
class LocationVerificationResult {
  final bool isVerified;
  final String? reason;
  final double? distanceMeters;
  final Duration? timeAtLocation;

  const LocationVerificationResult({
    required this.isVerified,
    this.reason,
    this.distanceMeters,
    this.timeAtLocation,
  });

  factory LocationVerificationResult.verified({
    required double distanceMeters,
    required Duration timeAtLocation,
  }) {
    return LocationVerificationResult(
      isVerified: true,
      distanceMeters: distanceMeters,
      timeAtLocation: timeAtLocation,
    );
  }

  factory LocationVerificationResult.failed(String reason) {
    return LocationVerificationResult(
      isVerified: false,
      reason: reason,
    );
  }
}

/// Service for verifying user location at restaurant
class LocationVerificationService {
  /// Singleton instance
  static final LocationVerificationService _instance =
      LocationVerificationService._internal();
  factory LocationVerificationService() => _instance;
  LocationVerificationService._internal();

  /// Current verification session
  _VerificationSession? _currentSession;

  // ============================================================================
  // PERMISSION HANDLING
  // ============================================================================

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      AppLogger.error('Check location service failed: $e');
      return false;
    }
  }

  /// Check location permission status
  Future<LocationPermission> checkPermission() async {
    try {
      return await Geolocator.checkPermission();
    } catch (e) {
      AppLogger.error('Check permission failed: $e');
      return LocationPermission.denied;
    }
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    try {
      return await Geolocator.requestPermission();
    } catch (e) {
      AppLogger.error('Request permission failed: $e');
      return LocationPermission.denied;
    }
  }

  /// Ensure we have location permission
  Future<bool> ensureLocationPermission() async {
    // Check if location service is enabled
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      AppLogger.warning('Location service is disabled');
      return false;
    }

    // Check permission
    LocationPermission permission = await checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        AppLogger.warning('Location permission denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      AppLogger.warning('Location permission denied forever');
      return false;
    }

    return true;
  }

  // ============================================================================
  // LOCATION TRACKING
  // ============================================================================

  /// Get current position
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await ensureLocationPermission();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      AppLogger.error('Get current position failed: $e');
      return null;
    }
  }

  /// Calculate distance between two coordinates (in meters)
  double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  // ============================================================================
  // VERIFICATION SESSION
  // ============================================================================

  /// Start verification session for a restaurant visit
  Future<bool> startVerificationSession({
    required double restaurantLat,
    required double restaurantLon,
    required String restaurantId,
  }) async {
    // Stop any existing session
    stopVerificationSession();

    // Get current position
    final position = await getCurrentPosition();
    if (position == null) {
      AppLogger.warning('Cannot start verification: no position');
      return false;
    }

    // Check if user is near restaurant
    final distance = calculateDistance(
      lat1: position.latitude,
      lon1: position.longitude,
      lat2: restaurantLat,
      lon2: restaurantLon,
    );

    if (distance > RewardsConstants.maximumDistanceMeters) {
      AppLogger.warning(
          'User too far from restaurant: ${distance.toStringAsFixed(0)}m');
      return false;
    }

    // Create session
    _currentSession = _VerificationSession(
      restaurantId: restaurantId,
      restaurantLat: restaurantLat,
      restaurantLon: restaurantLon,
      startTime: DateTime.now(),
      startPosition: position,
    );

    AppLogger.info('Verification session started for restaurant: $restaurantId');

    return true;
  }

  /// Stop current verification session
  void stopVerificationSession() {
    if (_currentSession != null) {
      AppLogger.info('Verification session stopped');
      _currentSession = null;
    }
  }

  /// Verify if user completed the visit (automatic check)
  Future<LocationVerificationResult> verifyVisit() async {
    if (_currentSession == null) {
      return LocationVerificationResult.failed('No active session');
    }

    final session = _currentSession!;

    // Get current position
    final currentPosition = await getCurrentPosition();
    if (currentPosition == null) {
      return LocationVerificationResult.failed('Cannot get current position');
    }

    // Check distance from restaurant
    final distance = calculateDistance(
      lat1: currentPosition.latitude,
      lon1: currentPosition.longitude,
      lat2: session.restaurantLat,
      lon2: session.restaurantLon,
    );

    // Check if still within range
    if (distance > RewardsConstants.maximumDistanceMeters) {
      return LocationVerificationResult.failed(
        'Too far from restaurant: ${distance.toStringAsFixed(0)}m',
      );
    }

    // Check time at location
    final timeAtLocation = DateTime.now().difference(session.startTime);

    if (timeAtLocation.inMinutes <
        RewardsConstants.minimumTimeAtLocationMinutes) {
      return LocationVerificationResult.failed(
        'Not enough time at location: ${timeAtLocation.inMinutes} minutes',
      );
    }

    // Verification successful!
    final result = LocationVerificationResult.verified(
      distanceMeters: distance,
      timeAtLocation: timeAtLocation,
    );

    // Clear session
    stopVerificationSession();

    AppLogger.info(
        'Visit verified: ${distance.toStringAsFixed(0)}m, ${timeAtLocation.inMinutes}min');

    return result;
  }

  /// Quick verification (manual trigger)
  /// Use this when user explicitly claims "I'm here"
  Future<LocationVerificationResult> quickVerify({
    required double restaurantLat,
    required double restaurantLon,
  }) async {
    final position = await getCurrentPosition();
    if (position == null) {
      return LocationVerificationResult.failed('Cannot get location');
    }

    final distance = calculateDistance(
      lat1: position.latitude,
      lon1: position.longitude,
      lat2: restaurantLat,
      lon2: restaurantLon,
    );

    // Check if within acceptable range
    if (distance < RewardsConstants.minimumDistanceMeters) {
      return LocationVerificationResult.failed(
        'Too close - GPS accuracy issue: ${distance.toStringAsFixed(0)}m',
      );
    }

    if (distance > RewardsConstants.maximumDistanceMeters) {
      return LocationVerificationResult.failed(
        'Too far from restaurant: ${distance.toStringAsFixed(0)}m',
      );
    }

    // Quick verification successful
    return LocationVerificationResult.verified(
      distanceMeters: distance,
      timeAtLocation: Duration.zero, // No time check for quick verify
    );
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Check if user is currently near a restaurant
  Future<bool> isNearRestaurant({
    required double restaurantLat,
    required double restaurantLon,
  }) async {
    final position = await getCurrentPosition();
    if (position == null) return false;

    final distance = calculateDistance(
      lat1: position.latitude,
      lon1: position.longitude,
      lat2: restaurantLat,
      lon2: restaurantLon,
    );

    return distance <= RewardsConstants.maximumDistanceMeters;
  }

  /// Get current session info (for debugging)
  _VerificationSession? get currentSession => _currentSession;

  /// Check if session is active
  bool get hasActiveSession => _currentSession != null;
}

/// Internal class to track verification session
class _VerificationSession {
  final String restaurantId;
  final double restaurantLat;
  final double restaurantLon;
  final DateTime startTime;
  final Position startPosition;

  _VerificationSession({
    required this.restaurantId,
    required this.restaurantLat,
    required this.restaurantLon,
    required this.startTime,
    required this.startPosition,
  });

  Duration get duration => DateTime.now().difference(startTime);
}
