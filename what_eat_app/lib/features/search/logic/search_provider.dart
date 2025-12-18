import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import '../../../models/food_model.dart';
import '../../../core/utils/logger.dart';
import '../../recommendation/interfaces/repository_interfaces.dart';
import '../../recommendation/logic/recommendation_provider.dart';

// Search State
class SearchState {
  final String query;
  final Set<int> selectedPriceSegments;
  final Set<String> selectedCuisines;
  final Set<String> selectedMealTypes;
  final Set<String> excludedAllergens;
  final String sortBy;
  final List<FoodModel> results;
  final bool isLoading;
  final String? error;

  const SearchState({
    this.query = '',
    this.selectedPriceSegments = const {},
    this.selectedCuisines = const {},
    this.selectedMealTypes = const {},
    this.excludedAllergens = const {},
    this.sortBy = 'relevance',
    this.results = const [],
    this.isLoading = false,
    this.error,
  });

  int get activeFilterCount =>
      selectedPriceSegments.length +
      selectedCuisines.length +
      selectedMealTypes.length +
      excludedAllergens.length;

  SearchState copyWith({
    String? query,
    Set<int>? selectedPriceSegments,
    Set<String>? selectedCuisines,
    Set<String>? selectedMealTypes,
    Set<String>? excludedAllergens,
    String? sortBy,
    List<FoodModel>? results,
    bool? isLoading,
    String? error,
  }) {
    return SearchState(
      query: query ?? this.query,
      selectedPriceSegments: selectedPriceSegments ?? this.selectedPriceSegments,
      selectedCuisines: selectedCuisines ?? this.selectedCuisines,
      selectedMealTypes: selectedMealTypes ?? this.selectedMealTypes,
      excludedAllergens: excludedAllergens ?? this.excludedAllergens,
      sortBy: sortBy ?? this.sortBy,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Search Controller
class SearchController extends StateNotifier<SearchState> {
  SearchController(this._foodRepository) : super(const SearchState()) {
    _init();
  }

  final IFoodRepository _foodRepository;
  List<FoodModel> _allFoods = [];

  Future<void> _init() async {
    try {
      _allFoods = await _foodRepository.getAllFoods();
    } catch (e, st) {
      // Standardized error handling: Log + Crashlytics
      AppLogger.error('Error initializing search: $e', e, st);
      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'Search initialization failed',
        fatal: false,
      );
      state = state.copyWith(error: 'Lỗi khi tải dữ liệu tìm kiếm: $e');
    }
  }

  void updateQuery(String query) {
    state = state.copyWith(query: query);
    _performSearch();
  }

  void togglePriceFilter(int price) {
    final newSet = Set<int>.from(state.selectedPriceSegments);
    if (newSet.contains(price)) {
      newSet.remove(price);
    } else {
      newSet.add(price);
    }
    state = state.copyWith(selectedPriceSegments: newSet);
    _performSearch();
  }

  void toggleCuisineFilter(String cuisine) {
    final newSet = Set<String>.from(state.selectedCuisines);
    if (newSet.contains(cuisine)) {
      newSet.remove(cuisine);
    } else {
      newSet.add(cuisine);
    }
    state = state.copyWith(selectedCuisines: newSet);
    _performSearch();
  }

  void toggleMealTypeFilter(String mealType) {
    final newSet = Set<String>.from(state.selectedMealTypes);
    if (newSet.contains(mealType)) {
      newSet.remove(mealType);
    } else {
      newSet.add(mealType);
    }
    state = state.copyWith(selectedMealTypes: newSet);
    _performSearch();
  }

  void toggleAllergenFilter(String allergen) {
    final newSet = Set<String>.from(state.excludedAllergens);
    if (newSet.contains(allergen)) {
      newSet.remove(allergen);
    } else {
      newSet.add(allergen);
    }
    state = state.copyWith(excludedAllergens: newSet);
    _performSearch();
  }

  void updateSort(String sortBy) {
    state = state.copyWith(sortBy: sortBy);
    _performSearch();
  }

  void clearAllFilters() {
    state = state.copyWith(
      selectedPriceSegments: const {},
      selectedCuisines: const {},
      selectedMealTypes: const {},
      excludedAllergens: const {},
    );
    _performSearch();
  }

  void _performSearch() {
    state = state.copyWith(isLoading: true);

    try {
      var results = List<FoodModel>.from(_allFoods);

      // Filter by search query
      if (state.query.isNotEmpty) {
        final queryLower = state.query.toLowerCase();
        results = results.where((food) {
          return food.name.toLowerCase().contains(queryLower) ||
              food.searchKeywords.any((keyword) =>
                  keyword.toLowerCase().contains(queryLower)) ||
              food.cuisineId.toLowerCase().contains(queryLower) ||
              food.mealTypeId.toLowerCase().contains(queryLower);
        }).toList();
      }

      // Filter by price
      if (state.selectedPriceSegments.isNotEmpty) {
        results = results.where((food) {
          return state.selectedPriceSegments.contains(food.priceSegment);
        }).toList();
      }

      // Filter by cuisine
      if (state.selectedCuisines.isNotEmpty) {
        results = results.where((food) {
          return state.selectedCuisines.contains(food.cuisineId);
        }).toList();
      }

      // Filter by meal type
      if (state.selectedMealTypes.isNotEmpty) {
        results = results.where((food) {
          return state.selectedMealTypes.contains(food.mealTypeId);
        }).toList();
      }

      // Exclude allergens
      if (state.excludedAllergens.isNotEmpty) {
        results = results.where((food) {
          return !food.allergenTags
              .any((allergen) => state.excludedAllergens.contains(allergen));
        }).toList();
      }

      // Sort results
      _sortResults(results);

      state = state.copyWith(
        results: results,
        isLoading: false,
        error: null,
      );
    } catch (e, st) {
      // Standardized error handling: Log + Crashlytics
      AppLogger.error('Error performing search: $e', e, st);
      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'Search failed',
        fatal: false,
      );
      state = state.copyWith(
        isLoading: false,
        error: 'Lỗi khi tìm kiếm: $e',
      );
    }
  }

  void _sortResults(List<FoodModel> foods) {
    switch (state.sortBy) {
      case 'price_low':
        foods.sort((a, b) => a.priceSegment.compareTo(b.priceSegment));
        break;
      case 'price_high':
        foods.sort((a, b) => b.priceSegment.compareTo(a.priceSegment));
        break;
      case 'popular':
        foods.sort((a, b) => b.viewCount.compareTo(a.viewCount));
        break;
      case 'relevance':
      default:
        // If there's a query, sort by name similarity
        if (state.query.isNotEmpty) {
          final queryLower = state.query.toLowerCase();
          foods.sort((a, b) {
            final aStartsWith = a.name.toLowerCase().startsWith(queryLower);
            final bStartsWith = b.name.toLowerCase().startsWith(queryLower);
            if (aStartsWith && !bStartsWith) return -1;
            if (!aStartsWith && bStartsWith) return 1;
            return a.name.compareTo(b.name);
          });
        }
        break;
    }
  }

  // Helper methods to get available filter options
  Future<List<String>> getAvailableCuisines() async {
    final cuisines = _allFoods.map((food) => food.cuisineId).toSet().toList();
    cuisines.sort();
    return cuisines;
  }

  Future<List<String>> getAvailableMealTypes() async {
    final mealTypes = _allFoods.map((food) => food.mealTypeId).toSet().toList();
    mealTypes.sort();
    return mealTypes;
  }

  Future<List<String>> getAvailableAllergens() async {
    final allergens = <String>{};
    for (final food in _allFoods) {
      allergens.addAll(food.allergenTags);
    }
    final list = allergens.toList();
    list.sort();
    return list;
  }
}

// Provider
final searchProvider = StateNotifierProvider<SearchController, SearchState>((ref) {
  final foodRepository = ref.watch(foodRepositoryProvider);
  return SearchController(foodRepository);
});