import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:what_eat_app/core/services/cache_service.dart';
import 'package:what_eat_app/models/food_model.dart';
import 'package:what_eat_app/models/user_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CacheService', () {
    late CacheService cache;

    setUpAll(() async {
      // Initialize Hive for testing
      Hive.init('./test/hive_test');
      
      // Register adapters
      // Register adapters only if not already registered
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(FoodModelAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(UserModelAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(UserInfoAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(UserSettingsAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(UserStatsAdapter());
      }
    });

    setUp(() async {
      cache = CacheService(ttlOverride: const Duration(minutes: 5));
      await cache.init();
      await cache.clearCache();
    });

    tearDown(() async {
      await cache.clearCache();
    });

    test('Cache should be invalid initially', () {
      expect(cache.isCacheValid(), false);
      expect(cache.cachedItemsCount, 0);
    });

    test('Should save and retrieve foods from cache', () async {
      final foods = [
        FoodModel.create(
          id: 'test1',
          name: 'Test Food 1',
          searchKeywords: const ['test'],
          description: 'Test description',
          images: const [],
          cuisineId: 'vn',
          mealTypeId: 'lunch',
          flavorProfile: const [],
          allergenTags: const [],
          priceSegment: 2,
          availableTimes: const ['lunch'],
          contextScores: const {'weather_hot': 1.0},
          mapQuery: 'test food',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          viewCount: 0,
          pickCount: 0,
        ),
      ];

      await cache.saveFoodsToCache(foods);

      expect(cache.isCacheValid(), true);
      expect(cache.cachedItemsCount, 1);

      final retrieved = await cache.getFoodsFromCache();
      expect(retrieved.length, 1);
      expect(retrieved.first.id, 'test1');
      expect(retrieved.first.name, 'Test Food 1');
    });

    test('Cache should expire after TTL', () async {
      // Create cache with very short TTL
      final shortCache = CacheService(ttlOverride: const Duration(milliseconds: 100));
      await shortCache.init();

      final foods = [
        FoodModel.create(
          id: 'test1',
          name: 'Test Food 1',
          searchKeywords: const [],
          description: '',
          images: const [],
          cuisineId: 'vn',
          mealTypeId: 'lunch',
          flavorProfile: const [],
          allergenTags: const [],
          priceSegment: 2,
          availableTimes: const [],
          contextScores: const {},
          mapQuery: '',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          viewCount: 0,
          pickCount: 0,
        ),
      ];

      await shortCache.saveFoodsToCache(foods);
      expect(shortCache.isCacheValid(), true);

      // Wait for TTL to expire
      await Future.delayed(const Duration(milliseconds: 150));

      expect(shortCache.isCacheValid(), false);
    });

    test('Should clear cache successfully', () async {
      final foods = [
        FoodModel.create(
          id: 'test1',
          name: 'Test Food',
          searchKeywords: const [],
          description: '',
          images: const [],
          cuisineId: 'vn',
          mealTypeId: 'lunch',
          flavorProfile: const [],
          allergenTags: const [],
          priceSegment: 2,
          availableTimes: const [],
          contextScores: const {},
          mapQuery: '',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          viewCount: 0,
          pickCount: 0,
        ),
      ];

      await cache.saveFoodsToCache(foods);
      expect(cache.cachedItemsCount, 1);

      await cache.clearCache();
      expect(cache.cachedItemsCount, 0);
      expect(cache.isCacheValid(), false);
    });

    test('Cache stats should return correct information', () async {
      final stats = cache.getCacheStats();
      
      expect(stats['initialized'], true);
      expect(stats['valid'], false);
      expect(stats['version'], 0);
      expect(stats['items_count'], 0);
    });
  });
}