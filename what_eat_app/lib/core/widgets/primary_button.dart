import 'package:flutter/material.dart';
import 'package:what_eat_app/config/theme/style_tokens.dart';
import 'package:what_eat_app/core/constants/app_colors.dart';

enum PrimaryButtonVariant { primary, tonal, ghost }

enum AppButtonSize { small, medium, large }

class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final IconData? leadingIcon;
  final PrimaryButtonVariant variant;
  final AppButtonSize size;
  final bool expand;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.width,
    this.leadingIcon,
    this.variant = PrimaryButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.expand = true,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  double _height() {
    const map = {
      AppButtonSize.small: 40.0,
      AppButtonSize.medium: 48.0,
      AppButtonSize.large: 56.0,
    };
    return map[widget.size]!;
  }

  EdgeInsets _padding() {
    switch (widget.size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm);
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md);
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md);
    }
  }

  ButtonStyle _style(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Color background;
    Color foreground;
    BorderSide? border;

    switch (widget.variant) {
      case PrimaryButtonVariant.primary:
        background = scheme.primary;
        foreground = scheme.onPrimary;
        break;
      case PrimaryButtonVariant.tonal:
        background = AppColors.primaryLight.withOpacity(0.18);
        foreground = AppColors.primaryDark;
        break;
      case PrimaryButtonVariant.ghost:
        background = Colors.transparent;
        foreground = AppColors.textPrimary;
        border = const BorderSide(color: AppColors.border);
        break;
    }

    return ElevatedButton.styleFrom(
      elevation: 0,
      minimumSize: Size(widget.width ?? (widget.expand ? double.infinity : 0), _height()),
      padding: _padding(),
      backgroundColor: background,
      foregroundColor: foreground,
      disabledBackgroundColor: AppColors.textSecondary.withOpacity(0.12),
      disabledForegroundColor: AppColors.textSecondary.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: border ?? BorderSide.none,
      ),
      textStyle: Theme.of(context).textTheme.labelLarge,
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
            if (widget.leadingIcon != null) ...[
              Icon(widget.leadingIcon, size: 18),
                const SizedBox(width: AppSpacing.xs),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: widget.expand ? double.infinity : (widget.width ?? 0),
      ),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          duration: AppDurations.fast,
          scale: _pressed && !widget.isLoading ? 0.98 : 1.0,
          child: ElevatedButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            style: _style(context),
            child: content,
          ),
        ),
      ),
    );
  }
}
