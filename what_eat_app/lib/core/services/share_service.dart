import 'package:share_plus/share_plus.dart';
import 'package:what_eat_app/models/food_model.dart';
import 'package:what_eat_app/core/services/analytics_service.dart';
import 'package:what_eat_app/core/utils/logger.dart';

/// Service để handle share functionality với rich formatting
/// 
/// Features:
/// - Format share text với food details
/// - Include Google Maps link
/// - Track share analytics
/// - Support multiple share methods
class ShareService {
  final AnalyticsService? _analyticsService;

  ShareService({AnalyticsService? analyticsService})
      : _analyticsService = analyticsService;

  /// Share món ăn với formatted text
  /// 
  /// [food] - Food model cần share
  /// [includeDescription] - Có bao gồm description không (default: true)
  /// [includePrice] - Có bao gồm price segment không (default: true)
  /// [customMessage] - Custom message prefix (optional)
  Future<ShareResult> shareFood({
    required FoodModel food,
    bool includeDescription = true,
    bool includePrice = true,
    String? customMessage,
  }) async {
    try {
      final shareText = _buildShareText(
        food: food,
        includeDescription: includeDescription,
        includePrice: includePrice,
        customMessage: customMessage,
      );

      // Track analytics
      await _trackShareEvent(food, 'food_detail');

      // Share
      final result = await Share.share(
        shareText,
        subject: 'Hôm Nay Ăn Gì? - ${food.name}',
      );

      AppLogger.info('Food shared: ${food.name}, result: ${result.status}');
      return result;
    } catch (e) {
      AppLogger.error('Share food failed: $e');
      rethrow;
    }
  }

  /// Share với recommendation context
  /// 
  /// Includes weather, companion, mood information
  Future<ShareResult> shareFoodWithContext({
    required FoodModel food,
    String? weather,
    String? companion,
    String? mood,
    String? reason,
  }) async {
    try {
      final shareText = _buildShareTextWithContext(
        food: food,
        weather: weather,
        companion: companion,
        mood: mood,
        reason: reason,
      );

      await _trackShareEvent(food, 'recommendation_result');

      final result = await Share.share(
        shareText,
        subject: 'Hôm Nay Ăn Gì? - Gợi ý: ${food.name}',
      );

      AppLogger.info('Food with context shared: ${food.name}');
      return result;
    } catch (e) {
      AppLogger.error('Share food with context failed: $e');
      rethrow;
    }
  }

  /// Share Google Maps location
  Future<ShareResult> shareLocation({
    required String mapQuery,
    required String foodName,
  }) async {
    try {
      final mapsUrl = _buildGoogleMapsUrl(mapQuery);
      final shareText = '📍 Tìm quán "$foodName":\n$mapsUrl';

      final result = await Share.share(
        shareText,
        subject: 'Vị trí quán - $foodName',
      );

      AppLogger.info('Location shared: $foodName');
      return result;
    } catch (e) {
      AppLogger.error('Share location failed: $e');
      rethrow;
    }
  }

  /// Share favorite list summary
  Future<ShareResult> shareFavoritesSummary({
    required List<FoodModel> favorites,
  }) async {
    try {
      if (favorites.isEmpty) {
        throw Exception('No favorites to share');
      }

      final shareText = _buildFavoritesText(favorites);

      final result = await Share.share(
        shareText,
        subject: 'Hôm Nay Ăn Gì? - Danh sách yêu thích của tôi',
      );

      AppLogger.info('Favorites shared: ${favorites.length} items');
      return result;
    } catch (e) {
      AppLogger.error('Share favorites failed: $e');
      rethrow;
    }
  }

  // Private helper methods

  String _buildShareText({
    required FoodModel food,
    bool includeDescription = true,
    bool includePrice = true,
    String? customMessage,
  }) {
    final buffer = StringBuffer();

    // Header với emoji
    buffer.writeln('🍜 ${customMessage ?? "Thử món này nhé!"}');
    buffer.writeln();

    // Food name
    buffer.writeln('📌 ${food.name}');

    // Price
    if (includePrice) {
      final priceEmoji = _getPriceEmoji(food.priceSegment);
      final priceText = _getPriceText(food.priceSegment);
      buffer.writeln('$priceEmoji Giá: $priceText');
    }

    // Cuisine & meal type
    buffer.writeln('🍴 ${food.cuisineId} - ${food.mealTypeId}');

    // Description
    if (includeDescription && food.description.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('💭 ${food.description}');
    }

    // Flavor profile
    if (food.flavorProfile.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('✨ ${food.flavorProfile.take(3).join(", ")}');
    }

    // Maps link
    buffer.writeln();
    buffer.writeln('📍 Tìm quán ngay:');
    buffer.writeln(_buildGoogleMapsUrl(food.mapQuery));

    // Footer
    buffer.writeln();
    buffer.writeln('💚 Từ app "Hôm Nay Ăn Gì?"');

    return buffer.toString();
  }

