import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:what_eat_app/config/theme/style_tokens.dart';
import 'package:what_eat_app/core/constants/app_colors.dart';
import 'package:what_eat_app/core/widgets/primary_button.dart';
import 'package:what_eat_app/core/widgets/price_badge.dart';
import 'package:what_eat_app/core/widgets/cached_food_image.dart';
import 'package:what_eat_app/core/widgets/food_detail_skeleton.dart';
import 'package:what_eat_app/core/widgets/error_widget.dart';
import 'package:what_eat_app/core/services/cloudinary_service.dart';
import '../../../../models/food_model.dart';
import '../../../../models/food_model_extensions.dart';
import '../../../../core/services/deep_link_service.dart';
import '../../../../core/services/copywriting_service.dart';
import '../../../../core/services/share_service.dart';
import '../../../../core/services/activity_log_service.dart';
import '../../../../core/services/analytics_service.dart';
import '../logic/recommendation_provider.dart';
import '../logic/scoring_engine.dart';

/// ⚡ OPTIMIZED: Supports optimistic navigation với loading skeleton
class ResultScreen extends ConsumerStatefulWidget {
  final FoodModel? food; // Nullable for loading state
  final RecommendationContext recContext;
  final bool isLoading; // Flag for skeleton loading

  const ResultScreen({
    super.key,
    this.food,
    required this.recContext,
    this.isLoading = false,
  });

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  FoodModel? _currentFood;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentFood = widget.food;
    _isLoading = widget.isLoading;
    
    // ⚡ If we already have food data, not loading
    if (_currentFood != null) {
      _isLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // ⚡ Listen to recommendation state changes
    ref.listen<RecommendationState>(recommendationProvider, (previous, next) {
      // Update food when recommendation completes
      if (!next.isLoading && next.currentFood != null) {
        if (_currentFood?.id != next.currentFood!.id || _isLoading) {
          setState(() {
            _currentFood = next.currentFood;
            _isLoading = false;
          });
        }
      }
      
      // Handle errors
      if (next.error != null && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    });

    final recommendationState = ref.watch(recommendationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gợi ý món ăn'),
        actions: [
          if (_currentFood != null && !_isLoading)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _handleShare(context, ref, _currentFood!),
            ),
        ],
      ),
      body: _isLoading
          ? const FoodDetailSkeleton() // ⚡ Show skeleton while loading
          : _currentFood == null
              ? _buildErrorState(context)
              : _buildFoodContent(context, ref, recommendationState),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    // Standardized error display: AppErrorWidget
    return AppErrorWidget(
      title: 'Không thể tải món ăn',
      message: 'Vui lòng thử lại sau',
      onRetry: () {
        // Retry by refreshing recommendation
        final recommendationState = ref.read(recommendationProvider);
        if (recommendationState.currentFood != null) {
          setState(() {
            _currentFood = recommendationState.currentFood;
            _isLoading = false;
          });
        }
      },
    );
  }

