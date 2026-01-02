import 'package:flutter/material.dart';
import '../../../../models/reward_model.dart';

/// Card hiển thị mystery box với animation và effects
/// 
/// Features:
/// - Color-coded theo rarity (Bronze/Silver/Gold/Diamond)
/// - Shimmer effect cho unopened boxes
/// - Pulse/hover animation
/// - Unopened badge indicator
/// - Disabled state cho opened boxes
/// - Rainbow gradient cho Diamond boxes
class MysteryBoxCard extends StatefulWidget {
  /// Box để hiển thị
  final RewardBox box;
  
  /// Callback khi tap vào box
  final VoidCallback? onTap;
  
  /// Size của card
  final MysteryBoxCardSize size;
  
  /// Hiển thị shadow không
  final bool showShadow;

  const MysteryBoxCard({
    super.key,
    required this.box,
    this.onTap,
    this.size = MysteryBoxCardSize.medium,
    this.showShadow = true,
  });

  @override
  State<MysteryBoxCard> createState() => _MysteryBoxCardState();
}

class _MysteryBoxCardState extends State<MysteryBoxCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    
    // Setup pulse animation cho unopened boxes
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Start pulse if unopened
    if (!widget.box.isOpened) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canTap = !widget.box.isOpened && widget.onTap != null;
    
    return GestureDetector(
      onTap: canTap ? widget.onTap : null,
      onTapDown: canTap ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: canTap ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: canTap ? () => setState(() => _isPressed = false) : null,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: !widget.box.isOpened && !_isPressed 
                ? _pulseAnimation.value 
                : (_isPressed ? 0.95 : 1.0),
            child: child,
          );
        },
        child: _buildCard(context),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    final rarity = widget.box.rarity;
    final dimensions = _getDimensions();
    
    return Container(
      width: dimensions.width,
      height: dimensions.height,
      decoration: BoxDecoration(
        gradient: _getGradient(rarity),
        borderRadius: BorderRadius.circular(dimensions.borderRadius),
        border: widget.box.rarity == BoxRarity.diamond
            ? _getRainbowBorder()
            : null,
        boxShadow: widget.showShadow && !widget.box.isOpened
            ? [
                BoxShadow(
                  color: _getColor(rarity).withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          // Shimmer effect for unopened boxes
          if (!widget.box.isOpened)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(dimensions.borderRadius),
                child: _buildShimmerEffect(rarity),
              ),
            ),
          
          // Main content
          Positioned.fill(
            child: _buildContent(context, rarity, dimensions),
          ),
          
          // Unopened badge
          if (!widget.box.isOpened)
            Positioned(
              top: 8,
              right: 8,
              child: _buildUnopenedBadge(),
            ),
          
          // Opened overlay
          if (widget.box.isOpened)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(dimensions.borderRadius),
                ),
                child: Center(
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: dimensions.iconSize * 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    BoxRarity rarity,
    _CardDimensions dimensions,
  ) {
    return Padding(
      padding: EdgeInsets.all(dimensions.padding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Box emoji/icon
          Text(
            _getEmoji(rarity),
            style: TextStyle(
              fontSize: dimensions.emojiSize,
            ),
          ),
          SizedBox(height: dimensions.spacing),
          
          // Rarity name
          Text(
            _getRarityName(rarity),
            style: TextStyle(
              color: Colors.white,
              fontSize: dimensions.titleSize,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.5),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          
          // Action text
          if (!widget.box.isOpened) ...[
            SizedBox(height: dimensions.spacing * 0.5),
            Text(
              'Nhấn để mở',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: dimensions.subtitleSize,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ] else ...[
            SizedBox(height: dimensions.spacing * 0.5),
            Text(
              'Đã mở',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: dimensions.subtitleSize,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShimmerEffect(BoxRarity rarity) {
    // Use the existing pulse controller for shimmer effect
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1 + 2 * _pulseController.value, -1 + 2 * _pulseController.value),
              end: Alignment(1 - 2 * _pulseController.value, 1 - 2 * _pulseController.value),
              colors: [
                Colors.transparent,
                Colors.white.withOpacity(0.2),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUnopenedBadge() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Center(
        child: Text(
          '!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // Styling Helpers
  // ============================================================================

  LinearGradient _getGradient(BoxRarity rarity) {
    switch (rarity) {
      case BoxRarity.bronze:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFCD7F32), Color(0xFF8B4513)],
        );
      case BoxRarity.silver:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFC0C0C0), Color(0xFF808080)],
        );
      case BoxRarity.gold:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        );
      case BoxRarity.diamond:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB9F2FF), Color(0xFF87CEEB)],
        );
    }
  }

  Color _getColor(BoxRarity rarity) {
    switch (rarity) {
      case BoxRarity.bronze:
        return const Color(0xFFCD7F32);
      case BoxRarity.silver:
        return const Color(0xFFC0C0C0);
      case BoxRarity.gold:
        return const Color(0xFFFFD700);
      case BoxRarity.diamond:
        return const Color(0xFFB9F2FF);
    }
  }

  BoxBorder? _getRainbowBorder() {
    return Border.all(
      width: 3,
      color: Colors.transparent,
    );
    // Note: For true rainbow effect, use package like 'animated_gradient'
    // or implement custom painter
  }

  String _getEmoji(BoxRarity rarity) {
    switch (rarity) {
      case BoxRarity.bronze:
        return '📦';
      case BoxRarity.silver:
        return '🎁';
      case BoxRarity.gold:
        return '💎';
      case BoxRarity.diamond:
        return '✨';
    }
  }

  String _getRarityName(BoxRarity rarity) {
    switch (rarity) {
      case BoxRarity.bronze:
        return 'Đồng';
      case BoxRarity.silver:
        return 'Bạc';
      case BoxRarity.gold:
        return 'Vàng';
      case BoxRarity.diamond:
        return 'Kim Cương';
    }
  }

  _CardDimensions _getDimensions() {
    switch (widget.size) {
      case MysteryBoxCardSize.small:
        return _CardDimensions(
          width: 100,
          height: 120,
          padding: 8,
          borderRadius: 12,
          emojiSize: 32,
          titleSize: 14,
          subtitleSize: 10,
          iconSize: 40,
          spacing: 4,
        );
      case MysteryBoxCardSize.medium:
        return _CardDimensions(
          width: 140,
          height: 180,
          padding: 12,
          borderRadius: 16,
          emojiSize: 48,
          titleSize: 16,
          subtitleSize: 12,
          iconSize: 60,
          spacing: 8,
        );
      case MysteryBoxCardSize.large:
        return _CardDimensions(
          width: 200,
          height: 240,
          padding: 16,
          borderRadius: 20,
          emojiSize: 64,
          titleSize: 20,
          subtitleSize: 14,
          iconSize: 80,
          spacing: 12,
        );
    }
  }
}

/// Size variants cho MysteryBoxCard
enum MysteryBoxCardSize {
  small,
  medium,
  large,
}

/// Internal class để store card dimensions
class _CardDimensions {
  final double width;
  final double height;
  final double padding;
  final double borderRadius;
  final double emojiSize;
  final double titleSize;
  final double subtitleSize;
  final double iconSize;
  final double spacing;

  _CardDimensions({
    required this.width,
    required this.height,
    required this.padding,
    required this.borderRadius,
    required this.emojiSize,
    required this.titleSize,
    required this.subtitleSize,
    required this.iconSize,
    required this.spacing,
  });
}

// Extension BoxRarityExtension đã được định nghĩa trong reward_model.dart
// Không cần duplicate ở đây
