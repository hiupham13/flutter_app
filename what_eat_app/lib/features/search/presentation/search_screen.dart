import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/food_image_card.dart';
import '../../../core/widgets/price_badge.dart';
import '../../../models/food_model.dart';

import '../../recommendation/logic/scoring_engine.dart';
import '../logic/search_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Tìm món ăn...',
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          style: Theme.of(context).textTheme.titleMedium,
          onChanged: (value) {
            ref.read(searchProvider.notifier).updateQuery(value);
          },
        ),
        actions: [
          // Filter button
          IconButton(
            icon: Badge(
              label: Text(ref.watch(searchProvider).activeFilterCount.toString()),
              isLabelVisible: searchState.activeFilterCount > 0,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: () => _showFilterDialog(context),
          ),
          // Clear search
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                ref.read(searchProvider.notifier).updateQuery('');
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Active filters chips
          if (searchState.activeFilterCount > 0)
            _buildActiveFiltersChips(),
          
          // Sort options
          _buildSortBar(),
          
          // Search results
          Expanded(
            child: _buildSearchResults(searchState),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFiltersChips() {
    final searchState = ref.watch(searchProvider);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Price filters
          ...searchState.selectedPriceSegments.map((price) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(_getPriceLabel(price)),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () {
                  ref.read(searchProvider.notifier).togglePriceFilter(price);
                },
              ),
            );
          }),
          
          // Cuisine filters
          ...searchState.selectedCuisines.map((cuisine) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(cuisine),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () {
                  ref.read(searchProvider.notifier).toggleCuisineFilter(cuisine);
                },
              ),
            );
          }),
          
          // Meal type filters
          ...searchState.selectedMealTypes.map((mealType) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(mealType),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () {
                  ref.read(searchProvider.notifier).toggleMealTypeFilter(mealType);
                },
              ),
            );
          }),
          
          // Clear all button
          TextButton.icon(
            onPressed: () {
              ref.read(searchProvider.notifier).clearAllFilters();
            },
            icon: const Icon(Icons.clear_all, size: 18),
            label: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );
  }

  Widget _buildSortBar() {
    final searchState = ref.watch(searchProvider);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          const Text('Sắp xếp:'),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSortChip('Liên quan', 'relevance', searchState.sortBy),
                  const SizedBox(width: 8),
                  _buildSortChip('Giá thấp', 'price_low', searchState.sortBy),
                  const SizedBox(width: 8),
                  _buildSortChip('Giá cao', 'price_high', searchState.sortBy),
                  const SizedBox(width: 8),
                  _buildSortChip('Phổ biến', 'popular', searchState.sortBy),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, String value, String currentSort) {
    final isSelected = currentSort == value;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          ref.read(searchProvider.notifier).updateSort(value);
        }
      },
    );
  }

  Widget _buildSearchResults(SearchState searchState) {
    if (searchState.isLoading) {
      return const LoadingIndicator();
    }
    
    if (searchState.error != null) {
      return Center(
        child: Text('Lỗi: ${searchState.error}'),
      );
    }
    
    final results = searchState.results;
    
    if (_searchController.text.isEmpty && searchState.activeFilterCount == 0) {
      return EmptyStateWidget(
        title: 'Tìm kiếm món ăn yêu thích',
        message: 'Nhập tên món hoặc sử dụng bộ lọc',
        illustration: Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.search,
            size: 40,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }
    
    if (results.isEmpty) {
      return EmptyStateWidget(
        title: 'Không tìm thấy kết quả',
        message: 'Thử từ khóa khác hoặc điều chỉnh bộ lọc',
        illustration: Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.search_off,
            size: 40,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final food = results[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: FoodImageCard(
            imageUrl: food.images.isNotEmpty ? food.images.first : '',
            title: food.name,
            subtitle: '${food.cuisineId} • ${food.mealTypeId}',
            priceBadge: PriceBadge(level: _mapPrice(food.priceSegment)),
            tags: food.flavorProfile.take(3).toList(),
            heroTag: 'search_${food.id}',
            onTap: () => _navigateToDetail(food),
          ),
        );
      },
    );
  }

  void _showFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const SearchFilterDialog(),
    );
  }

  void _navigateToDetail(FoodModel food) {
    final ctx = RecommendationContext(
      budget: food.priceSegment,
      companion: 'alone',
    );
    
    context.pushNamed(
      'result',
      extra: {
        'food': food,
        'context': ctx,
      },
    );
  }

  String _getPriceLabel(int price) {
    switch (price) {
      case 1:
        return 'Rẻ';
      case 2:
        return 'Vừa';
      case 3:
        return 'Sang';
      default:
        return '';
    }
  }

  PriceLevel _mapPrice(int segment) {
    switch (segment) {
      case 1:
        return PriceLevel.low;
      case 3:
        return PriceLevel.high;
      case 2:
      default:
        return PriceLevel.medium;
    }
  }
}

