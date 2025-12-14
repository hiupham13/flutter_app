import 'package:what_eat_app/models/food_model.dart';
import 'package:what_eat_app/core/services/cloudinary_service.dart';

/// Extension để lấy image URL từ FoodModel
extension FoodModelImageExtension on FoodModel {
  /// Lấy URL hình ảnh với Cloudinary transform
  /// 
  /// Sử dụng fallback strategy:
  /// 1. food.images list (nếu có và là URL hợp lệ, không phải placeholder)
  ///    - Tự động bỏ qua placeholder URLs (placeholder.com, placehold.it, etc.)
  /// 2. food.id → foods/{id}.jpg (từ Cloudinary)
  /// 3. food.name → foods/{normalized-name}.jpg (từ Cloudinary)
  /// 
  /// **Lưu ý**: Nếu Firestore có placeholder URL trong trường `images`,
  /// code sẽ tự động bỏ qua và dùng `food.id` để tạo URL từ Cloudinary.
  /// 
  /// [transformations] - Cloudinary transformations (mặc định: defaultFoodTransformations)
  /// [enableLogging] - Bật logging để debug (mặc định: false)
  String? getImageUrl(
    CloudinaryService cloudinaryService, {
    String transformations = CloudinaryService.defaultFoodTransformations,
    bool enableLogging = false,
  }) {
    return cloudinaryService.getFoodImageUrl(
      id,
      name,
      images,
      transformations: transformations,
      enableLogging: enableLogging,
    );
  }

  /// Lấy URL hình ảnh thumbnail
  String? getThumbnailUrl(CloudinaryService cloudinaryService) {
    return cloudinaryService.getFoodImageUrl(
      id,
      name,
      images,
      transformations: CloudinaryService.thumbnailTransformations,
    );
  }

  /// Lấy URL hình ảnh avatar
  String? getAvatarUrl(CloudinaryService cloudinaryService) {
    return cloudinaryService.getFoodImageUrl(
      id,
      name,
      images,
      transformations: CloudinaryService.avatarTransformations,
    );
  }
}

