import 'package:what_eat_app/models/food_model.dart';
import 'package:what_eat_app/core/services/cloudinary_service.dart';

/// Extension để lấy image URL từ FoodModel
extension FoodModelImageExtension on FoodModel {
  /// Lấy URL hình ảnh với Cloudinary transform
  /// 
  /// Sử dụng fallback strategy:
  /// 1. food.images list (nếu có và là URL hợp lệ, không phải placeholder)
  ///    - Tự động bỏ qua placeholder URLs (placeholder.com, placehold.it, etc.)
  /// 2. food.id → {id}.jpg (chỉ khi enableAutoFallback = true)
  /// 3. food.name → {normalized-name}.jpg (chỉ khi enableAutoFallback = true)
  /// 
  /// **Lưu ý**: 
  /// - Mặc định, auto fallback TẮT để tránh tạo URL giả định khi file chưa upload.
  /// - Chỉ bật enableAutoFallback khi chắc chắn file đã được upload lên Cloudinary.
  /// - Nếu Firestore có placeholder URL, cần upload ảnh và cập nhật field "images".
  /// 
  /// [transformations] - Cloudinary transformations (mặc định: defaultFoodTransformations)
  /// [enableLogging] - Bật logging để debug (mặc định: false)
  /// [enableAutoFallback] - Tự động tạo URL từ food.id/food.name (mặc định: false)
  String? getImageUrl(
    CloudinaryService cloudinaryService, {
    String transformations = CloudinaryService.defaultFoodTransformations,
    bool enableLogging = false,
    bool enableAutoFallback = false,
  }) {
    return cloudinaryService.getFoodImageUrl(
      id,
      name,
      images,
      transformations: transformations,
      enableLogging: enableLogging,
      enableAutoFallback: enableAutoFallback,
    );
  }

  /// Lấy URL hình ảnh thumbnail
  /// 
  /// **Lưu ý**: Không dùng auto fallback để tránh tạo URL giả định
  String? getThumbnailUrl(CloudinaryService cloudinaryService) {
    return cloudinaryService.getFoodImageUrl(
      id,
      name,
      images,
      transformations: CloudinaryService.thumbnailTransformations,
      enableAutoFallback: false,
    );
  }

  /// Lấy URL hình ảnh avatar
  /// 
  /// **Lưu ý**: Không dùng auto fallback để tránh tạo URL giả định
  String? getAvatarUrl(CloudinaryService cloudinaryService) {
    return cloudinaryService.getFoodImageUrl(
      id,
      name,
      images,
      transformations: CloudinaryService.avatarTransformations,
      enableAutoFallback: false,
    );
  }
}

