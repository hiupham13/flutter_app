import '../../../../models/food_model.dart';
import '../logic/scoring_engine.dart';

/// Interface for reading food data
/// Follows Interface Segregation Principle (ISP)
abstract class IFoodReadable {
  /// Get all foods
  Future<List<FoodModel>> getAllFoods();
  
  /// Get food by ID
  Future<FoodModel?> getFoodById(String foodId);
  
  /// Search foods by keyword
  Future<List<FoodModel>> searchFoods(String query);
  
  /// Get foods by filters
  Future<List<FoodModel>> getFoodsByFilters({
    int? budget,
    String? cuisineId,
    String? mealTypeId,
    String? keyword,
  });
}

/// Interface for writing food data
abstract class IFoodWritable {
  /// Increment view count
  Future<void> incrementViewCount(String foodId);
  
  /// Increment pick count
  Future<void> incrementPickCount(String foodId);
}

/// Combined interface for food repository
abstract class IFoodRepository implements IFoodReadable, IFoodWritable {
  /// Filter foods locally (client-side)
  List<FoodModel> filterFoodsLocal(
    List<FoodModel> foods, {
    int? budget,
    String? cuisineId,
    String? mealTypeId,
    String? keyword,
  });
  
  /// Force refresh foods
  Future<List<FoodModel>> refreshFoods();
}

/// Interface for history operations
abstract class IHistoryRepository {
  /// Add history entry
  Future<void> addHistory({
    required String userId,
    required FoodModel food,
    required RecommendationContext context,
  });
  
  /// Fetch history food IDs
  Future<List<String>> fetchHistoryFoodIds({
    required String userId,
    int limit = 20,
  });
  
  /// Fetch history food IDs within N days
  Future<List<String>> fetchHistoryFoodIdsWithDays({
    required String userId,
    int days = 7,
  });
  
  /// Add user action
  Future<void> addUserAction({
    required String userId,
    required String foodId,
    required String action,
    RecommendationContext? context,
  });
}

