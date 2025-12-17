import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_widget.dart' as custom;
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/price_badge.dart';
import '../../../core/widgets/cached_food_image.dart';
import '../../../core/services/share_service.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../../models/food_model.dart';
import '../../../models/food_model_extensions.dart';
import '../logic/favorites_provider.dart';
import '../../../core/utils/logger.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteFoods = ref.watch(favoriteFoodsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Món Yêu Thích'),
        elevation: 0,
        actions: [
          // Share all button
          favoriteFoods.when(
            data: (foods) => foods.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.share),
                    tooltip: 'Chia sẻ danh sách',
                    onPressed: () => _shareAllFavorites(context, ref, foods),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          // Clear all button
          favoriteFoods.when(
            data: (foods) => foods.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Xóa tất cả',
                    onPressed: () => _showClearAllDialog(context, ref),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: favoriteFoods.when(
        data: (foods) => foods.isEmpty
            ? const EmptyStateWidget(
                title: 'Chưa có món yêu thích',
                message: 'Thêm món ăn vào danh sách yêu thích để xem lại sau',
              )
            : _buildFoodList(context, ref, foods),
        loading: () => const LoadingIndicator(),
        error: (e, st) => custom.AppErrorWidget(
          title: 'Lỗi tải danh sách',
          message: e.toString(),
          onRetry: () => ref.refresh(favoriteFoodsProvider),
        ),
      ),
    );
  }
  
  Widget _buildFoodList(BuildContext context, WidgetRef ref, List<FoodModel> foods) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(favoriteFoodsProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: foods.length,
        itemBuilder: (context, index) {
          final food = foods[index];
          return _buildFoodCard(context, ref, food);
        },
      ),
    );
  }
  
  Widget _buildFoodCard(BuildContext context, WidgetRef ref, FoodModel food) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Navigate to food detail
          AppLogger.info('Food tapped: ${food.name}');
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with remove button
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Builder(
                    builder: (context) {
                      // Sử dụng CloudinaryService với fallback giống như result screen
                      final cloudinaryService = ref.read(cloudinaryServiceProvider);
                      final imageUrl = food.getImageUrl(
                        cloudinaryService,
                        transformations: 'c_fill,g_auto,q_auto,w_800',
                        enableAutoFallback: true, // Bật auto fallback
                        enableLogging: false, // Tắt logging để tránh spam log
                      );
                      
                      // Debug log trong debug mode - Đã comment để tránh spam log
                      // if (kDebugMode && imageUrl != null) {
                      //   AppLogger.info('❤️ Favorites Screen - Food Image URL:');
                      //   AppLogger.info('   Food ID: ${food.id}');
                      //   AppLogger.info('   Food Name: ${food.name}');
                      //   AppLogger.info('   Images list: ${food.images}');
                      //   AppLogger.info('   Generated URL: $imageUrl');
                      // } else if (kDebugMode && imageUrl == null) {
                      //   AppLogger.warning('⚠️ Favorites Screen - No image URL found for:');
                      //   AppLogger.warning('   Food ID: ${food.id}');
                      //   AppLogger.warning('   Food Name: ${food.name}');
                      //   AppLogger.warning('   Images list: ${food.images}');
                      // }
                      
                      return CachedFoodImage(
                        imageUrl: imageUrl ?? '',
                        fit: BoxFit.cover,
                        borderRadius: 0,
                      );
                    },
                  ),
                ),
                // Remove button
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: () => _removeFavorite(context, ref, food),
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.favorite,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Food info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          food.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PriceBadge(
                        level: _getPriceLevel(food.priceSegment),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Description
                  if (food.description.isNotEmpty) ...[
                    Text(
                      food.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  // Info chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildInfoChip(
                        context,
                        Icons.restaurant,
                        food.cuisineId,
                      ),
                      _buildInfoChip(
                        context,
                        Icons.schedule,
                        food.mealTypeId,
                      ),
                      if (food.avgCalories != null)
                        _buildInfoChip(
                          context,
                          Icons.local_fire_department,
                          '${food.avgCalories} kcal',
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _shareFood(context, ref, food),
                          icon: const Icon(Icons.share, size: 18),
                          label: const Text('Chia sẻ'),
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoChip(BuildContext context, IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      labelStyle: Theme.of(context).textTheme.bodySmall,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
  
  PriceLevel _getPriceLevel(int segment) {
    switch (segment) {
      case 1:
        return PriceLevel.low;
      case 3:
        return PriceLevel.high;
      default:
        return PriceLevel.medium;
    }
  }
  
  Future<void> _removeFavorite(
    BuildContext context,
    WidgetRef ref,
    FoodModel food,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa khỏi yêu thích?'),
        content: Text('Bạn có chắc muốn xóa "${food.name}" khỏi danh sách yêu thích?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        final controller = ref.read(favoritesControllerProvider);
        await controller.removeFavorite(food.id);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã xóa "${food.name}" khỏi yêu thích'),
              action: SnackBarAction(
                label: 'Hoàn tác',
                onPressed: () async {
                  try {
                    await controller.addFavorite(food.id);
                  } catch (e) {
                    AppLogger.error('Undo remove favorite failed: $e');
                  }
                },
              ),
            ),
          );
        }
      } catch (e) {
        AppLogger.error('Remove favorite failed: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e')),
          );
        }
      }
    }
  }
  
  Future<void> _showClearAllDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tất cả?'),
        content: const Text(
          'Bạn có chắc muốn xóa tất cả món ăn khỏi danh sách yêu thích?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        final controller = ref.read(favoritesControllerProvider);
        await controller.clearAll();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa tất cả món yêu thích')),
          );
        }
      } catch (e) {
        AppLogger.error('Clear all favorites failed: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e')),
          );
        }
      }
    }
  }
  
  Future<void> _shareFood(
    BuildContext context,
    WidgetRef ref,
    FoodModel food,
  ) async {
    try {
      final analyticsService = ref.read(analyticsServiceProvider);
      final shareService = ShareService(analyticsService: analyticsService);
      
      await shareService.shareFood(
        food: food,
        customMessage: 'Món này trong danh sách yêu thích của tôi!',
      );
      
      AppLogger.info('Favorite food shared: ${food.name}');
    } catch (e) {
      AppLogger.error('Share favorite food failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể chia sẻ: $e')),
        );
      }
    }
  }
  
  Future<void> _shareAllFavorites(
    BuildContext context,
    WidgetRef ref,
    List<FoodModel> favorites,
  ) async {
    try {
      final analyticsService = ref.read(analyticsServiceProvider);
      final shareService = ShareService(analyticsService: analyticsService);
      
      await shareService.shareFavoritesSummary(favorites: favorites);
      
      AppLogger.info('Favorites list shared: ${favorites.length} items');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã chia sẻ danh sách yêu thích')),
        );
      }
    } catch (e) {
      AppLogger.error('Share favorites list failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể chia sẻ: $e')),
        );
      }
    }
  }
}
