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
      folder: 'foods', // Folder prefix: foods/
      enableLogging: true,
    );
    
    AppLogger.info('📸 Generated URL: $url');
    AppLogger.info('📂 Public ID: foods/$foodId.jpg');
    AppLogger.info('👉 Copy URL này và mở trong browser để kiểm tra');
    AppLogger.info('=== End Test ===\n');
  }

  /// Test với food name cụ thể
  static void testWithFoodName(WidgetRef ref, String foodName) {
    final cloudinaryService = ref.read(cloudinaryServiceProvider);
    
    AppLogger.info('=== Testing Cloudinary with Food Name: $foodName ===');
    
    final url = cloudinaryService.getFoodImageUrlFromName(
      foodName,
      folder: 'foods', // Folder prefix: foods/
      enableLogging: true,
    );
    
    AppLogger.info('📸 Generated URL: $url');
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

  /// Test các món ăn cụ thể với folder prefix foods/
  /// 
  /// Test các món: bún thịt nướng, bánh tráng trộn, và các món khác
  static void testSpecificFoods(WidgetRef ref) {
    AppLogger.info('🍜 Testing Specific Foods with Folder Prefix (foods/)...\n');
    final separator = List.filled(80, '=').join();
    AppLogger.info(separator);
    
    final testFoods = [
      {'id': 'bun-thit-nuong', 'name': 'Bún Thịt Nướng'},
      {'id': 'banh-trang-tron', 'name': 'Bánh Tráng Trộn'},
      {'id': 'pho-bo', 'name': 'Phở Bò'},
      {'id': 'banh-hue', 'name': 'Bánh Bèo Huế'}, // ⚠️ Kiểm tra: food.id phải là 'banh-hue' để khớp với public_id trên Cloudinary
      {'id': 'com-tam', 'name': 'Cơm Tấm'},
    ];
    
    final cloudinaryService = ref.read(cloudinaryServiceProvider);
    
    for (var i = 0; i < testFoods.length; i++) {
      final food = testFoods[i];
      final foodId = food['id']!;
      final foodName = food['name']!;
      
      AppLogger.info('\n📋 Test ${i + 1}/${testFoods.length}: $foodName');
      AppLogger.info('   Food ID: $foodId');
      AppLogger.info('   Food Name: $foodName');
      
      // Test với food ID
      final urlFromId = cloudinaryService.getFoodImageUrlFromId(
        foodId,
        folder: 'foods',
        enableLogging: false,
      );
      
      // Test với food name
      final urlFromName = cloudinaryService.getFoodImageUrlFromName(
        foodName,
        folder: 'foods',
        enableLogging: false,
      );
      
      AppLogger.info('   📸 URL từ ID:   $urlFromId');
      AppLogger.info('   📸 URL từ Name: $urlFromName');
      AppLogger.info('   📂 Public ID:   foods/$foodId.jpg');
      AppLogger.info('   🔗 Copy URL và mở trong browser để kiểm tra');
      
      if (i < testFoods.length - 1) {
        AppLogger.info('   ${List.filled(76, '-').join()}');
      }
    }
    
    AppLogger.info('\n$separator');
    AppLogger.info('✅ Test completed!');
    AppLogger.info('👉 Tất cả URL đều có folder prefix: foods/');
    AppLogger.info('👉 Format: https://res.cloudinary.com/dinrpqxne/image/upload/.../foods/{food-id}.jpg');
    AppLogger.info('👉 Kiểm tra xem ảnh có tồn tại trên Cloudinary hay không\n');
  }

  /// Test với FoodModel và hiển thị tất cả URL có thể
  static void testFoodModelUrls(WidgetRef ref, food) {
    if (food == null) {
      AppLogger.warning('FoodModel is null');
      return;
    }

    final cloudinaryService = ref.read(cloudinaryServiceProvider);
    
    final separator = List.filled(80, '=').join();
    AppLogger.info(separator);
    AppLogger.info('🍔 Testing FoodModel Image URLs');
    AppLogger.info(separator);
    AppLogger.info('Food ID: ${food.id}');
    AppLogger.info('Food Name: ${food.name}');
    AppLogger.info('Images list: ${food.images?.length ?? 0} items');
    
    if (food.images != null && food.images!.isNotEmpty) {
      AppLogger.info('\n📋 Images từ Firestore:');
      for (var i = 0; i < food.images!.length; i++) {
        AppLogger.info('   ${i + 1}. ${food.images![i]}');
      }
    }
    
    AppLogger.info('\n🔍 Testing getImageUrl() với các options:');
    
    // Test 1: Không có auto fallback (mặc định)
    final urlDefault = food.getImageUrl(
      cloudinaryService,
      enableLogging: false,
      enableAutoFallback: false,
    );
    AppLogger.info('   1. enableAutoFallback = false:');
    AppLogger.info('      URL: $urlDefault');
    AppLogger.info('      (Chỉ dùng URL từ images list, không tự tạo từ ID/Name)');
    
    // Test 2: Có auto fallback
    final urlWithFallback = food.getImageUrl(
      cloudinaryService,
      enableLogging: false,
      enableAutoFallback: true,
    );
    AppLogger.info('\n   2. enableAutoFallback = true:');
    AppLogger.info('      URL: $urlWithFallback');
    AppLogger.info('      (Tự động tạo URL từ ID/Name nếu images list không hợp lệ)');
    
    // Test 3: Thumbnail
    final thumbnailUrl = food.getThumbnailUrl(cloudinaryService);
    AppLogger.info('\n   3. Thumbnail URL:');
    AppLogger.info('      URL: $thumbnailUrl');
    
    // Test 4: Avatar
    final avatarUrl = food.getAvatarUrl(cloudinaryService);
    AppLogger.info('\n   4. Avatar URL:');
    AppLogger.info('      URL: $avatarUrl');
    
    // Test 5: URL từ ID trực tiếp
    final urlFromId = cloudinaryService.getFoodImageUrlFromId(
      food.id,
      folder: 'foods',
      enableLogging: false,
    );
    AppLogger.info('\n   5. URL từ Food ID trực tiếp:');
    AppLogger.info('      Public ID: foods/${food.id}.jpg');
    AppLogger.info('      URL: $urlFromId');
    
    // Test 6: URL từ Name trực tiếp
    final urlFromName = cloudinaryService.getFoodImageUrlFromName(
      food.name,
      folder: 'foods',
      enableLogging: false,
    );
    AppLogger.info('\n   6. URL từ Food Name trực tiếp:');
    AppLogger.info('      URL: $urlFromName');
    
    AppLogger.info('\n$separator');
    AppLogger.info('✅ Test completed!');
    AppLogger.info('👉 Copy các URL trên và mở trong browser để kiểm tra');
    AppLogger.info('👉 Lưu ý: URL có folder prefix foods/ (ví dụ: foods/pho-bo.jpg)\n');
  }
}

