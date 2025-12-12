import 'package:flutter/material.dart';
import 'package:what_eat_app/config/theme/style_tokens.dart';
import 'package:what_eat_app/core/constants/app_colors.dart';
import 'package:what_eat_app/core/widgets/primary_button.dart';

class AppErrorWidget extends StatelessWidget {
  final String title;
  final String? message;
  final String actionLabel;
  final VoidCallback? onRetry;
  final bool dense;

  const AppErrorWidget({
    super.key,
    required this.title,
    this.message,
    this.actionLabel = 'Thử lại',
    this.onRetry,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = dense ? AppSpacing.sm : AppSpacing.md;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(dense ? AppSpacing.md : AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: const [AppShadows.soft],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF3E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_rounded,
              color: AppColors.secondary,
              size: 20,
            ),
          ),
          SizedBox(height: spacing),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          if (onRetry != null) ...[
            SizedBox(height: spacing),
            PrimaryButton(
              label: actionLabel,
              onPressed: onRetry,
              variant: PrimaryButtonVariant.tonal,
              size: AppButtonSize.small,
              expand: false,
            ),
          ],
        ],
      ),
    );
  }
}

