import 'package:geolocator/geolocator.dart';
import '../utils/logger.dart';

class LocationService {
  /// Lấy vị trí hiện tại của người dùng
  Future<Position?> getCurrentLocation() async {
    try {
      // 1. Kiểm tra xem GPS có bật không?
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.warning('Location services are disabled');
        
        // ✅ UPDATE: Mở cài đặt để người dùng bật GPS
        // Hàm này trả về true nếu người dùng đã bật, false nếu họ hủy
        bool opened = await Geolocator.openLocationSettings();
        
        // Nếu người dùng vẫn không bật sau khi mở cài đặt -> Trả về null
        if (!opened) {
             // Check lại lần nữa cho chắc (vì một số máy openLocationSettings trả về void/false ko chuẩn)
             if (!await Geolocator.isLocationServiceEnabled()) {
                return null;
             }
        }
      }

      // 2. Kiểm tra quyền truy cập (Giữ nguyên)
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          AppLogger.warning('Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        AppLogger.warning('Location permissions are permanently denied');
        return null;
      }

      // 3. Lấy vị trí hiện tại (Kèm Timeout)
      // ✅ UPDATE: Thêm timeLimit để tránh treo app nếu GPS yếu
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10), 
      );

      AppLogger.info('Location retrieved: ${position.latitude}, ${position.longitude}');
      return position;
      
    } catch (e) {
      AppLogger.error('Error getting location: $e');
      return null;
    }
  }

  /// Tính khoảng cách giữa hai điểm (km)
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }
}