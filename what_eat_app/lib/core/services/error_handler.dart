import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import '../utils/logger.dart';

/// Global error handling & crash reporting setup.
class AppErrorHandler {
  /// Call once in main() after Firebase init.
  static Future<void> init() async {
    // Bật Crashlytics collection (tự động tắt trong debug mode)
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    
    // Set user identifier nếu có (sẽ được set sau khi login)
    // FirebaseCrashlytics.instance.setUserIdentifier('user_id');

    FlutterError.onError = (FlutterErrorDetails details) async {
      // Forward to Crashlytics và log
      FirebaseCrashlytics.instance.recordFlutterError(details);
      AppLogger.error('FlutterError: ${details.exceptionAsString()}',
          details.exception, details.stack);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        fatal: true,
        reason: 'Platform error',
      );
      AppLogger.error('Platform error: $error', error, stack);
      return true;
    };
  }

  /// Wrap runApp to capture all uncaught errors.
  static Future<void> runGuarded(Future<void> Function() body) async {
    await runZonedGuarded(
      body,
      (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        AppLogger.error('Uncaught zone error: $error', error, stack);
      },
    );
  }
}

