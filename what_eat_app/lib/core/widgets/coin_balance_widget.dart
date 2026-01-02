import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/rewards/logic/rewards_provider.dart';

/// Widget hiển thị số dư coin của user với animation
/// 
/// Features:
/// - Hiển thị coin balance real-time
/// - Animated counter khi số coin thay đổi
/// - Pulse animation khi update
/// - Gradient background vàng gold
/// - Tap để navigate đến transaction history
class CoinBalanceWidget extends ConsumerStatefulWidget {
  /// Size của widget (compact hoặc expanded)
  final CoinBalanceSize size;
  
  /// Có hiển thị label "Coins" không
  final bool showLabel;
  
  /// Custom onTap callback (mặc định navigate to /transactions)
  final VoidCallback? onTap;

  const CoinBalanceWidget({
    super.key,
    this.size = CoinBalanceSize.compact,
    this.showLabel = false,
    this.onTap,
  });

  @override
  ConsumerState<CoinBalanceWidget> createState() => _CoinBalanceWidgetState();
}

class _CoinBalanceWidgetState extends ConsumerState<CoinBalanceWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  int? _previousBalance;

  @override
  void initState() {
    super.initState();
    
    // Setup pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _triggerPulse() {
    _pulseController.forward().then((_) {
      _pulseController.reverse();
    });
  }

  void _handleTap() {
    if (widget.onTap != null) {
      widget.onTap!();
    } else {
      // Navigate to transaction history
      context.push('/transactions');
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = ref.watch(coinBalanceProvider);

    // Trigger pulse if balance changed
    if (_previousBalance != null && _previousBalance != balance) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerPulse();
      });
    }
    _previousBalance = balance;

    return _buildContent(balance);
  }

  Widget _buildContent(int balance) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: child,
          );
        },
        child: Container(
          padding: _getPadding(),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(_getBorderRadius()),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Coin icon
              Icon(
                Icons.monetization_on,
                color: Colors.white,
                size: _getIconSize(),
              ),
              SizedBox(width: _getSpacing()),
              
              // Balance text
              AnimatedFlipCounter(
                value: balance,
                duration: const Duration(milliseconds: 500),
                textStyle: TextStyle(
                  color: Colors.white,
                  fontSize: _getTextSize(),
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              // Label (optional)
              if (widget.showLabel) ...[
                const SizedBox(width: 4),
                Text(
                  'Coins',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: _getTextSize() - 2,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  EdgeInsets _getPadding() {
    switch (widget.size) {
      case CoinBalanceSize.compact:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case CoinBalanceSize.medium:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case CoinBalanceSize.large:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
    }
  }

  double _getBorderRadius() {
    switch (widget.size) {
      case CoinBalanceSize.compact:
        return 16;
      case CoinBalanceSize.medium:
        return 20;
      case CoinBalanceSize.large:
        return 24;
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case CoinBalanceSize.compact:
        return 18;
      case CoinBalanceSize.medium:
        return 24;
      case CoinBalanceSize.large:
        return 32;
    }
  }

  double _getTextSize() {
    switch (widget.size) {
      case CoinBalanceSize.compact:
        return 14;
      case CoinBalanceSize.medium:
        return 16;
      case CoinBalanceSize.large:
        return 20;
    }
  }

  double _getSpacing() {
    switch (widget.size) {
      case CoinBalanceSize.compact:
        return 6;
      case CoinBalanceSize.medium:
        return 8;
      case CoinBalanceSize.large:
        return 10;
    }
  }
}

/// Size variants cho CoinBalanceWidget
enum CoinBalanceSize {
  compact,
  medium,
  large,
}

/// Widget hiển thị số với animation flip
class AnimatedFlipCounter extends StatefulWidget {
  final int value;
  final Duration duration;
  final TextStyle? textStyle;

  const AnimatedFlipCounter({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 500),
    this.textStyle,
  });

  @override
  State<AnimatedFlipCounter> createState() => _AnimatedFlipCounterState();
}

class _AnimatedFlipCounterState extends State<AnimatedFlipCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  int _previousValue = 0;
  int _currentValue = 0;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
    _previousValue = widget.value;
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void didUpdateWidget(AnimatedFlipCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.value != widget.value) {
      setState(() {
        _previousValue = _currentValue;
        _currentValue = widget.value;
      });
      
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // Interpolate between previous and current value
        final displayValue = (_previousValue + 
          ((_currentValue - _previousValue) * _animation.value)).round();
        
        return Text(
          _formatNumber(displayValue),
          style: widget.textStyle,
        );
      },
    );
  }

  String _formatNumber(int value) {
    // Format với dấu phẩy cho số lớn
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return value.toString();
    }
  }
}

/// Extension để format số coin đẹp hơn
extension CoinFormatExtension on int {
  String toFormattedCoinString() {
    if (this >= 1000000) {
      return '${(this / 1000000).toStringAsFixed(1)}M';
    } else if (this >= 1000) {
      return '${(this / 1000).toStringAsFixed(1)}K';
    } else {
      return toString();
    }
  }
}
