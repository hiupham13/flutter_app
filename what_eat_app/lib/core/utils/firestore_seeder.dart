import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../constants/firebase_collections.dart';
import '../utils/logger.dart';
import '../../features/rewards/data/mock_redemption_data.dart';

class FirestoreSeeder {
  final FirebaseFirestore _firestore;

  FirestoreSeeder({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> seedMasterData({bool dryRun = false}) async {
    final raw = await rootBundle.loadString('assets/data/master_data_attributes.json');
    final map = jsonDecode(raw) as Map<String, dynamic>;
    AppLogger.info('Master data loaded from asset (${map.keys.join(', ')})');
    if (dryRun) return;
    await _firestore
        .collection(FirebaseCollections.masterData)
        .doc(FirebaseCollections.attributesDoc)
        .set(map, SetOptions(merge: true));
    AppLogger.info('Master data seeded to Firestore');
  }

  Future<void> seedFoods({bool dryRun = false}) async {
    final raw = await rootBundle.loadString('assets/data/foods.json');
    final list = jsonDecode(raw) as List<dynamic>;
    AppLogger.info('Foods loaded from asset (${list.length} items)');
    if (dryRun) return;

    final batch = _firestore.batch();
    for (final item in list) {
      if (item is Map<String, dynamic>) {
        final id = item['id'] as String;
        final ref =
            _firestore.collection(FirebaseCollections.foods).doc(id);
        batch.set(ref, item, SetOptions(merge: true));
      }
    }
    await batch.commit();
    AppLogger.info('Foods seeded to Firestore');
  }

  Future<void> seedFoodsBatch2({bool dryRun = false}) async {
    final raw = await rootBundle.loadString('assets/data/foods_batch_2.json');
    final list = jsonDecode(raw) as List<dynamic>;
    AppLogger.info('Foods batch2 loaded from asset (${list.length} items)');
    if (dryRun) return;

    final batch = _firestore.batch();
    for (final item in list) {
      if (item is Map<String, dynamic>) {
        final id = item['id'] as String;
        final ref =
            _firestore.collection(FirebaseCollections.foods).doc(id);
        batch.set(ref, item, SetOptions(merge: true));
      }
    }
    await batch.commit();
    AppLogger.info('Foods batch2 seeded to Firestore');
  }

  /// Seed redemption offers from mock data
  /// 
  /// Seeds all mock redemption offers (vouchers, cash, premium) to Firestore
  /// for demo/testing purposes.
  Future<void> seedRedemptionOffers({bool dryRun = false}) async {
    final offers = MockRedemptionData.allOffers;
    AppLogger.info('Redemption offers loaded from mock data (${offers.length} items)');
    
    if (dryRun) {
      AppLogger.info('Dry run - would seed: ${offers.map((o) => o.title).join(', ')}');
      return;
    }

    try {
      final batch = _firestore.batch();
      for (final offer in offers) {
        final ref = _firestore
            .collection('redemption_offers')
            .doc(offer.id);
        batch.set(ref, offer.toFirestore(), SetOptions(merge: true));
      }
      await batch.commit();
      AppLogger.info('✅ Redemption offers seeded to Firestore successfully!');
    } catch (e, st) {
      AppLogger.error('❌ Failed to seed redemption offers: $e', e, st);
      rethrow;
    }
  }

  /// Seed all data (convenience method)
  Future<void> seedAll({bool dryRun = false}) async {
    AppLogger.info('🌱 Starting full data seed...');
    await seedMasterData(dryRun: dryRun);
    await seedFoods(dryRun: dryRun);
    await seedFoodsBatch2(dryRun: dryRun);
    await seedRedemptionOffers(dryRun: dryRun);
    AppLogger.info('✅ All data seeded successfully!');
  }
}

