import 'package:url_launcher/url_launcher.dart';
import '../utils/logger.dart';
import 'dart:io' show Platform;

class DeepLinkService {
  /// Mở Google Maps với từ khóa tìm kiếm
  Future<bool> openGoogleMaps(String query) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final geoUrl = Uri.parse('geo:0,0?q=$encodedQuery');
      final webUrl = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$encodedQuery',
      );

      // Prefer geo: scheme on Android (opens native Maps reliably)
      if (Platform.isAndroid) {
        final geoOk = await launchUrl(
          geoUrl,
          mode: LaunchMode.externalApplication,
        );
        if (geoOk) {
          AppLogger.info('Opened Maps (geo) with query: $query');
          return true;
        }
      }

      // Fallback to https url
      final ok = await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      if (ok) {
        AppLogger.info('Opened Google Maps with query: $query');
        return true;
      }

      final fallbackOk =
          await launchUrl(webUrl, mode: LaunchMode.platformDefault);
      if (fallbackOk) {
        AppLogger.info('Opened Google Maps in browser as fallback: $query');
        return true;
      }

      final webviewOk =
          await launchUrl(webUrl, mode: LaunchMode.inAppWebView);
      if (webviewOk) {
        AppLogger.info('Opened Google Maps in in-app webview: $query');
        return true;
      }

      AppLogger.warning('Could not launch Google Maps');
      return false;
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
      final geoUrl = Uri.parse('geo:$latitude,$longitude?q=$latitude,$longitude');
      final webUrl = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
      );

      if (Platform.isAndroid) {
        final geoOk = await launchUrl(
          geoUrl,
          mode: LaunchMode.externalApplication,
        );
        if (geoOk) return true;
      }

      final ok = await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      if (ok) return true;
      final fallbackOk =
          await launchUrl(webUrl, mode: LaunchMode.platformDefault);
      if (fallbackOk) return true;
      final webviewOk = await launchUrl(webUrl, mode: LaunchMode.inAppWebView);
      if (webviewOk) return true;

      AppLogger.warning('Could not launch Google Maps with coordinates');
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

