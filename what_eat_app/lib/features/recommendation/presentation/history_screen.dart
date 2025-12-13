import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../config/theme/style_tokens.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_widget.dart' as custom;
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/cached_food_image.dart';
import '../../../core/widgets/price_badge.dart';
import '../../../core/utils/logger.dart';
import '../logic/history_provider.dart';
import '../logic/scoring_engine.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Load history on init
    Future.microtask(() {
      ref.read(historyControllerProvider.notifier).loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(historyControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch Sử Gợi Ý'),
        elevation: 0,
        actions: [
          if (historyState.totalCount > 0)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Xóa tất cả',
              onPressed: () => _showClearAllDialog(context),
            ),
        ],
      ),
      body: _buildBody(historyState),
    );
  }

  Widget _buildBody(HistoryState state) {
    if (state.isLoading) {
      return const LoadingIndicator();
    }

    if (state.error != null) {
      return custom.AppErrorWidget(
        title: 'Lỗi tải lịch sử',
        message: state.error!,
        onRetry: () => ref.read(historyControllerProvider.notifier).loadHistory(),
      );
    }

    if (state.groupedHistory.isEmpty) {
      return const EmptyStateWidget(
        title: 'Chưa có lịch sử',
        message: 'Các món ăn bạn đã được gợi ý sẽ hiển thị ở đây',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(historyControllerProvider.notifier).loadHistory();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: state.groupedHistory.length,
        itemBuilder: (context, index) {
          final group = state.groupedHistory[index];
          return _buildDateGroup(group);
        },
      ),
    );
  }

  Widget _buildDateGroup(GroupedHistoryItem group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      _formatDate(group.date),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${group.items.length} món',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),

        // Food items
        ...group.items.map((item) => _buildHistoryCard(item)),

        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  Widget _buildHistoryCard(HistoryFoodItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _navigateToFoodDetail(item.food),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Food image
            SizedBox(
              width: 120,
              height: 100,
              child: CachedFoodImage(
                imageUrl: item.food.images.isNotEmpty
                    ? item.food.images.first
                    : '',
                fit: BoxFit.cover,
                borderRadius: 0,
              ),
            ),

            // Food info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and price
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.food.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        PriceBadge(
                          level: _getPriceLevel(item.food.priceSegment),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xs),

                    // Cuisine and meal type
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _buildInfoChip(
                          context,
                          Icons.restaurant,
                          item.food.cuisineId,
                        ),
                        _buildInfoChip(
                          context,
                          Icons.schedule,
                          item.food.mealTypeId,
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // Time and actions
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          _formatTime(item.timestamp),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () => _deleteHistoryItem(context, item),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 14),
      label: Text(label),
      labelStyle: Theme.of(context).textTheme.bodySmall,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDate = DateTime(date.year, date.month, date.day);

    if (itemDate == today) {
      return 'Hôm nay';
    } else if (itemDate == yesterday) {
      return 'Hôm qua';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  String _formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
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

  void _navigateToFoodDetail(food) {
    // Navigate to result screen with food
    final context = RecommendationContext(
      budget: food.priceSegment,
      companion: 'alone',
    );
    
    this.context.pushNamed(
      'result',
      extra: {
        'food': food,
        'context': context,
      },
    );
  }

  Future<void> _deleteHistoryItem(
    BuildContext context,
    HistoryFoodItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa khỏi lịch sử?'),
        content: Text(
          'Bạn có chắc muốn xóa "${item.food.name}" khỏi lịch sử?',
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
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(historyControllerProvider.notifier)
            .deleteHistoryItem(item.historyId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã xóa "${item.food.name}" khỏi lịch sử'),
            ),
          );
        }
      } catch (e) {
        AppLogger.error('Delete history failed: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showClearAllDialog(BuildContext context) async {
    final historyState = ref.read(historyControllerProvider);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tất cả lịch sử?'),
        content: Text(
          'Bạn có chắc muốn xóa tất cả ${historyState.totalCount} món ăn khỏi lịch sử?',
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
        await ref.read(historyControllerProvider.notifier).clearAllHistory();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa tất cả lịch sử')),
          );
        }
      } catch (e) {
        AppLogger.error('Clear all history failed: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}