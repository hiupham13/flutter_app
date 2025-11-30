import 'package:geolocator/geolocator.dart';
import '../utils/logger.dart';

class LocationService {
  /// Lấy vị trí hiện tại của người dùng
  Future<Position?> getCurrentLocation() async {
    try {
      // Kiểm tra quyền truy cập vị trí
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.warning('Location services are disabled');
        return null;
      }

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

      // Lấy vị trí hiện tại
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
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

