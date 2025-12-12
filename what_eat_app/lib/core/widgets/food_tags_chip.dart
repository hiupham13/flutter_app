import 'package:flutter/material.dart';
import 'package:what_eat_app/config/theme/style_tokens.dart';
import 'package:what_eat_app/core/constants/app_colors.dart';

class FoodTagsChip extends StatelessWidget {
  final List<String> tags;
  final Set<String>? selected;
  final void Function(String tag)? onSelected;
  final bool scrollable;

  const FoodTagsChip({
    super.key,
    required this.tags,
    this.selected,
    this.onSelected,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final chips = tags
        .map(
          (tag) => FilterChip(
            label: Text(tag),
            selected: selected?.contains(tag) ?? false,
            onSelected: onSelected != null ? (_) => onSelected!(tag) : null,
            selectedColor: AppColors.primary.withOpacity(0.14),
            checkmarkColor: AppColors.primaryDark,
            labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: (selected?.contains(tag) ?? false)
                      ? AppColors.primaryDark
                      : AppColors.textSecondary,
                ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              side: const BorderSide(color: AppColors.border),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
          ),
        )
        .toList();

    if (scrollable) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: chips,
        ),
      );
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: chips,
    );
  }
}

