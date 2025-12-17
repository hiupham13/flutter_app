import '../../../../models/food_model.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/utils/logger.dart';
import '../interfaces/scorer_interfaces.dart';

/// Scores foods based on location proximity
/// Implements ILocationScorer interface (DIP)
class LocationScorer implements ILocationScorer {
  final LocationService _locationService;
  
  LocationScorer({LocationService? locationService})
      : _locationService = locationService ?? LocationService();
  
  /// Get location multiplier based on proximity
  /// Returns 1.0 if location unavailable, higher for closer foods
  @override
  Future<double> getLocationMultiplier(FoodModel food) async {
    try {
      final userLocation = await _locationService.getCurrentLocation();
      if (userLocation == null) {
        // No location available, return neutral
        return 1.0;
      }
      
      // Option 1: If food has coordinates, calculate distance
      // (This would require adding lat/lng to FoodModel)
      
      // Option 2: Simple keyword-based approach
      // Boost foods with location-related keywords
      final locationKeywords = ['gần', 'quanh', 'đây', 'gần đây', 'quanh đây'];
      final hasLocationKeyword = food.searchKeywords.any(
        (keyword) => locationKeywords.any(
          (locationKeyword) => keyword.toLowerCase().contains(locationKeyword),
        ),
      );
      
      if (hasLocationKeyword) {
        AppLogger.debug('📍 Location boost for food: ${food.name}');
        return 1.2; // 20% boost for location-relevant foods
      }
      
      // Option 3: Check map query (if it contains location info)
      if (food.mapQuery.isNotEmpty) {
        // If map query suggests nearby location
        final nearbyIndicators = ['gần', 'quanh', 'đây'];
        final isNearby = nearbyIndicators.any(
          (indicator) => food.mapQuery.toLowerCase().contains(indicator),
        );
        
        if (isNearby) {
          return 1.15; // 15% boost
        }
      }
      
      return 1.0; // Neutral
    } catch (e, st) {
      AppLogger.error('Error calculating location multiplier: $e', e, st);
      return 1.0; // Fail gracefully
    }
  }
  
  /// Get location multipliers for all foods (batch operation)
  @override
  Future<Map<String, double>> getLocationMultipliers(List<FoodModel> foods) async {
    final multipliers = <String, double>{};
    
    try {
      final userLocation = await _locationService.getCurrentLocation();
      if (userLocation == null) {
        // Return neutral multipliers for all
        for (final food in foods) {
          multipliers[food.id] = 1.0;
        }
        return multipliers;
      }
      
      // Calculate multipliers for all foods
      for (final food in foods) {
        multipliers[food.id] = await getLocationMultiplier(food);
      }
      
      return multipliers;
    } catch (e, st) {
      AppLogger.error('Error calculating location multipliers: $e', e, st);
      // Return neutral multipliers on error
      for (final food in foods) {
        multipliers[food.id] = 1.0;
      }
      return multipliers;
    }
  }
  
  /// Pre-calculate location multipliers for all foods
  @override
  Future<Map<String, double>> preCalculateLocationMultipliers(List<FoodModel> foods) async {
    return getLocationMultipliers(foods);
  }
}

