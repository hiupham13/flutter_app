import 'package:flutter_test/flutter_test.dart';
import 'package:what_eat_app/features/recommendation/data/repositories/food_repository.dart';
import 'package:what_eat_app/features/recommendation/data/sources/food_firestore_service.dart';
import 'package:what_eat_app/models/food_model.dart';

FoodModel buildFood({
  String id = 'pho_bo',
  int priceSegment = 2,
  String cuisineId = 'vn',
  String mealTypeId = 'soup',
  List<String> searchKeywords = const [],
}) {
  return FoodModel(
    id: id,
    name: id,
    searchKeywords: searchKeywords,
    description: '',
    images: const [],
    cuisineId: cuisineId,
    mealTypeId: mealTypeId,
    flavorProfile: const [],
    allergenTags: const [],
    priceSegment: priceSegment,
    avgCalories: null,
    availableTimes: const [],
    contextScores: const {},
    mapQuery: id,
    isActive: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    viewCount: 0,
    pickCount: 0,
  );
}

class _FakeFoodService implements FoodDataSource {
  @override
  Future<List<FoodModel>> fetchAllFoods() async => [];

  @override
  Future<FoodModel?> fetchFoodById(String foodId) async => null;

  @override
  Future<void> incrementPickCount(String foodId) async {}

  @override
  Future<void> incrementViewCount(String foodId) async {}

  @override
  Future<List<FoodModel>> fetchFoodsByFilters({
    int? budget,
    String? cuisineId,
    String? mealTypeId,
    String? keyword,
  }) async =>
      [];

  @override
  Future<List<FoodModel>> searchFoods(String query) async => [];
}

void main() {
  final repo = FoodRepository(dataSource: _FakeFoodService());

  test('Filter by cuisine and budget', () {
    final foods = [
      buildFood(id: 'pho', cuisineId: 'vn', priceSegment: 2),
      buildFood(id: 'ramen', cuisineId: 'jp', priceSegment: 3),
    ];

    final result = repo.filterFoodsLocal(foods, cuisineId: 'vn', budget: 2);
    expect(result.length, 1);
    expect(result.first.id, 'pho');
  });

  test('Search by keyword', () {
    final foods = [
      buildFood(id: 'banh_mi', searchKeywords: const ['banh mi']),
      buildFood(id: 'com_tam', searchKeywords: const ['broken rice']),
    ];

    final result = repo.filterFoodsLocal(foods, keyword: 'broken');
    expect(result.length, 1);
    expect(result.first.id, 'com_tam');
  });
}

