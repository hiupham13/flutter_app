import 'package:what_eat_app/core/services/cloudinary_service.dart';
import 'package:what_eat_app/core/utils/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Helper class để test Cloudinary connection
/// 
/// Sử dụng trong development để kiểm tra kết nối và URL generation
class CloudinaryTestHelper {
  /// Test kết nối Cloudinary với food ID và name
  /// 
  /// Ví dụ sử dụng:
  /// ```dart
  /// final helper = CloudinaryTestHelper();
  /// helper.testWithFoodId('pho-bo');
  /// helper.testWithFoodName('Phở Bò');
  /// ```
  static void testConnection(WidgetRef ref, {
    String? foodId,
    String? foodName,
  }) {
    final cloudinaryService = ref.read(cloudinaryServiceProvider);
    cloudinaryService.testConnection(
      testFoodId: foodId,
      testFoodName: foodName,
    );
  }

  /// Test với food ID cụ thể
  static void testWithFoodId(WidgetRef ref, String foodId) {
    final cloudinaryService = ref.read(cloudinaryServiceProvider);
    
    AppLogger.info('=== Testing Cloudinary with Food ID: $foodId ===');
    
    final url = cloudinaryService.getFoodImageUrlFromId(
      foodId,
      enableLogging: true,
    );
    
    AppLogger.info('Generated URL: $url');
    AppLogger.info('👉 Copy URL này và mở trong browser để kiểm tra');
    AppLogger.info('=== End Test ===\n');
  }

  /// Test với food name cụ thể
  static void testWithFoodName(WidgetRef ref, String foodName) {
    final cloudinaryService = ref.read(cloudinaryServiceProvider);
    
    AppLogger.info('=== Testing Cloudinary with Food Name: $foodName ===');
    
    final url = cloudinaryService.getFoodImageUrlFromName(
      foodName,
      enableLogging: true,
    );
    
    AppLogger.info('Generated URL: $url');
    AppLogger.info('👉 Copy URL này và mở trong browser để kiểm tra');
    AppLogger.info('=== End Test ===\n');
  }

  /// Test với FoodModel (nếu có)
  static void testWithFoodModel(WidgetRef ref, food) {
    if (food == null) {
      AppLogger.warning('FoodModel is null');
      return;
    }

    final cloudinaryService = ref.read(cloudinaryServiceProvider);
    
    AppLogger.info('=== Testing Cloudinary with FoodModel ===');
    AppLogger.info('Food ID: ${food.id}');
    AppLogger.info('Food Name: ${food.name}');
    AppLogger.info('Images list: ${food.images?.length ?? 0} items');
    
    // Sử dụng extension method
    final url = food.getImageUrl(cloudinaryService, enableLogging: true);
    
    AppLogger.info('Generated URL: $url');
    AppLogger.info('👉 Copy URL này và mở trong browser để kiểm tra');
    AppLogger.info('=== End Test ===\n');
  }

  /// Quick test - test tất cả các trường hợp
  static void quickTest(WidgetRef ref) {
    AppLogger.info('🚀 Starting Cloudinary Quick Test...\n');
    
    // Test 1: Connection
    testConnection(ref, foodId: 'pho-bo', foodName: 'Phở Bò');
    
    // Test 2: With food ID (sẽ tạo URL: foods/pho-bo.jpg)
    testWithFoodId(ref, 'pho-bo');
    
    // Test 3: With food name (sẽ tạo URL: foods/pho-bo.jpg)
    testWithFoodName(ref, 'Phở Bò');
    
    AppLogger.info('✅ Quick test completed!');
    AppLogger.info('👉 Check console above for URLs');
    AppLogger.info('👉 Copy URLs and open in browser to verify images');
    AppLogger.info('👉 Note: Folder trên Cloudinary phải là "foods" (số nhiều)\n');
  }
}

