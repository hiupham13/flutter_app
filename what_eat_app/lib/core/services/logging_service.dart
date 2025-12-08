import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import '../utils/logger.dart';

/// Central logging that fans out to console and Crashlytics.
class LoggingService {
  static void debug(String message) => AppLogger.debug(message);
  static void info(String message) => AppLogger.info(message);
  static void warning(String message) => AppLogger.warning(message);
  static void error(String message, {dynamic error, StackTrace? stack}) {
    AppLogger.error(message, error, stack);
    FirebaseCrashlytics.instance.recordError(
      error ?? message,
      stack ?? StackTrace.current,
      reason: message,
      fatal: false,
    );
  }
}

