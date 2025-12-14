import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:what_eat_app/core/utils/logger.dart';

/// Service để xử lý hình ảnh với Cloudinary
/// 
/// Cung cấp các phương thức để:
/// - Transform URL thành Cloudinary URL với các transformations
/// - Tối ưu hóa hình ảnh (resize, format, quality)
/// - Hỗ trợ responsive images
class CloudinaryService {
  /// Cloudinary cloud name (cần config trong app)
  final String cloudName;
  
  /// Base URL của Cloudinary
  String get baseUrl => 'https://res.cloudinary.com/$cloudName/image/upload';
  
  /// Default transformations cho food images
  static const String defaultFoodTransformations = 'c_fill,g_auto,q_auto,w_800';
  
  /// Transformations cho thumbnail
  static const String thumbnailTransformations = 'c_fill,g_auto,q_auto,w_300';
  
  /// Transformations cho avatar
  static const String avatarTransformations = 'c_fill,g_auto,q_auto,w_100';

  CloudinaryService({
    required this.cloudName,
  });

  /// Chuyển đổi URL thành Cloudinary URL
  /// 
  /// Nếu URL đã là Cloudinary URL, trả về nguyên bản
  /// Nếu URL là external URL, upload lên Cloudinary (cần implement upload API)
  /// Nếu URL là public_id của Cloudinary, thêm base URL và transformations
  String transformImageUrl(
    String? imageUrl, {
    String transformations = defaultFoodTransformations,
  }) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return '';
    }

    // Nếu đã là Cloudinary URL đầy đủ, trả về nguyên bản
    if (imageUrl.contains('res.cloudinary.com')) {
      return imageUrl;
    }

    // Nếu là HTTP/HTTPS URL (external), có thể cần upload lên Cloudinary trước
    // Hoặc sử dụng Cloudinary fetch API: fetch:https://example.com/image.jpg
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      // Option 1: Sử dụng Cloudinary fetch (nếu image là public)
      // return '$baseUrl/fetch:$transformations/$imageUrl';
      
      // Option 2: Upload image lên Cloudinary trước, sau đó dùng public_id
      // Hiện tại trả về URL gốc, bạn cần implement upload logic
      return imageUrl;
    }

    // Nếu là public_id của Cloudinary (không có domain)
    // Thêm base URL và transformations
    return '$baseUrl/$transformations/$imageUrl';
  }

  /// Transform URL cho thumbnail
  String transformThumbnailUrl(String? imageUrl) {
    return transformImageUrl(imageUrl, transformations: thumbnailTransformations);
  }

  /// Transform URL cho avatar
  String transformAvatarUrl(String? imageUrl) {
    return transformImageUrl(imageUrl, transformations: avatarTransformations);
  }

  /// Transform URL với custom width
  String transformWithWidth(String? imageUrl, int width) {
    final transformations = 'c_fill,g_auto,q_auto,w_$width';
    return transformImageUrl(imageUrl, transformations: transformations);
  }

  /// Transform URL với custom width và height
  String transformWithSize(String? imageUrl, int width, int height) {
    final transformations = 'c_fill,g_auto,q_auto,w_$width,h_$height';
    return transformImageUrl(imageUrl, transformations: transformations);
  }

  /// Lấy URL đầu tiên hợp lệ từ danh sách và transform
  String? getFirstValidImageUrl(
    List<String> imageUrls, {
    String transformations = defaultFoodTransformations,
  }) {
    for (final url in imageUrls) {
      if (url.isNotEmpty) {
        return transformImageUrl(url, transformations: transformations);
      }
    }
    return null;
  }

  /// Tạo Cloudinary URL từ food ID
  /// 
  /// Format: {normalized-id}.jpg (không có folder prefix)
  /// Ví dụ: food.id = "pho-bo" → "pho-bo.jpg"
  /// 
  /// **Lưu ý**: Trên Cloudinary, khi file ở trong folder, Public ID trong URL
  /// có thể không cần folder prefix. Ví dụ: file ở folder "foods" nhưng Public ID
  /// trong URL chỉ là "pho-bo.jpg" (không phải "foods/pho-bo.jpg")
  /// 
  /// Normalize: lowercase, loại bỏ ký tự đặc biệt, thay bằng dash
  String getFoodImageUrlFromId(
    String foodId, {
    String transformations = defaultFoodTransformations,
    String extension = 'jpg',
    bool enableLogging = false,
  }) {
    if (foodId.isEmpty) {
      if (enableLogging) AppLogger.debug('Cloudinary: foodId is empty');
      return '';
    }
    
    // Normalize food ID: lowercase, loại bỏ ký tự đặc biệt, thay bằng dash
    final normalizedId = foodId
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9-]'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    
    if (normalizedId.isEmpty) {
      if (enableLogging) AppLogger.debug('Cloudinary: normalizedId is empty for foodId: $foodId');
      return '';
    }
    
    // Public ID không có folder prefix (file ở folder "foods" nhưng Public ID chỉ là tên file)
    // Format: pho-bo.jpg (không phải foods/pho-bo.jpg)
    final publicId = '$normalizedId.$extension';
    final url = '$baseUrl/$transformations/$publicId';
    
    if (enableLogging) {
      AppLogger.info('Cloudinary URL from ID:');
      AppLogger.info('  Food ID: $foodId');
      AppLogger.info('  Normalized ID: $normalizedId');
      AppLogger.info('  Public ID: $publicId (không có folder prefix)');
      AppLogger.info('  Full URL: $url');
    }
    
    return url;
  }

  /// Tạo Cloudinary URL từ food name
  /// 
  /// Format: {normalized-name}.jpg (không có folder prefix)
  /// Normalize: loại bỏ dấu tiếng Việt, lowercase, space → dash
  String getFoodImageUrlFromName(
    String foodName, {
    String transformations = defaultFoodTransformations,
    String extension = 'jpg',
    bool enableLogging = false,
  }) {
    if (foodName.isEmpty) {
      if (enableLogging) AppLogger.debug('Cloudinary: foodName is empty');
      return '';
    }
    
    // Normalize food name: loại bỏ dấu tiếng Việt, lowercase, space → dash
    var normalizedName = foodName.toLowerCase();
    
    // Loại bỏ dấu tiếng Việt
    normalizedName = normalizedName
        .replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
        .replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e')
        .replaceAll(RegExp(r'[ìíịỉĩ]'), 'i')
        .replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
        .replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u')
        .replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y')
        .replaceAll(RegExp(r'[đ]'), 'd');
    
    // Thay space và ký tự đặc biệt bằng dash
    normalizedName = normalizedName
        .replaceAll(RegExp(r'[^a-z0-9-]'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    
    if (normalizedName.isEmpty) {
      if (enableLogging) AppLogger.debug('Cloudinary: normalizedName is empty for foodName: $foodName');
      return '';
    }
    
    // Public ID không có folder prefix
    final publicId = '$normalizedName.$extension';
    final url = '$baseUrl/$transformations/$publicId';
    
    if (enableLogging) {
      AppLogger.info('Cloudinary URL from Name:');
      AppLogger.info('  Food Name: $foodName');
      AppLogger.info('  Normalized Name: $normalizedName');
      AppLogger.info('  Public ID: $publicId (không có folder prefix)');
      AppLogger.info('  Full URL: $url');
    }
    
    return url;
  }

  /// Lấy URL hình ảnh từ FoodModel với fallback strategy
  /// 
  /// Ưu tiên:
  /// 1. food.images list (nếu có và là URL hợp lệ, không phải placeholder)
  /// 2. food.id → {id}.jpg (không có folder prefix)
  /// 3. food.name → {normalized-name}.jpg (không có folder prefix)
  /// 
  /// **Lưu ý**: Public ID không có folder prefix vì file trên Cloudinary
  /// có thể ở folder "foods" nhưng Public ID trong URL chỉ là tên file.
  /// 
  /// Trả về Cloudinary URL đã transform hoặc null nếu không tìm thấy
  String? getFoodImageUrl(
    String? foodId,
    String? foodName,
    List<String>? images, {
    String transformations = defaultFoodTransformations,
    bool enableLogging = false,
  }) {
    if (enableLogging) {
      AppLogger.info('Cloudinary: Getting image URL');
      AppLogger.info('  Food ID: $foodId');
      AppLogger.info('  Food Name: $foodName');
      AppLogger.info('  Images list: ${images?.length ?? 0} items');
      AppLogger.info('  Cloud Name: $cloudName');
    }
    
    // Ưu tiên 1: Sử dụng images list nếu có và là URL hợp lệ
    if (images != null && images.isNotEmpty) {
      final firstImage = images.first;
      if (firstImage.isNotEmpty) {
        // Kiểm tra nếu là placeholder URL thì bỏ qua
        if (_isPlaceholderUrl(firstImage)) {
          if (enableLogging) {
            AppLogger.info('  Images list contains placeholder, skipping...');
          }
        } else {
          // Nếu là Cloudinary URL hoặc external URL hợp lệ
          final url = transformImageUrl(firstImage, transformations: transformations);
          if (enableLogging) {
            AppLogger.info('  Using images list: $url');
          }
          return url;
        }
      }
    }
    
    // Ưu tiên 2: Sử dụng food.id
    if (foodId != null && foodId.isNotEmpty) {
      final urlFromId = getFoodImageUrlFromId(
        foodId,
        transformations: transformations,
        enableLogging: enableLogging,
      );
      if (urlFromId.isNotEmpty) {
        if (enableLogging) {
          AppLogger.info('  Using food ID: $urlFromId');
        }
        return urlFromId;
      }
    }
    
    // Ưu tiên 3: Sử dụng food.name
    if (foodName != null && foodName.isNotEmpty) {
      final urlFromName = getFoodImageUrlFromName(foodName, transformations: transformations);
      if (urlFromName.isNotEmpty) {
        if (enableLogging) {
          AppLogger.info('  Using food name: $urlFromName');
        }
        return urlFromName;
      }
    }
    
    if (enableLogging) {
      AppLogger.warning('Cloudinary: No image URL found for food');
    }
    
    return null;
  }

  /// Kiểm tra xem URL có phải là placeholder không
  /// 
  /// Phát hiện các placeholder service phổ biến:
  /// - placeholder.com, placehold.it, via.placeholder.com
  /// - dummyimage.com, loremflickr.com, picsum.photos
  /// - Và các pattern khác
  bool _isPlaceholderUrl(String url) {
    if (url.isEmpty) return true;
    
    final lowerUrl = url.toLowerCase();
    
    // Danh sách các pattern placeholder phổ biến
    final placeholderPatterns = [
      'placeholder.com',
      'placehold.it',
      'via.placeholder.com',
      'dummyimage.com',
      'loremflickr.com',
      'picsum.photos',
      'fakeimg.pl',
      'imgplaceholder.com',
    ];
    
    // Kiểm tra pattern
    if (placeholderPatterns.any((pattern) => lowerUrl.contains(pattern))) {
      return true;
    }
    
    // Kiểm tra thêm: nếu URL chứa "placeholder" hoặc "dummy" trong domain
    if (lowerUrl.contains('placeholder') || lowerUrl.contains('/dummy')) {
      return true;
    }
    
    return false;
  }

  /// Test kết nối Cloudinary và tạo URL
  /// 
  /// Sử dụng để debug và kiểm tra cấu hình
  void testConnection({String? testFoodId, String? testFoodName}) {
    AppLogger.info('=== Cloudinary Connection Test ===');
    AppLogger.info('Cloud Name: $cloudName');
    AppLogger.info('Base URL: $baseUrl');
    
    if (testFoodId != null) {
      AppLogger.info('\nTesting with Food ID: $testFoodId');
      final url = getFoodImageUrlFromId(testFoodId, enableLogging: true);
      AppLogger.info('Generated URL: $url');
    }
    
    if (testFoodName != null) {
      AppLogger.info('\nTesting with Food Name: $testFoodName');
      final url = getFoodImageUrlFromName(testFoodName, enableLogging: true);
      AppLogger.info('Generated URL: $url');
    }
    
    AppLogger.info('=== End Test ===\n');
  }
}

/// Provider cho CloudinaryService
/// 
/// Cần config cloudName trong app initialization hoặc từ config file
final cloudinaryServiceProvider = Provider<CloudinaryService>((ref) {
  // TODO: Lấy cloudName từ config hoặc environment variable
  // Ví dụ: từ Firebase Remote Config, .env file, hoặc constants
  const cloudName = 'dinrpqxne'; // Thay bằng cloud name thực tế
  
  return CloudinaryService(cloudName: cloudName);
});

