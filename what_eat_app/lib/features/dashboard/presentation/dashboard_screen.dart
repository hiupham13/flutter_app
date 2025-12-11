import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/context_manager.dart';
import '../../../../core/services/copywriting_service.dart';
import '../../../../core/services/weather_service.dart';
import '../../../../core/services/activity_log_service.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../models/food_model.dart';
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

  @override
  void initState() {
    super.initState();
    _loadContext();
    _preloadHistory();
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
      appBar: AppBar(
        title: const Text('Hôm Nay Ăn Gì?'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (mounted) {
                context.goNamed('login');
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadContext,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with Weather
                _buildHeader(),
                
                const SizedBox(height: 32),

                // Main Action Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildRecommendationButton(),
                ),

                const SizedBox(height: 32),

                // Quick Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildQuickActions(),
                ),

                const SizedBox(height: 24),

                // Recent Recommendations
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildRecentRecommendations(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: _buildWeatherGradient(_contextSummary?.weather),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Text(
            _greetingMessage,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Weather Widget
          if (_isLoadingContext)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          else if (_contextSummary != null)
            _buildWeatherCard(_contextSummary!),
        ],
      ),
    );
  }

  LinearGradient _buildWeatherGradient(WeatherData? weather) {
    if (weather == null) {
      return LinearGradient(colors: [Colors.orange[400]!, Colors.orange[600]!]);
    }
    if (weather.isHot) {
      return const LinearGradient(colors: [Color(0xFFFF8C42), Color(0xFFFF5722)]);
    }
    if (weather.isRainy) {
      return const LinearGradient(colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)]);
    }
    if (weather.isCold) {
      return const LinearGradient(colors: [Color(0xFF90CAF9), Color(0xFF1E88E5)]);
    }
    return const LinearGradient(colors: [Color(0xFFFFB74D), Color(0xFFFF9800)]);
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Weather Icon
          _getWeatherIcon(weather),
          const SizedBox(width: 16),
          
          // Temperature
          Text(
            '${weather.temperature.toStringAsFixed(0)}°C',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          
          // Weather Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weather.description,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  summary.timeLabel,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
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

  Widget _buildRecommendationButton() {
    final recommendationState = ref.watch(recommendationProvider);
    final isLoading = recommendationState.isLoading;

    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange[300]!,
            Colors.orange[500]!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : _handleGetRecommendation,
          borderRadius: BorderRadius.circular(20),
          child: Center(
            child: isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.restaurant_menu,
                        size: 64,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'GỢI Ý NGAY',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bấm để tìm món ăn phù hợp',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nhanh',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.pushNamed('favorites'),
                icon: const Icon(Icons.favorite_border),
                label: const Text('Yêu thích (stub)'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  await _loadContext();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Làm mới bối cảnh xong')),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Làm mới thời tiết'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentRecommendations() {
    final recommendationState = ref.watch(recommendationProvider);
    final history = recommendationState.history;

    if (history.isEmpty) {
      return const SizedBox.shrink();
    }

    final items = history.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gợi ý gần đây',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...items.map(
          (food) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: _buildFoodThumbnail(food),
                ),
              ),
              title: Text(
                food.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                food.cuisineId.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right),
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
          ),
        ),
      ],
    );
  }

  Widget _buildFoodThumbnail(FoodModel food) {
    final url = food.images.isNotEmpty ? food.images.first : null;
    if (url == null ||
        !(url.startsWith('http://') || url.startsWith('https://'))) {
      return const Icon(Icons.restaurant);
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Icon(Icons.restaurant),
    );
  }
}
