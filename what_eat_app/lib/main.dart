import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/utils/logger.dart';
import 'core/services/error_handler.dart';

import 'firebase_options.dart';

void main() async {
  // Global guarded zone (crash reporting)
  await AppErrorHandler.runGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      AppLogger.info('Firebase initialized successfully');
    } catch (e, st) {
      AppLogger.error('Firebase initialization failed: $e', e, st);
      AppLogger.warning('Hãy chạy lệnh: flutterfire configure');
    }

    // Crashlytics & global error hooks
    await AppErrorHandler.init();

    // Initialize Hive for local storage
    try {
      await Hive.initFlutter();
      AppLogger.info('Hive initialized successfully');
    } catch (e, st) {
      AppLogger.error('Hive initialization failed: $e', e, st);
    }

    runApp(
      const ProviderScope(
        child: WhatEatApp(),
      ),
    );
  });
}
