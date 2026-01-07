import 'dart:convert';
import 'package:flutter/services.dart';
import '../../../models/restaurant_model.dart';
import '../../../core/services/location_service.dart';
import '../../../core/utils/logger.dart';
import 'package:geolocator/geolocator.dart';

/// Repository for loading fake restaurant data (Level 1 - Zero Cost)
class RestaurantRepository {
  final LocationService _locationService;
  List<RestaurantModel>? _cachedRestaurants;

  RestaurantRepository({LocationService? locationService})
      : _locationService = locationService ?? LocationService();

  /// Load restaurants from JSON file (fake data)
  Future<List<RestaurantModel>> loadRestaurants() async {
    try {
      // Return cached if available
      if (_cachedRestaurants != null) {
        return _cachedRestaurants!;
      }

      // Load from JSON asset
      final String jsonString =
          await rootBundle.loadString('assets/data/restaurants.json');
      final List<dynamic> jsonList = json.decode(jsonString);

      _cachedRestaurants = jsonList
          .map((json) => RestaurantModel.fromJson(json as Map<String, dynamic>))
          .toList();

      AppLogger.info('Loaded ${_cachedRestaurants!.length} restaurants from JSON');

      return _cachedRestaurants!;
    } catch (e, st) {
      AppLogger.error('Error loading restaurants: $e', e, st);
      return [];
    }
  }

  /// Get restaurants with calculated distances from user location
  Future<List<RestaurantModel>> getNearbyRestaurants({
    double? userLat,
    double? userLng,
    double maxDistanceKm = 10.0,
  }) async {
    try {
      // Load restaurants
      final restaurants = await loadRestaurants();

      // Get user location if not provided
      Position? userPosition;
      if (userLat == null || userLng == null) {
        userPosition = await _locationService.getCurrentLocation();
        if (userPosition == null) {
          // No location, return all restaurants without distance
          return restaurants;
        }
        userLat = userPosition.latitude;
        userLng = userPosition.longitude;
      }

      // Calculate distances and filter
      final nearbyRestaurants = <RestaurantModel>[];

      for (final restaurant in restaurants) {
        final distanceMeters = Geolocator.distanceBetween(
          userLat,
          userLng,
          restaurant.latitude,
          restaurant.longitude,
        );

        final distanceKm = distanceMeters / 1000;

        // Filter by max distance
        if (distanceKm <= maxDistanceKm) {
          final distanceDisplay = _formatDistance(distanceMeters);
          nearbyRestaurants.add(
            restaurant.copyWithDistance(
              distanceMeters: distanceMeters,
              distanceDisplay: distanceDisplay,
            ),
          );
        }
      }

      // Sort by distance (closest first)
      nearbyRestaurants.sort((a, b) {
        final distA = a.distanceMeters ?? double.infinity;
        final distB = b.distanceMeters ?? double.infinity;
        return distA.compareTo(distB);
      });

      AppLogger.info(
          'Found ${nearbyRestaurants.length} nearby restaurants within ${maxDistanceKm}km');

      return nearbyRestaurants;
    } catch (e, st) {
      AppLogger.error('Error getting nearby restaurants: $e', e, st);
      return [];
    }
  }

  /// Get restaurant by ID
  Future<RestaurantModel?> getRestaurantById(String id) async {
    try {
      final restaurants = await loadRestaurants();
      return restaurants.firstWhere(
        (r) => r.id == id,
        orElse: () => throw Exception('Restaurant not found'),
      );
    } catch (e) {
      AppLogger.error('Error getting restaurant by ID: $e');
      return null;
    }
  }

  /// Search restaurants by name or cuisine
  Future<List<RestaurantModel>> searchRestaurants(String query) async {
    try {
      final restaurants = await loadRestaurants();
      final lowerQuery = query.toLowerCase();

      return restaurants.where((restaurant) {
        // Search in name
        if (restaurant.name.toLowerCase().contains(lowerQuery)) {
          return true;
        }

        // Search in cuisines
        if (restaurant.cuisines.any(
            (cuisine) => cuisine.toLowerCase().contains(lowerQuery))) {
          return true;
        }

        // Search in description
        if (restaurant.description != null &&
            restaurant.description!.toLowerCase().contains(lowerQuery)) {
          return true;
        }

        return false;
      }).toList();
    } catch (e, st) {
      AppLogger.error('Error searching restaurants: $e', e, st);
      return [];
    }
  }

  /// Format distance for display
  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)}m';
    } else {
      final km = meters / 1000;
      return '${km.toStringAsFixed(1)}km';
    }
  }

  /// Clear cache (for testing or refresh)
  void clearCache() {
    _cachedRestaurants = null;
  }
}