  Widget _buildFoodContent(
    BuildContext context,
    WidgetRef ref,
    RecommendationState recommendationState,
  ) {
    final food = _currentFood!;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFoodImage(food),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food.name,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                PriceBadge(level: _mapPrice(food.priceSegment)),
                const SizedBox(height: AppSpacing.lg),
                if (food.description.isNotEmpty) ...[
                  Text(
                    food.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
                FutureBuilder<String>(
                  future: ref.read(copywritingServiceProvider).getRecommendationReason(
                    weather: widget.recContext.weather,
                    companion: widget.recContext.companion,
                    mood: widget.recContext.mood,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return _buildReasonCard(snapshot.data!, context);
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                FutureBuilder<String>(
                  future: ref.read(copywritingServiceProvider).getJokeMessage(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return _buildJokeCard(snapshot.data!, context);
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                _buildActionButtons(
                  context,
                  ref,
                  recommendationState,
                  food,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodImage(FoodModel food) {
    // Sử dụng CloudinaryService với fallback: images → id → name
    final cloudinaryService = ref.read(cloudinaryServiceProvider);
    final imageUrl = food.getImageUrl(
      cloudinaryService,
      transformations: 'c_fill,g_auto,q_auto,w_800',
      enableAutoFallback: true, // Bật auto fallback để tự tạo URL từ food.id nếu images list không hợp lệ
      enableLogging: false, // Tắt logging để tránh spam log
    );
    
    // Debug log trong debug mode - Đã comment để tránh spam log
    // if (kDebugMode && imageUrl != null) {
    //   AppLogger.info('🍔 Result Screen - Food Image URL:');
    //   AppLogger.info('   Food ID: ${food.id}');
    //   AppLogger.info('   Food Name: ${food.name}');
    //   AppLogger.info('   Images list: ${food.images}');
    //   AppLogger.info('   Generated URL: $imageUrl');
    // } else if (kDebugMode && imageUrl == null) {
    //   AppLogger.warning('⚠️ Result Screen - No image URL found for:');
    //   AppLogger.warning('   Food ID: ${food.id}');
    //   AppLogger.warning('   Food Name: ${food.name}');
    //   AppLogger.warning('   Images list: ${food.images}');
    // }

    return Hero(
      tag: 'food_${food.id}', // ⚡ Unique hero tag for smooth transition
      child: SizedBox(
        height: 320,
        width: double.infinity,
        child: CachedFoodImage(
          imageUrl: imageUrl ?? '',
          height: 320,
          fit: BoxFit.cover,
          borderRadius: AppRadius.lg,
        ),
      ),
    );
  }

  Widget _buildReasonCard(String reason, BuildContext ctx) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: const [AppShadows.soft],
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              reason,
              style: Theme.of(ctx).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJokeCard(String joke, BuildContext ctx) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: const [AppShadows.soft],
      ),
      child: Row(
        children: [
          const Icon(Icons.sentiment_satisfied, color: AppColors.secondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              joke,
              style: Theme.of(ctx).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    RecommendationState state,
    FoodModel food,
  ) {
    final deepLinkService = DeepLinkService();
    
    return Column(
      children: [
        PrimaryButton(
          label: 'Tìm quán ngay',
          leadingIcon: Icons.map_outlined,
          onPressed: () async {
            final userId = FirebaseAuth.instance.currentUser?.uid;

            if (userId != null) {
              final activityLogService = ref.read(activityLogServiceProvider);
              final analyticsService = ref.read(analyticsServiceProvider);

              await Future.wait([
                activityLogService.logMapClick(
                  userId: userId,
                  food: food,
                ),
                analyticsService.logMapOpened(food),
              ]);

              await ref.read(recommendationProvider.notifier).selectFood(food.id);
            }

            final success = await deepLinkService.openGoogleMaps(food.mapQuery);
            if (!success && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Không thể mở Google Maps'),
                ),
              );
            }
          },
        ),
        const SizedBox(height: AppSpacing.md),
        PrimaryButton(
          label: 'Gợi ý khác',
          leadingIcon: Icons.casino,
          variant: PrimaryButtonVariant.tonal,
          onPressed: state.recommendedFoods.length > 1
              ? () => ref.read(recommendationProvider.notifier).nextFood()
              : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton.icon(
          onPressed: () {
            // TODO: Save to favorites
          },
          icon: const Icon(Icons.favorite_border),
          label: const Text('Lưu vào yêu thích'),
        ),
      ],
    );
  }

  Future<void> _handleShare(
    BuildContext context,
    WidgetRef ref,
    FoodModel food,
  ) async {
    final copywritingService = ref.read(copywritingServiceProvider);
    final analyticsService = ref.read(analyticsServiceProvider);
    final shareService = ShareService(analyticsService: analyticsService);
    
    // Get recommendation reason for richer share text
    final reason = await copywritingService.getRecommendationReason(
      weather: widget.recContext.weather,
      companion: widget.recContext.companion,
      mood: widget.recContext.mood,
    );

    // Share with full context
    await shareService.shareFoodWithContext(
      food: food,
      weather: widget.recContext.weather?.description,
      companion: widget.recContext.companion,
      mood: widget.recContext.mood,
      reason: reason,
    );
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