  String _buildShareTextWithContext({
    required FoodModel food,
    String? weather,
    String? companion,
    String? mood,
    String? reason,
  }) {
    final buffer = StringBuffer();

    // Catchy header
    buffer.writeln('🍽️ Tôi được gợi ý món: ${food.name}!');
    buffer.writeln();

    // Food details in compact format
    final details = <String>[];
    details.add('🍴 ${food.cuisineId}');
    details.add('${_getPriceEmoji(food.priceSegment)} ${_getPriceText(food.priceSegment)}');
    buffer.writeln(details.join(' • '));
    
    buffer.writeln();

    // Context in compact format
    if (weather != null || companion != null || mood != null) {
      final contexts = <String>[];
      if (weather != null) contexts.add('☀️ $weather');
      if (companion != null) contexts.add('👥 ${_formatCompanion(companion)}');
      if (mood != null) contexts.add('😊 $mood');
      
      if (contexts.isNotEmpty) {
        buffer.writeln(contexts.join(' • '));
        buffer.writeln();
      }
    }

    // Reason if available
    if (reason != null && reason.isNotEmpty) {
      buffer.writeln('💡 $reason');
      buffer.writeln();
    }

    // Short description if available
    if (food.description.isNotEmpty && food.description.length < 100) {
      buffer.writeln(food.description);
      buffer.writeln();
    }

    // Maps link - clickable
    buffer.writeln('📍 Tìm quán ngay:');
    buffer.writeln(_buildGoogleMapsUrl(food.mapQuery));
    
    buffer.writeln();
    
    // Hashtags for social media
    buffer.writeln(_buildHashtags(food));
    
    buffer.writeln();
    buffer.writeln('💚 Từ app "Hôm Nay Ăn Gì?"');

    return buffer.toString();
  }

  String _buildFavoritesText(List<FoodModel> favorites) {
    final buffer = StringBuffer();

    buffer.writeln('❤️ Danh sách món yêu thích của tôi');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln();

    for (var i = 0; i < favorites.length; i++) {
      final food = favorites[i];
      buffer.writeln('${i + 1}. ${food.name}');
      buffer.writeln('   ${_getPriceEmoji(food.priceSegment)} ${_getPriceText(food.priceSegment)} | ${food.cuisineId}');
      
      if (i < favorites.length - 1) {
        buffer.writeln();
      }
    }

    buffer.writeln();
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('💚 Từ app "Hôm Nay Ăn Gì?"');

    return buffer.toString();
  }

  String _buildGoogleMapsUrl(String mapQuery) {
    final encodedQuery = Uri.encodeComponent(mapQuery);
    return 'https://www.google.com/maps/search/?api=1&query=$encodedQuery';
  }

  String _getPriceEmoji(int segment) {
    switch (segment) {
      case 1:
        return '💵';
      case 2:
        return '💵💵';
      case 3:
        return '💵💵💵';
      default:
        return '💵';
    }
  }

  String _getPriceText(int segment) {
    switch (segment) {
      case 1:
        return 'Bình dân';
      case 2:
        return 'Trung bình';
      case 3:
        return 'Cao cấp';
      default:
        return 'Chưa rõ';
    }
  }

  String _formatCompanion(String companion) {
    switch (companion.toLowerCase()) {
      case 'alone':
        return 'Một mình';
      case 'family':
        return 'Gia đình';
      case 'friends':
        return 'Bạn bè';
      case 'date':
        return 'Hẹn hò';
      case 'colleagues':
        return 'Đồng nghiệp';
      default:
        return companion;
    }
  }

  String _buildHashtags(FoodModel food) {
    final tags = <String>[];
    
    // App hashtag
    tags.add('#HômNayĂnGì');
    
    // Cuisine hashtag (clean)
    final cuisine = food.cuisineId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    if (cuisine.isNotEmpty) {
      tags.add('#$cuisine');
    }
    
    // Meal type
    final mealType = food.mealTypeId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    if (mealType.isNotEmpty) {
      tags.add('#$mealType');
    }
    
    // Add popular food hashtags
    tags.add('#ĂnGì');
    tags.add('#MónNgon');
    
    return tags.take(5).join(' ');
  }

  Future<void> _trackShareEvent(FoodModel food, String source) async {
    try {
      // Track via analytics service if available
      await _analyticsService?.logFoodShared(
        food: food,
        source: source,
      );
    } catch (e) {
      AppLogger.error('Track share event failed: $e');
      // Don't throw, tracking failures shouldn't break sharing
    }
  }
}

/// Provider cho ShareService
final shareServiceProvider = ShareService();