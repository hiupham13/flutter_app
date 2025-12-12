import 'package:flutter/material.dart';
import 'package:what_eat_app/config/theme/style_tokens.dart';
import 'package:what_eat_app/core/constants/app_colors.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;
  final bool withOverlay;
  final double size;

  const LoadingIndicator({
    super.key,
    this.message,
    this.withOverlay = false,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: size,
          width: size,
          child: const CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            message!,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (!withOverlay) {
      return Center(child: content);
    }

    return Container(
      color: Colors.black.withOpacity(0.12),
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: const [AppShadows.card],
        ),
        child: content,
      ),
    );
  }
}
