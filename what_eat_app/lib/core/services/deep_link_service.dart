import 'package:url_launcher/url_launcher.dart';
import '../utils/logger.dart';

class DeepLinkService {
  /// Mở Google Maps với từ khóa tìm kiếm
  Future<bool> openGoogleMaps(String query) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$encodedQuery',
      );

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        AppLogger.info('Opened Google Maps with query: $query');
        return true;
      } else {
        AppLogger.warning('Could not launch Google Maps');
        return false;
      }
    } catch (e) {
      AppLogger.error('Error opening Google Maps: $e');
      return false;
    }
  }

  /// Mở ứng dụng Google Maps với tọa độ
  Future<bool> openGoogleMapsWithCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
      );

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('Error opening Google Maps with coordinates: $e');
      return false;
    }
  }

  /// Mở Grab Food (nếu có)
  Future<bool> openGrabFood(String query) async {
    try {
      // Deep link format cho Grab (cần kiểm tra lại format chính xác)
      final url = Uri.parse('grab://food?query=${Uri.encodeComponent(query)}');
      
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('Error opening Grab Food: $e');
      return false;
    }
  }
}

