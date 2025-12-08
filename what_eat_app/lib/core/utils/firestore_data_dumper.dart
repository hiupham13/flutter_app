import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firebase_collections.dart';
import 'logger.dart';

/// Utility class để dump dữ liệu từ Firestore ra console
/// Mục đích: Xem cấu trúc dữ liệu thực tế để code chính xác
class FirestoreDataDumper {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Dump tất cả dữ liệu quan trọng
  Future<void> dumpAllData() async {
    AppLogger.info('=' * 80);
    AppLogger.info('BẮT ĐẦU DUMP DỮ LIỆU TỪ FIRESTORE');
    AppLogger.info('=' * 80);
    AppLogger.info('');

    await dumpMasterData();
    await dumpFoods();
    await dumpUsers();
    await dumpAppConfigs();

    AppLogger.info('');
    AppLogger.info('=' * 80);
    AppLogger.info('KẾT THÚC DUMP DỮ LIỆU');
    AppLogger.info('=' * 80);
  }

  /// Dump Master Data (attributes)
  Future<void> dumpMasterData() async {
    try {
      AppLogger.info('📋 COLLECTION: master_data');
      AppLogger.info('-' * 80);

      final doc = await _firestore
          .collection(FirebaseCollections.masterData)
          .doc(FirebaseCollections.attributesDoc)
          .get();

      if (!doc.exists) {
        AppLogger.warning('Document "attributes" không tồn tại');
        AppLogger.info('');
        return;
      }

      final data = doc.data()!;
      
      // In ra từng phần
      if (data.containsKey('cuisines')) {
        AppLogger.info('🍜 CUISINES:');
        _printList(data['cuisines'] as List?);
      }

      if (data.containsKey('meal_types')) {
        AppLogger.info('🍽️ MEAL TYPES:');
        _printList(data['meal_types'] as List?);
      }

      if (data.containsKey('flavors')) {
        AppLogger.info('🌶️ FLAVORS:');
        _printList(data['flavors'] as List?);
      }

      if (data.containsKey('allergens')) {
        AppLogger.info('⚠️ ALLERGENS:');
        _printList(data['allergens'] as List?);
      }

      // In toàn bộ raw data
      AppLogger.info('');
      AppLogger.info('📄 RAW DATA (JSON format):');
      AppLogger.info(_formatJson(data));
      AppLogger.info('');

    } catch (e) {
      AppLogger.error('Lỗi khi dump master_data: $e');
      AppLogger.info('');
    }
  }

  /// Dump Foods collection
  Future<void> dumpFoods() async {
    try {
      AppLogger.info('🍔 COLLECTION: foods');
      AppLogger.info('-' * 80);

      final querySnapshot = await _firestore
          .collection(FirebaseCollections.foods)
          .get();

      if (querySnapshot.docs.isEmpty) {
        AppLogger.warning('Collection "foods" rỗng hoặc không tồn tại');
        AppLogger.info('');
        return;
      }

      AppLogger.info('Tổng số món ăn: ${querySnapshot.docs.length}');
      AppLogger.info('');

      for (var i = 0; i < querySnapshot.docs.length; i++) {
        final doc = querySnapshot.docs[i];
        final data = doc.data();

        AppLogger.info('--- MÓN ĂN #${i + 1} ---');
        AppLogger.info('Document ID: ${doc.id}');
        AppLogger.info('Name: ${data['name'] ?? 'N/A'}');
        AppLogger.info('Price Segment: ${data['price_segment'] ?? 'N/A'}');
        AppLogger.info('Cuisine ID: ${data['cuisine_id'] ?? 'N/A'}');
        AppLogger.info('Meal Type ID: ${data['meal_type_id'] ?? 'N/A'}');
        AppLogger.info('Is Active: ${data['is_active'] ?? 'N/A'}');
        
        if (data.containsKey('context_scores')) {
          AppLogger.info('Context Scores: ${data['context_scores']}');
        }

        // In toàn bộ data của món đầu tiên để xem cấu trúc
        if (i == 0) {
          AppLogger.info('');
          AppLogger.info('📄 RAW DATA của món đầu tiên (JSON format):');
          AppLogger.info(_formatJson(data));
        }

        AppLogger.info('');
      }

    } catch (e) {
      AppLogger.error('Lỗi khi dump foods: $e');
      AppLogger.info('');
    }
  }

