import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:what_eat_app/core/constants/app_colors.dart';
import 'package:what_eat_app/core/services/cloudinary_service.dart';

/// Widget hiển thị ảnh món ăn với caching tự động
/// 
/// Sử dụng cached_network_image để:
/// - Cache ảnh vào disk và memory
/// - Hiển thị placeholder trong khi loading
/// - Hiển thị error widget khi load thất bại
/// - Fade-in animation khi ảnh load xong
/// - Tự động transform URL qua Cloudinary nếu cần
class CachedFoodImage extends ConsumerWidget {
  /// URL của ảnh cần hiển thị
  final String imageUrl;
  
  /// Chiều rộng của ảnh (optional)
  final double? width;
  
  /// Chiều cao của ảnh (optional)
  final double? height;
  
  /// BoxFit cho ảnh (default: cover)
  final BoxFit fit;
  
  /// Border radius (default: 12)
  final double borderRadius;
  
  /// Custom placeholder widget (optional)
  final Widget? placeholder;
  
  /// Custom error widget (optional)
  final Widget? errorWidget;
  
  /// Duration của fade-in animation (default: 300ms)
  final Duration fadeInDuration;
  
  /// Duration của fade-out animation (default: 100ms)
  final Duration fadeOutDuration;

  const CachedFoodImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 12.0,
    this.placeholder,
    this.errorWidget,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.fadeOutDuration = const Duration(milliseconds: 100),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Transform URL qua Cloudinary nếu cần
    final cloudinaryService = ref.read(cloudinaryServiceProvider);
    final transformedUrl = cloudinaryService.transformImageUrl(
      imageUrl,
      transformations: width != null 
          ? 'c_fill,g_auto,q_auto,w_${(width! * 2).toInt()}'
          : CloudinaryService.defaultFoodTransformations,
    );
    
    // Nếu imageUrl rỗng, hiển thị error widget ngay
    if (transformedUrl.isEmpty) {
      return _buildDefaultErrorWidget();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: transformedUrl,
        width: width,
        height: height,
        fit: fit,
        fadeInDuration: fadeInDuration,
        fadeOutDuration: fadeOutDuration,
        
        // Placeholder khi đang loading
        placeholder: (context, url) {
          return placeholder ?? _buildDefaultPlaceholder();
        },
        
        // Error widget khi load thất bại
        errorWidget: (context, url, error) {
          return errorWidget ?? _buildDefaultErrorWidget();
        },
        
        // Cache configuration
        memCacheWidth: width != null ? (width! * 2).toInt() : null,
        memCacheHeight: height != null ? (height! * 2).toInt() : null,
        maxWidthDiskCache: 800,
        maxHeightDiskCache: 800,
      ),
    );
  }

  /// Placeholder mặc định khi đang loading
  Widget _buildDefaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 40,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.textSecondary.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Error widget mặc định khi load thất bại
  Widget _buildDefaultErrorWidget() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.border,
            AppColors.border.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image_outlined,
              size: 48,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Không có ảnh',
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Variant của CachedFoodImage cho circular avatar
class CachedFoodAvatar extends ConsumerWidget {
  final String imageUrl;
  final double radius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CachedFoodAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 24.0,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Transform URL qua Cloudinary cho avatar
    final cloudinaryService = ref.read(cloudinaryServiceProvider);
    final transformedUrl = cloudinaryService.transformAvatarUrl(imageUrl);
    
    if (transformedUrl.isEmpty) {
      return _buildDefaultAvatar();
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: transformedUrl,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        placeholder: (context, url) {
          return placeholder ?? _buildDefaultAvatar();
        },
        errorWidget: (context, url, error) {
          return errorWidget ?? _buildDefaultAvatar();
        },
        memCacheWidth: (radius * 4).toInt(),
        memCacheHeight: (radius * 4).toInt(),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.3),
            AppColors.primaryDark.withOpacity(0.3),
          ],
        ),
      ),
      child: Icon(
        Icons.restaurant,
        size: radius,
        color: AppColors.primary,
      ),
    );
  }
}

/// Utility class để quản lý cache
class FoodImageCacheManager {
  /// Clear toàn bộ image cache
  static Future<void> clearCache() async {
    await CachedNetworkImage.evictFromCache('');
  }

  /// Clear cache của một URL cụ thể
  static Future<void> clearCacheForUrl(String url) async {
    await CachedNetworkImage.evictFromCache(url);
  }
}