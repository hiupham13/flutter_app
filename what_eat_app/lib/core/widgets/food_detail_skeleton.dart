import 'package:flutter/material.dart';
import 'package:what_eat_app/config/theme/style_tokens.dart';
import 'package:what_eat_app/core/widgets/shimmer_box.dart';

/// Loading skeleton cho food detail screen
/// Shows placeholder khi đang load data trong background
class FoodDetailSkeleton extends StatelessWidget {
  const FoodDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image skeleton
          const ShimmerBox(
            height: 320,
            width: double.infinity,
          ),
          
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title skeleton
                const ShimmerBox(
                  height: 40,
                  width: 250,
                  borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
                ),
                
                const SizedBox(height: AppSpacing.sm),
                
                // Price badge skeleton
                const ShimmerBox(
                  height: 32,
                  width: 100,
                  borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Description skeleton
                const ShimmerBox(
                  height: 60,
                  borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
                ),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Reason card skeleton
                const ShimmerBox(
                  height: 80,
                  borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Joke card skeleton
                const ShimmerBox(
                  height: 80,
                  borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
                ),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Action buttons skeleton
                Column(
                  children: [
                    const ShimmerBox(
                      height: 56,
                      borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const ShimmerBox(
                      height: 56,
                      borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ShimmerBox(
                      height: 40,
                      width: 180,
                      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}