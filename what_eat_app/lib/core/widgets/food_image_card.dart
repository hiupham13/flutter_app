import 'package:flutter/material.dart';
import 'package:what_eat_app/config/theme/style_tokens.dart';

import 'package:what_eat_app/core/widgets/price_badge.dart';
import 'package:what_eat_app/core/widgets/cached_food_image.dart';

class FoodImageCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String? subtitle;
  final PriceBadge? priceBadge;
  final List<String>? tags;
  final VoidCallback? onTap;
  final String? heroTag;

  const FoodImageCard({
    super.key,
    required this.imageUrl,
    required this.title,
    this.subtitle,
    this.priceBadge,
    this.tags,
    this.onTap,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final tagChips = tags != null
        ? tags!
            .map(
              (t) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  t,
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: Colors.white),
                ),
              ),
            )
            .toList()
        : <Widget>[];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: heroTag != null
                  ? Hero(
                      tag: heroTag!,
                      child: _buildImage(),
                    )
                  : _buildImage(),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Color.fromRGBO(0, 0, 0, 0.55),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.md,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (priceBadge != null) ...[
                    priceBadge!,
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          shadows: const [
                            Shadow(
                              color: Colors.black38,
                              blurRadius: 12,
                              offset: Offset(0, 2),
                            )
                          ],
                        ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                  ],
                  if (tagChips.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: tagChips,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return CachedFoodImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      borderRadius: 0, // No border radius vì đã có ClipRRect ở parent
    );
  }
}

