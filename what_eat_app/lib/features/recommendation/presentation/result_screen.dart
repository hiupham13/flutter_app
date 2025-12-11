import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../models/food_model.dart';
import '../../../../core/services/deep_link_service.dart';
import '../../../../core/services/copywriting_service.dart';
import '../../../../core/services/activity_log_service.dart';
import '../../../../core/services/analytics_service.dart';
import '../logic/recommendation_provider.dart';
import '../logic/scoring_engine.dart';

class ResultScreen extends ConsumerWidget {
  final FoodModel food;
  final RecommendationContext context;

  const ResultScreen({
    super.key,
    required this.food,
    required this.context,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copywritingService = ref.watch(copywritingServiceProvider);
    final deepLinkService = DeepLinkService();
    final recommendationState = ref.watch(recommendationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gợi ý món ăn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              final text =
                  'Thử món ${food.name} nhé? Tìm quán: https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(food.mapQuery)}';
              Share.share(text, subject: 'Hôm Nay Ăn Gì?');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Food Image
            _buildFoodImage(),
            
            // Food Info
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Food Name
                  Text(
                    food.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Price Badge
                  _buildPriceBadge(food.priceSegment),
                  const SizedBox(height: 16),

                  // Description
                  if (food.description.isNotEmpty) ...[
                    Text(
                      food.description,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Recommendation Reason
                  FutureBuilder<String>(
                    future: copywritingService.getRecommendationReason(
                      weather: this.context.weather,
                      companion: this.context.companion,
                      mood: this.context.mood,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return _buildReasonCard(snapshot.data!);
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 24),

                  // Joke Message
                  FutureBuilder<String>(
                    future: copywritingService.getJokeMessage(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return _buildJokeCard(snapshot.data!);
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 32),

                  // Action Buttons
                  _buildActionButtons(
                    context,
                    ref,
                    deepLinkService,
                    recommendationState,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodImage() {
    final imageUrl = _firstValidImage(food.images);

    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        image: imageUrl != null
            ? DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
                onError: (_, __) {},
              )
            : null,
      ),
      child: imageUrl == null
          ? const Center(
              child: Icon(
                Icons.restaurant,
                size: 80,
                color: Colors.grey,
              ),
            )
          : null,
    );
  }

  Widget _buildPriceBadge(int priceSegment) {
    final labels = ['Cuối tháng', 'Bình dân', 'Sang chảnh'];
    final colors = [Colors.green, Colors.orange, Colors.purple];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors[priceSegment - 1].withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors[priceSegment - 1],
          width: 1,
        ),
      ),
      child: Text(
        labels[priceSegment - 1],
        style: TextStyle(
          color: colors[priceSegment - 1],
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildReasonCard(String reason) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '💡 $reason',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJokeCard(String joke) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.sentiment_satisfied, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              joke,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.orange,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    DeepLinkService deepLinkService,
    RecommendationState state,
  ) {
    return Column(
      children: [
        // Primary Button: Tìm quán
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              final userId = FirebaseAuth.instance.currentUser?.uid;

              if (userId != null) {
                // Best-effort logging; errors are handled inside services
                final activityLogService =
                    ref.read(activityLogServiceProvider);
                final analyticsService = ref.read(analyticsServiceProvider);

                await Future.wait([
                  activityLogService.logMapClick(
                    userId: userId,
                    food: food,
                  ),
                  analyticsService.logMapOpened(food),
                ]);

                // Also mark food as selected
                await ref
                    .read(recommendationProvider.notifier)
                    .selectFood(food.id);
              }

              final success = await deepLinkService.openGoogleMaps(food.mapQuery);
              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Không thể mở Google Maps'),
                  ),
                );
              }
            },
            icon: const Icon(Icons.map),
            label: const Text('TÌM QUÁN NGAY'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Secondary Button: Gợi ý khác
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: state.recommendedFoods.length > 1
                ? () {
                    ref.read(recommendationProvider.notifier).nextFood();
                  }
                : null,
            icon: const Icon(Icons.refresh),
            label: const Text('Gợi ý khác'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Tertiary: Lưu vào yêu thích (stub)
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.favorite_border),
            label: const Text('Lưu vào yêu thích (sắp có)'),
          ),
        ),
      ],
    );
  }

  String? _firstValidImage(List<String> urls) {
    for (final url in urls) {
      if (url.startsWith('http://') || url.startsWith('https://')) {
        return url;
      }
    }
    return null;
  }
}
