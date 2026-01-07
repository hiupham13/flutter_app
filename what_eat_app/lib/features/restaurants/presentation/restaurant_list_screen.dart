import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/restaurant_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../config/theme/style_tokens.dart';
import '../logic/restaurant_provider.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/empty_state_widget.dart';
import 'widgets/restaurant_card.dart';
import 'widgets/restaurant_detail_sheet.dart';

/// Màn hình hiển thị danh sách nhà hàng gần đây
/// 
/// Features:
/// - Hiển thị danh sách restaurants với distance và rating
/// - Pull-to-refresh
/// - Search restaurants
/// - Tap để xem chi tiết
/// - "Chỉ đường" button mở Google Maps
class RestaurantListScreen extends ConsumerStatefulWidget {
  const RestaurantListScreen({super.key});

  @override
  ConsumerState<RestaurantListScreen> createState() => _RestaurantListScreenState();
}

class _RestaurantListScreenState extends ConsumerState<RestaurantListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use search provider if query exists, otherwise use nearby restaurants
    final restaurantsAsync = _searchQuery.isEmpty
        ? ref.watch(nearbyRestaurantsProvider)
        : ref.watch(searchRestaurantsProvider(_searchQuery));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nhà hàng gần đây'),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm nhà hàng...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
        ),
      ),
      body: restaurantsAsync.when(
        data: (restaurants) {
          if (restaurants.isEmpty) {
            return Center(
              child: EmptyStateWidget(
                icon: Icons.restaurant_outlined,
                title: _searchQuery.isEmpty
                    ? 'Không tìm thấy nhà hàng gần đây'
                    : 'Không tìm thấy nhà hàng',
                subtitle: _searchQuery.isEmpty
                    ? 'Vui lòng bật GPS để tìm nhà hàng gần bạn'
                    : 'Thử tìm kiếm với từ khóa khác',
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(nearbyRestaurantsProvider);
              if (_searchQuery.isNotEmpty) {
                ref.invalidate(searchRestaurantsProvider(_searchQuery));
              }
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: restaurants.length,
              itemBuilder: (context, index) {
                final restaurant = restaurants[index];
                return RestaurantCard(
                  restaurant: restaurant,
                  onTap: () => _showRestaurantDetail(restaurant),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: LoadingIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Lỗi tải nhà hàng',
                style: AppFonts.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: AppFonts.bodySmall.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(nearbyRestaurantsProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show restaurant detail bottom sheet
  void _showRestaurantDetail(RestaurantModel restaurant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RestaurantDetailSheet(restaurant: restaurant),
    );
  }
}

