import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/reward_model.dart';
import '../../../core/constants/rewards_constants.dart';
import '../logic/rewards_provider.dart';
import 'widgets/mystery_box_card.dart';

/// Full-screen màn hình mở Mystery Box với animations
/// 
/// Animation sequence (5.8 seconds total):
/// 1. Box appears (scale up)           → 0.5s
/// 2. User taps "Open"                  
/// 3. Box shakes 3 times               → 1.0s
/// 4. Box opens (lid flies up)         → 0.5s
/// 5. Coins fly out                    → 1.0s
/// 6. Confetti (if big win)            → 2.0s
/// 7. Final reveal (total coins)       → 0.5s
/// 8. Buttons appear (share, continue) → 0.3s
class BoxOpeningScreen extends ConsumerStatefulWidget {
  /// Box cần mở
  final RewardBox box;

  const BoxOpeningScreen({
    super.key,
    required this.box,
  });

  @override
  ConsumerState<BoxOpeningScreen> createState() => _BoxOpeningScreenState();
}

class _BoxOpeningScreenState extends ConsumerState<BoxOpeningScreen>
    with TickerProviderStateMixin {
  
  // Animation controllers
  late AnimationController _boxAppearController;
  late AnimationController _shakeController;
  late AnimationController _openController;
  late AnimationController _coinsController;
  late AnimationController _confettiController;
  late AnimationController _revealController;

  // Animations
  late Animation<double> _boxAppearAnimation;
  late Animation<double> _shakeAnimation;
  late Animation<double> _openAnimation;
  late Animation<double> _coinsAnimation;
  late Animation<double> _confettiAnimation;
  late Animation<double> _revealAnimation;

  // State
  BoxOpeningPhase _phase = BoxOpeningPhase.initial;
  int? _coinsAwarded;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startInitialAnimation();
  }

  void _initAnimations() {
    // 1. Box appear (scale 0 → 1)
    _boxAppearController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _boxAppearAnimation = CurvedAnimation(
      parent: _boxAppearController,
      curve: Curves.elasticOut,
    );

    // 2. Shake (rotate -10° ↔ +10°)
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(
      begin: -0.1,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));

    // 3. Open (scale up + opacity)
    _openController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _openAnimation = CurvedAnimation(
      parent: _openController,
      curve: Curves.easeOut,
    );

    // 4. Coins flying (scale + position)
    _coinsController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _coinsAnimation = CurvedAnimation(
      parent: _coinsController,
      curve: Curves.easeOut,
    );

    // 5. Confetti
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _confettiAnimation = CurvedAnimation(
      parent: _confettiController,
      curve: Curves.easeOut,
    );

    // 6. Reveal (fade in + slide up)
    _revealController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _revealAnimation = CurvedAnimation(
      parent: _revealController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _boxAppearController.dispose();
    _shakeController.dispose();
    _openController.dispose();
    _coinsController.dispose();
    _confettiController.dispose();
    _revealController.dispose();
    super.dispose();
  }

  Future<void> _startInitialAnimation() async {
    await Future.delayed(const Duration(milliseconds: 100));
    await _boxAppearController.forward();
    setState(() => _phase = BoxOpeningPhase.ready);
  }

  Future<void> _startOpening() async {
    if (_phase != BoxOpeningPhase.ready) return;

    setState(() => _phase = BoxOpeningPhase.shaking);

    // 1. Shake animation (3 times)
    for (int i = 0; i < 3; i++) {
      await _shakeController.forward();
      await _shakeController.reverse();
    }

    setState(() => _phase = BoxOpeningPhase.opening);

    // 2. Open animation
    await _openController.forward();

    setState(() => _phase = BoxOpeningPhase.revealing);

    // 3. Actually open box (backend call)
    try {
      final coins = await ref
          .read(rewardsControllerProvider)
          .openMysteryBox(widget.box.id);

      setState(() {
        _coinsAwarded = coins;
        _phase = BoxOpeningPhase.coinsFlying;
      });

      // 4. Coins flying animation
      await _coinsController.forward();

      // 5. Confetti if big win (500+ coins)
      if (RewardsConstants.isBigWin(coins)) {
        setState(() => _phase = BoxOpeningPhase.celebrating);
        await _confettiController.forward();
      }

      // 6. Final reveal
      setState(() => _phase = BoxOpeningPhase.complete);
      await _revealController.forward();

    } catch (e) {
      setState(() {
        _error = e.toString();
        _phase = BoxOpeningPhase.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Stack(
          children: [
            // Background gradient
            _buildBackground(),

            // Main content
            Center(
              child: _buildPhaseContent(),
            ),

            // Confetti overlay
            if (_phase == BoxOpeningPhase.celebrating)
              _buildConfetti(),

            // Close button (top right)
            if (_phase == BoxOpeningPhase.initial || 
                _phase == BoxOpeningPhase.ready ||
                _phase == BoxOpeningPhase.error)
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              widget.box.rarity.color.withOpacity(0.3),
              Colors.black87,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhaseContent() {
    switch (_phase) {
      case BoxOpeningPhase.initial:
        return _buildInitialBox();
      
      case BoxOpeningPhase.ready:
        return _buildReadyBox();
      
      case BoxOpeningPhase.shaking:
        return _buildShakingBox();
      
      case BoxOpeningPhase.opening:
      case BoxOpeningPhase.revealing:
        return _buildOpeningBox();
      
      case BoxOpeningPhase.coinsFlying:
        return _buildCoinsFlying();
      
      case BoxOpeningPhase.celebrating:
        return _buildCelebrating();
      
      case BoxOpeningPhase.complete:
        return _buildFinalReveal();
      
      case BoxOpeningPhase.error:
        return _buildError();
    }
  }

  // ============================================================================
  // Phase Builders
  // ============================================================================

  Widget _buildInitialBox() {
    return ScaleTransition(
      scale: _boxAppearAnimation,
      child: MysteryBoxCard(
        box: widget.box,
        size: MysteryBoxCardSize.large,
      ),
    );
  }

  Widget _buildReadyBox() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MysteryBoxCard(
          box: widget.box,
          size: MysteryBoxCardSize.large,
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _startOpening,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.box.rarity.color,
            padding: const EdgeInsets.symmetric(
              horizontal: 48,
              vertical: 16,
            ),
            textStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          child: const Text('MỞ HỘP QUÀ!'),
        ),
      ],
    );
  }

  Widget _buildShakingBox() {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _shakeAnimation.value,
          child: child,
        );
      },
      child: MysteryBoxCard(
        box: widget.box,
        size: MysteryBoxCardSize.large,
      ),
    );
  }

  Widget _buildOpeningBox() {
    return AnimatedBuilder(
      animation: _openAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: 1.0 - _openAnimation.value,
          child: Transform.scale(
            scale: 1.0 + (_openAnimation.value * 2),
            child: child,
          ),
        );
      },
      child: MysteryBoxCard(
        box: widget.box,
        size: MysteryBoxCardSize.large,
      ),
    );
  }

  Widget _buildCoinsFlying() {
    return AnimatedBuilder(
      animation: _coinsAnimation,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Multiple coins flying in different directions
            ...List.generate(10, (index) {
              final angle = (index / 10) * 2 * 3.14159;
              final distance = 100 * _coinsAnimation.value;
              final x = distance * (index % 2 == 0 ? 1 : -1);
              final y = -distance + (index * 10);

              return Transform.translate(
                offset: Offset(x, y),
                child: Opacity(
                  opacity: 1.0 - _coinsAnimation.value,
                  child: Text(
                    '💰',
                    style: TextStyle(
                      fontSize: 32 * (1 - _coinsAnimation.value * 0.5),
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildCelebrating() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '🎉',
          style: TextStyle(
            fontSize: 80 + (20 * _confettiAnimation.value),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'JACKPOT!',
          style: TextStyle(
            color: Colors.yellow,
            fontSize: 40 + (10 * _confettiAnimation.value),
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black,
                offset: const Offset(2, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinalReveal() {
    return FadeTransition(
      opacity: _revealAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(_revealAnimation),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Coins awarded
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: widget.box.rarity.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: widget.box.rarity.color,
                  width: 3,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.monetization_on,
                    size: 64,
                    color: Colors.yellow,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '+${_coinsAwarded}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Coins',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Share button
                OutlinedButton.icon(
                  onPressed: _shareResult,
                  icon: const Icon(Icons.share),
                  label: const Text('Chia Sẻ'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Continue button
                ElevatedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.check),
                  label: const Text('Tiếp Tục'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.box.rarity.color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfetti() {
    return AnimatedBuilder(
      animation: _confettiAnimation,
      builder: (context, child) {
        return Stack(
          children: List.generate(50, (index) {
            final x = (index % 10) * MediaQuery.of(context).size.width / 10;
            final y = MediaQuery.of(context).size.height * _confettiAnimation.value;
            final colors = [
              Colors.red,
              Colors.blue,
              Colors.green,
              Colors.yellow,
              Colors.purple,
            ];
            
            return Positioned(
              left: x,
              top: y,
              child: Container(
                width: 8,
                height: 16,
                decoration: BoxDecoration(
                  color: colors[index % colors.length],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildError() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.error_outline,
          size: 80,
          color: Colors.red,
        ),
        const SizedBox(height: 16),
        const Text(
          'Có Lỗi Xảy Ra',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _error ?? 'Unknown error',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => context.pop(),
          child: const Text('Đóng'),
        ),
      ],
    );
  }

  // ============================================================================
  // Actions
  // ============================================================================

  void _shareResult() {
    // TODO: Implement share functionality
    // Use ShareService to share result
    final text = 'Tôi vừa mở được hộp ${widget.box.rarity.displayName} '
        'và nhận ${_coinsAwarded} coins trong app Hôm Nay Ăn Gì! 🎉';
    
    // ref.read(shareServiceProvider).shareText(text);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng chia sẻ đang được phát triển')),
    );
  }
}

/// Các phase của animation mở box
enum BoxOpeningPhase {
  /// Box đang xuất hiện
  initial,
  
  /// Box sẵn sàng để mở
  ready,
  
  /// Box đang rung lắc
  shaking,
  
  /// Box đang mở
  opening,
  
  /// Đang reveal coins
  revealing,
  
  /// Coins đang bay ra
  coinsFlying,
  
  /// Đang celebrate (big win)
  celebrating,
  
  /// Hoàn thành, hiển thị final result
  complete,
  
  /// Có lỗi xảy ra
  error,
}
