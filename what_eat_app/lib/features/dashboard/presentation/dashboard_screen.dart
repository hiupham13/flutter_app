import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:what_eat_app/config/theme/style_tokens.dart';
import 'package:what_eat_app/core/constants/app_colors.dart';
import 'package:what_eat_app/core/widgets/food_image_card.dart';
import 'package:what_eat_app/core/widgets/shimmer_box.dart';
import 'package:what_eat_app/core/widgets/primary_button.dart';
import 'package:what_eat_app/core/widgets/price_badge.dart';
import '../../../../core/services/context_manager.dart';
import '../../../../core/services/copywriting_service.dart';
import '../../../../core/services/weather_service.dart';
import '../../../../core/services/activity_log_service.dart';
import '../../../../core/services/analytics_service.dart';
import '../../recommendation/logic/recommendation_provider.dart';
import '../../recommendation/logic/scoring_engine.dart';
import '../../recommendation/presentation/widgets/input_bottom_sheet.dart';
import '../../user/data/user_preferences_repository.dart';
import '../../auth/logic/auth_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  ContextSummary? _contextSummary;
  String _greetingMessage = 'Xin chào!';
  bool _isLoadingContext = true;
  int _slotIndex = 0;
  Timer? _slotTimer;
  final List<String> _slotTexts = const [
    'Ăn gì cho hẹn hò?',
    'Cuối tháng ăn gì?',
    'Nhóm bạn chọn gì?',
    'Trời mưa ăn gì?',
  ];

  @override
  void initState() {
    super.initState();
    _loadContext();
    _preloadHistory();
    _startSlotAnimation();
  }

  Future<void> _loadContext() async {
    setState(() => _isLoadingContext = true);

    try {
      final contextManager = ref.read(contextManagerProvider);
      final copywritingService = ref.read(copywritingServiceProvider);

      // Load context summary
      final summary = await contextManager.getContextSummary();
      
      // Load greeting message
      final greeting = await copywritingService.getGreetingMessage(summary.weather);

      if (mounted) {
        setState(() {
          _contextSummary = summary;
          _greetingMessage = greeting;
          _isLoadingContext = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingContext = false;
        });
      }
    }
  }

  Future<void> _preloadHistory() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final notifier = ref.read(recommendationProvider.notifier);
    await notifier.loadHistory(userId: uid, limit: 10);
  }

  void _startSlotAnimation() {
    _slotTimer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      if (!mounted) return;
      setState(() {
        _slotIndex = (_slotIndex + 1) % _slotTexts.length;
      });
    });
  }

  @override
  void dispose() {
    _slotTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleGetRecommendation() async {
    // Show input bottom sheet
    final input = await InputBottomSheet.show(context);
    
    if (input == null) return; // User cancelled

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng đăng nhập trước khi gợi ý.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Load user settings
    final userPrefsRepo = UserPreferencesRepository();
    final userSettings = await userPrefsRepo.fetchUserSettings(userId);

    // Get context with user input
    final contextManager = ref.read(contextManagerProvider);
    final recommendationContext = await contextManager.getCurrentContext(
      budget: input.budget,
      companion: input.companion,
      mood: input.mood,
      excludedAllergens: userSettings?.excludedAllergens ?? const [],
      blacklistedFoods: userSettings?.blacklistedFoods ?? const [],
      isVegetarian: userSettings?.isVegetarian ?? false,
      spiceTolerance: userSettings?.spiceTolerance ?? 2,
    );

    // Log activity & analytics (best-effort, non-blocking errors handled inside)
    final activityLogService = ref.read(activityLogServiceProvider);
    final analyticsService = ref.read(analyticsServiceProvider);
    await Future.wait([
      activityLogService.logRecommendationRequest(
        userId: userId,
        context: recommendationContext,
      ),
      analyticsService.logRecommendationRequested(recommendationContext),
    ]);

    // Get recommendation
    final notifier = ref.read(recommendationProvider.notifier);
    await notifier.getRecommendations(
      recommendationContext,
      userId: userId,
    );

    // Check result
    final state = ref.read(recommendationProvider);
    
    if (!mounted) return;

    if (state.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error!),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (state.currentFood != null) {
      // Navigate to result screen with food and context
      context.pushNamed(
        'result',
        extra: {
          'food': state.currentFood,
          'context': recommendationContext,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hôm Nay Ăn Gì?'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Cài đặt',
            onPressed: () => context.pushNamed('settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadContext,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header with Weather
                  _buildHeader(),

                  const SizedBox(height: AppSpacing.xxl),

                  // Main Action Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: _buildRecommendationCard(),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Quick Actions
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: _buildQuickActions(),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Recent Recommendations
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: _buildRecentRecommendations(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: _buildWeatherGradient(_contextSummary?.weather),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.lg),
          bottomRight: Radius.circular(AppRadius.lg),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _greetingMessage,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Cập nhật thời tiết, thời gian và sở thích để gợi ý món phù hợp.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_isLoadingContext)
            const ShimmerBox(
              height: 120,
              borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
            ),
          if (!_isLoadingContext && _contextSummary != null) _buildWeatherCard(_contextSummary!),
        ],
      ),
    );
  }

  LinearGradient _buildWeatherGradient(WeatherData? weather) {
    if (weather == null) return const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]);
    if (weather.isHot) {
      return const LinearGradient(colors: [AppColors.secondary, AppColors.secondaryDark]);
    }
    if (weather.isRainy) {
      return const LinearGradient(colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)]);
    }
    if (weather.isCold) {
      return const LinearGradient(colors: [Color(0xFF90CAF9), Color(0xFF1E88E5)]);
    }
    return const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]);
  }

  Widget _buildWeatherCard(ContextSummary summary) {
    final weather = summary.weather;
    
    if (weather == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.location_off, color: Colors.white),
            SizedBox(width: 12),
            Text(
              'Không thể lấy thông tin thời tiết',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _getWeatherIcon(weather),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${weather.temperature.toStringAsFixed(0)}°C',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                weather.description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                summary.timeLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
              ),
            ],
          ),
          const Spacer(),
          _buildInfoPill(
            icon: Icons.place_outlined,
            label: summary.location ?? 'Không rõ vị trí',
          ),
        ],
      ),
    );
  }

  Widget _getWeatherIcon(WeatherData weather) {
    IconData icon;
    if (weather.isHot) {
      icon = Icons.wb_sunny;
    } else if (weather.isRainy) {
      icon = Icons.umbrella;
    } else if (weather.isCold) {
      icon = Icons.ac_unit;
    } else if (weather.isSunny) {
      icon = Icons.wb_sunny;
    } else {
      icon = Icons.cloud;
    }

    return Icon(
      icon,
      size: 48,
      color: Colors.white,
    );
  }

  Widget _buildRecommendationCard() {
    final recommendationState = ref.watch(recommendationProvider);
    final isLoading = recommendationState.isLoading;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: const [AppShadows.elevated],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.restaurant_menu, color: Colors.white),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Bạn muốn ăn gì hôm nay?',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Chọn bối cảnh, ngân sách, tâm trạng để nhận gợi ý cá nhân hoá.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: AppSpacing.lg),
          AnimatedSwitcher(
            duration: AppDurations.fast,
            child: Text(
              _slotTexts[_slotIndex],
              key: ValueKey(_slotTexts[_slotIndex]),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Gợi ý ngay',
            onPressed: isLoading ? null : _handleGetRecommendation,
            isLoading: isLoading,
            size: AppButtonSize.large,
            expand: true,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Bối cảnh hiện tại',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextButton.icon(
              onPressed: () async {
                await _loadContext();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã làm mới bối cảnh'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Làm mới'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.info_outline, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Kéo xuống để làm mới hoặc dùng thanh điều hướng bên dưới để khám phá thêm.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentRecommendations() {
    final recommendationState = ref.watch(recommendationProvider);
    final history = recommendationState.history;

    if (recommendationState.isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gợi ý gần đây',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          const ShimmerBox(height: 160),
          const SizedBox(height: AppSpacing.sm),
          const ShimmerBox(height: 160),
        ],
      );
    }

    if (history.isEmpty) {
      return const SizedBox.shrink();
    }

    final items = history.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gợi ý gần đây',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        ...items.asMap().entries.map(
          (entry) {
            final index = entry.key;
            final food = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: FoodImageCard(
                imageUrl: food.images.isNotEmpty ? food.images.first : '',
                title: food.name,
                subtitle: food.cuisineId,
                priceBadge: PriceBadge(level: _mapPrice(food.priceSegment)),
                tags: [
                  food.mealTypeId,
                  ...food.flavorProfile.take(2),
                ],
                heroTag: 'history_${food.id}_$index',
                onTap: () {
                  final ctx = RecommendationContext(
                    budget: food.priceSegment,
                    companion: 'alone',
                  );
                  context.pushNamed(
                    'result',
                    extra: {
                      'food': food,
                      'context': ctx,
                    },
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  PriceLevel _mapPrice(int segment) {
    switch (segment) {
      case 1:
        return PriceLevel.low;
      case 3:
        return PriceLevel.high;
      case 2:
      default:
        return PriceLevel.medium;
    }
  }

  Widget _buildInfoPill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

