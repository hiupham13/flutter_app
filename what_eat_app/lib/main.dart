import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/utils/logger.dart';
import 'core/services/error_handler.dart';
import 'core/services/cache_service.dart';
import 'models/food_model.dart';
import 'models/user_model.dart';

import 'firebase_options.dart';

void main() async {
  // Global guarded zone (crash reporting)
  await AppErrorHandler.runGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 0️⃣ Initialize date formatting locale (for intl package)
    try {
      await initializeDateFormatting('vi_VN', null);
      AppLogger.info('✅ Date formatting initialized');
    } catch (e, st) {
      AppLogger.error('❌ Date formatting initialization failed: $e', e, st);
      // Continue anyway - will fallback to default locale
    }

    // 1️⃣ Initialize Hive FIRST (before Firebase)
    try {
      await Hive.initFlutter();
      AppLogger.info('✅ Hive initialized successfully');
      
      // Register type adapters
      Hive.registerAdapter(FoodModelAdapter());
      Hive.registerAdapter(UserModelAdapter());
      Hive.registerAdapter(UserInfoAdapter());
      Hive.registerAdapter(UserSettingsAdapter());
      Hive.registerAdapter(UserStatsAdapter());
      AppLogger.info('✅ Hive adapters registered (5 adapters)');
      
      // Initialize cache service
      await CacheService().init();
      AppLogger.info('✅ CacheService initialized');
      
    } catch (e, st) {
      AppLogger.error('❌ Hive initialization failed: $e', e, st);
      // Continue anyway - app can still work without cache
    }

    // 2️⃣ Initialize Firebase
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      AppLogger.info('✅ Firebase initialized successfully');
    } catch (e, st) {
      AppLogger.error('❌ Firebase initialization failed: $e', e, st);
      AppLogger.warning('💡 Hãy chạy lệnh: flutterfire configure');
    }

    // 3️⃣ Crashlytics & global error hooks
    await AppErrorHandler.init();
    AppLogger.info('✅ Error handler initialized');

    runApp(
      const ProviderScope(
        child: WhatEatApp(),
      ),
    );
  });
}