// Filter Dialog Widget
class SearchFilterDialog extends ConsumerWidget {
  const SearchFilterDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(searchProvider);
    
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bộ Lọc',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(searchProvider.notifier).clearAllFilters();
                    },
                    child: const Text('Xóa tất cả'),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Filter content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Price segment filter
                    _buildFilterSection(
                      context,
                      title: 'Mức Giá',
                      child: Wrap(
                        spacing: 8,
                        children: [1, 2, 3].map((price) {
                          final isSelected = searchState.selectedPriceSegments.contains(price);
                          return FilterChip(
                            label: Text(_getPriceLabel(price)),
                            selected: isSelected,
                            onSelected: (selected) {
                              ref.read(searchProvider.notifier).togglePriceFilter(price);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    
                    const Divider(height: 32),
                    
                    // Cuisine filter
                    _buildFilterSection(
                      context,
                      title: 'Ẩm Thực',
                      child: FutureBuilder<List<String>>(
                        future: ref.read(searchProvider.notifier).getAvailableCuisines(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox.shrink();
                          
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: snapshot.data!.map((cuisine) {
                              final isSelected = searchState.selectedCuisines.contains(cuisine);
                              return FilterChip(
                                label: Text(cuisine),
                                selected: isSelected,
                                onSelected: (selected) {
                                  ref.read(searchProvider.notifier).toggleCuisineFilter(cuisine);
                                },
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),
                    
                    const Divider(height: 32),
                    
                    // Meal type filter
                    _buildFilterSection(
                      context,
                      title: 'Bữa Ăn',
                      child: FutureBuilder<List<String>>(
                        future: ref.read(searchProvider.notifier).getAvailableMealTypes(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox.shrink();
                          
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: snapshot.data!.map((mealType) {
                              final isSelected = searchState.selectedMealTypes.contains(mealType);
                              return FilterChip(
                                label: Text(mealType),
                                selected: isSelected,
                                onSelected: (selected) {
                                  ref.read(searchProvider.notifier).toggleMealTypeFilter(mealType);
                                },
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),
                    
                    const Divider(height: 32),
                    
                    // Exclude allergens
                    _buildFilterSection(
                      context,
                      title: 'Loại Trừ Dị Ứng',
                      child: FutureBuilder<List<String>>(
                        future: ref.read(searchProvider.notifier).getAvailableAllergens(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox.shrink();
                          
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: snapshot.data!.map((allergen) {
                              final isSelected = searchState.excludedAllergens.contains(allergen);
                              return FilterChip(
                                label: Text(allergen),
                                selected: isSelected,
                                onSelected: (selected) {
                                  ref.read(searchProvider.notifier).toggleAllergenFilter(allergen);
                                },
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              // Apply button
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Áp dụng (${searchState.results.length} kết quả)'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterSection(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  String _getPriceLabel(int price) {
    switch (price) {
      case 1:
        return '💰 Rẻ';
      case 2:
        return '💰💰 Vừa';
      case 3:
        return '💰💰💰 Sang';
      default:
        return '';
    }
  }
}