  /// Dump Users collection
  Future<void> dumpUsers() async {
    try {
      AppLogger.info('👤 COLLECTION: users');
      AppLogger.info('-' * 80);

      final querySnapshot = await _firestore
          .collection(FirebaseCollections.users)
          .get();

      if (querySnapshot.docs.isEmpty) {
        AppLogger.warning('Collection "users" rỗng hoặc không tồn tại');
        AppLogger.info('');
        return;
      }

      AppLogger.info('Tổng số users: ${querySnapshot.docs.length}');
      AppLogger.info('');

      for (var i = 0; i < querySnapshot.docs.length; i++) {
        final doc = querySnapshot.docs[i];
        final data = doc.data();

        AppLogger.info('--- USER #${i + 1} ---');
        AppLogger.info('Document ID (UID): ${doc.id}');
        
        if (data.containsKey('info')) {
          final info = data['info'] as Map<String, dynamic>?;
          AppLogger.info('Display Name: ${info?['display_name'] ?? 'N/A'}');
          AppLogger.info('Email: ${info?['email'] ?? 'N/A'}');
        }

        if (data.containsKey('settings')) {
          final settings = data['settings'] as Map<String, dynamic>?;
          AppLogger.info('Default Budget: ${settings?['default_budget'] ?? 'N/A'}');
          AppLogger.info('Spice Tolerance: ${settings?['spice_tolerance'] ?? 'N/A'}');
          AppLogger.info('Is Vegetarian: ${settings?['is_vegetarian'] ?? 'N/A'}');
        }

        // In toàn bộ data của user đầu tiên
        if (i == 0) {
          AppLogger.info('');
          AppLogger.info('📄 RAW DATA của user đầu tiên (JSON format):');
          AppLogger.info(_formatJson(data));
        }

        AppLogger.info('');
      }

    } catch (e) {
      AppLogger.error('Lỗi khi dump users: $e');
      AppLogger.info('');
    }
  }

  /// Dump App Configs
  Future<void> dumpAppConfigs() async {
    try {
      AppLogger.info('⚙️ COLLECTION: app_configs');
      AppLogger.info('-' * 80);

      // Dump global_config
      final globalConfigDoc = await _firestore
          .collection(FirebaseCollections.appConfigs)
          .doc(FirebaseCollections.globalConfigDoc)
          .get();

      if (globalConfigDoc.exists) {
        AppLogger.info('📄 Document: global_config');
        AppLogger.info(_formatJson(globalConfigDoc.data()!));
        AppLogger.info('');
      } else {
        AppLogger.warning('Document "global_config" không tồn tại');
      }

      // Dump copywriting
      final copywritingDoc = await _firestore
          .collection(FirebaseCollections.appConfigs)
          .doc(FirebaseCollections.copywritingDoc)
          .get();

      if (copywritingDoc.exists) {
        AppLogger.info('📄 Document: copywriting');
        AppLogger.info(_formatJson(copywritingDoc.data()!));
        AppLogger.info('');
      } else {
        AppLogger.warning('Document "copywriting" không tồn tại');
      }

    } catch (e) {
      AppLogger.error('Lỗi khi dump app_configs: $e');
      AppLogger.info('');
    }
  }

  /// Helper: In list dạng dễ đọc
  void _printList(List? list) {
    if (list == null || list.isEmpty) {
      AppLogger.info('  (rỗng)');
      return;
    }

    for (var i = 0; i < list.length; i++) {
      final item = list[i];
      if (item is Map) {
        AppLogger.info('  ${i + 1}. ${item.toString()}');
      } else {
        AppLogger.info('  ${i + 1}. $item');
      }
    }
    AppLogger.info('');
  }

  /// Helper: Format Map thành JSON string dễ đọc
  String _formatJson(Map<String, dynamic> data) {
    // Convert Timestamp và các kiểu đặc biệt thành string
    final formatted = <String, dynamic>{};
    data.forEach((key, value) {
      formatted[key] = _convertValue(value);
    });

    // Sử dụng toString() đơn giản, dễ copy
    final buffer = StringBuffer();
    buffer.writeln('{');
    formatted.forEach((key, value) {
      if (value is String) {
        buffer.writeln('  "$key": "$value",');
      } else if (value is Map) {
        buffer.writeln('  "$key": {');
        value.forEach((k, v) {
          if (v is String) {
            buffer.writeln('    "$k": "$v",');
          } else {
            buffer.writeln('    "$k": $v,');
          }
        });
        buffer.writeln('  },');
      } else if (value is List) {
        buffer.write('  "$key": [');
        for (var i = 0; i < value.length; i++) {
          if (value[i] is String) {
            buffer.write('"${value[i]}"');
          } else if (value[i] is Map) {
            buffer.write('{...}'); // Rút gọn Map trong List
          } else {
            buffer.write(value[i]);
          }
          if (i < value.length - 1) buffer.write(', ');
        }
        buffer.writeln('],');
      } else {
        buffer.writeln('  "$key": $value,');
      }
    });
    buffer.write('}');
    return buffer.toString();
  }

  /// Convert các giá trị đặc biệt (Timestamp, etc.) thành string
  dynamic _convertValue(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    } else if (value is Map) {
      final result = <String, dynamic>{};
      value.forEach((key, val) {
        result[key.toString()] = _convertValue(val);
      });
      return result;
    } else if (value is List) {
      return value.map((e) => _convertValue(e)).toList();
    }
    return value;
  }
}

