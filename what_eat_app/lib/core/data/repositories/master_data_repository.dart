import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../constants/firebase_collections.dart';
import '../../../models/master_data_model.dart';
import '../../utils/logger.dart';

class MasterDataRepository {
  final FirebaseFirestore _firestore;
  MasterDataModel? _cache;

  MasterDataRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<MasterDataModel> getMasterData() async {
    if (_cache != null) return _cache!;

    // Try Firestore first
    try {
      final doc = await _firestore
          .collection(FirebaseCollections.masterData)
          .doc(FirebaseCollections.attributesDoc)
          .get();
      if (doc.exists && doc.data() != null) {
        _cache = MasterDataModel.fromMap(doc.data()!);
        return _cache!;
      }
    } catch (e, st) {
      AppLogger.warning('Load master data from Firestore failed: $e');
      AppLogger.debug('Stack: $st');
    }

    // Fallback to bundled asset
    try {
      final raw = await rootBundle.loadString('assets/data/master_data_attributes.json');
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _cache = MasterDataModel.fromMap(map);
      return _cache!;
    } catch (e, st) {
      AppLogger.error('Load master data asset failed: $e', e, st);
      rethrow;
    }
  }
}

