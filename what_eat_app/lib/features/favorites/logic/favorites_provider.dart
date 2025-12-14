import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/food_model.dart';
import '../data/favorites_repository.dart';
import '../../auth/logic/auth_provider.dart';
import '../../recommendation/data/repositories/food_repository.dart';

/// Provider for FavoritesRepository
final favoritesRepositoryProvider = Provider<FavoritesRepository?>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return authState.when(
    data: (user) => user != null ? FavoritesRepository(userId: user.uid) : null,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Stream provider for favorite food IDs
final favoriteFoodIdsProvider = StreamProvider<List<String>>((ref) {
  final repository = ref.watch(favoritesRepositoryProvider);
  
  if (repository == null) {
    return Stream.value([]);
  }
  
  return repository.watchFavorites();
});

/// Provider for favorite foods with full details
final favoriteFoodsProvider = FutureProvider<List<FoodModel>>((ref) async {
  final favoriteIds = await ref.watch(favoriteFoodIdsProvider.future);
  
  if (favoriteIds.isEmpty) {
    return [];
  }
  
  // Get all foods and filter by favorite IDs
  final foodRepo = ref.watch(foodRepositoryProvider);
  final allFoods = await foodRepo.getAllFoods();
  
  return allFoods.where((food) => favoriteIds.contains(food.id)).toList();
});

/// Controller for favorites operations
final favoritesControllerProvider = Provider<FavoritesController>((ref) {
  return FavoritesController(ref);
});

class FavoritesController {
  final Ref _ref;
  
  FavoritesController(this._ref);
  
  /// Add food to favorites
  Future<void> addFavorite(String foodId) async {
    final repository = _ref.read(favoritesRepositoryProvider);
    if (repository == null) {
      throw Exception('User not authenticated');
    }
    
    await repository.addFavorite(foodId);
  }
  
  /// Remove food from favorites
  Future<void> removeFavorite(String foodId) async {
    final repository = _ref.read(favoritesRepositoryProvider);
    if (repository == null) {
      throw Exception('User not authenticated');
    }
    
    await repository.removeFavorite(foodId);
  }
  
  /// Toggle favorite status
  Future<void> toggleFavorite(String foodId) async {
    final repository = _ref.read(favoritesRepositoryProvider);
    if (repository == null) {
      throw Exception('User not authenticated');
    }
    
    await repository.toggleFavorite(foodId);
  }
  
  /// Check if food is favorited
  Future<bool> isFavorite(String foodId) async {
    final repository = _ref.read(favoritesRepositoryProvider);
    if (repository == null) {
      return false;
    }
    
    return repository.isFavorite(foodId);
  }
  
  /// Clear all favorites
  Future<void> clearAll() async {
    final repository = _ref.read(favoritesRepositoryProvider);
    if (repository == null) {
      throw Exception('User not authenticated');
    }
    
    await repository.clearAllFavorites();
  }
}