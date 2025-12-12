import 'package:flutter/material.dart';
import 'package:what_eat_app/config/theme/style_tokens.dart';
import 'package:what_eat_app/core/constants/app_colors.dart';

enum PriceLevel { low, medium, high }

class PriceBadge extends StatelessWidget {
  final PriceLevel level;
  final String? label;

  const PriceBadge({
    super.key,
    required this.level,
    this.label,
  });

  Color _backgroundColor() {
    switch (level) {
      case PriceLevel.low:
        return AppColors.primaryLight.withOpacity(0.25);
      case PriceLevel.medium:
        return AppColors.secondaryLight.withOpacity(0.25);
      case PriceLevel.high:
        return const Color(0xFFFFE7D3);
    }
  }

  Color _textColor() {
    switch (level) {
      case PriceLevel.low:
        return AppColors.primaryDark;
      case PriceLevel.medium:
        return AppColors.secondaryDark;
      case PriceLevel.high:
        return const Color(0xFFB45309);
    }
  }

  String _defaultLabel() {
    switch (level) {
      case PriceLevel.low:
        return 'Bình dân';
      case PriceLevel.medium:
        return 'Vừa tầm';
      case PriceLevel.high:
        return 'Sang chảnh';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _backgroundColor(),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.payments_rounded,
            size: 16,
            color: _textColor(),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label ?? _defaultLabel(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _textColor(),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

