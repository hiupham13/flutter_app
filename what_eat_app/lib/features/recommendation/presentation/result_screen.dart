import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:what_eat_app/config/theme/style_tokens.dart';
import 'package:what_eat_app/core/constants/app_colors.dart';
import 'package:what_eat_app/core/widgets/primary_button.dart';
import 'package:what_eat_app/core/widgets/price_badge.dart';
import 'package:what_eat_app/core/widgets/cached_food_image.dart';
import '../../../../models/food_model.dart';
import '../../../../core/services/deep_link_service.dart';
import '../../../../core/services/copywriting_service.dart';
import '../../../../core/services/share_service.dart';
import '../../../../core/services/activity_log_service.dart';
import '../../../../core/services/analytics_service.dart';
import '../logic/recommendation_provider.dart';
import '../logic/scoring_engine.dart';

class ResultScreen extends ConsumerWidget {
  final FoodModel food;
  final RecommendationContext recContext;

  const ResultScreen({
    super.key,
    required this.food,
    required this.recContext,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copywritingService = ref.watch(copywritingServiceProvider);
    final analyticsService = ref.watch(analyticsServiceProvider);
    final shareService = ShareService(analyticsService: analyticsService);
    final deepLinkService = DeepLinkService();
    final recommendationState = ref.watch(recommendationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gợi ý món ăn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _handleShare(context, shareService, copywritingService),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFoodImage(),
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
                    future: copywritingService.getRecommendationReason(
                      weather: recContext.weather,
                      companion: recContext.companion,
                      mood: recContext.mood,
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
                    future: copywritingService.getJokeMessage(),
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
                    deepLinkService,
                    recommendationState,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodImage() {
    final imageUrl = _firstValidImage(food.images);

    return Hero(
      tag: food.id,
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
    DeepLinkService deepLinkService,
    RecommendationState state,
  ) {
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
    ShareService shareService,
    CopywritingService copywritingService,
  ) async {
    // Get recommendation reason for richer share text
    final reason = await copywritingService.getRecommendationReason(
      weather: recContext.weather,
      companion: recContext.companion,
      mood: recContext.mood,
    );

    // Share with full context
    await shareService.shareFoodWithContext(
      food: food,
      weather: recContext.weather?.description,
      companion: recContext.companion,
      mood: recContext.mood,
      reason: reason,
    );
  }

  String? _firstValidImage(List<String> urls) {
    for (final url in urls) {
      if (url.startsWith('http://') || url.startsWith('https://')) {
        return url;
      }
    }
    return null;
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
