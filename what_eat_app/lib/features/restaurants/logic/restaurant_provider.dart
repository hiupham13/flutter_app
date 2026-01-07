import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/restaurant_model.dart';
import '../data/restaurant_repository.dart';

/// Provider for restaurant repository
final restaurantRepositoryProvider = Provider<RestaurantRepository>((ref) {
  return RestaurantRepository();
});

/// Provider for nearby restaurants
final nearbyRestaurantsProvider = FutureProvider<List<RestaurantModel>>((ref) async {
  final repository = ref.watch(restaurantRepositoryProvider);
  return repository.getNearbyRestaurants();
});

/// Provider for all restaurants (without distance calculation)
final allRestaurantsProvider = FutureProvider<List<RestaurantModel>>((ref) async {
  final repository = ref.watch(restaurantRepositoryProvider);
  return repository.loadRestaurants();
});

/// Provider for restaurant by ID
final restaurantByIdProvider = FutureProvider.family<RestaurantModel?, String>((ref, id) async {
  final repository = ref.watch(restaurantRepositoryProvider);
  return repository.getRestaurantById(id);
});

/// Provider for search restaurants
final searchRestaurantsProvider = FutureProvider.family<List<RestaurantModel>, String>((ref, query) async {
  final repository = ref.watch(restaurantRepositoryProvider);
  if (query.isEmpty) {
    return repository.loadRestaurants();
  }
  return repository.searchRestaurants(query);
});

