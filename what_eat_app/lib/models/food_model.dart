import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'dart:convert';

part 'food_model.g.dart';

@HiveType(typeId: 0)
class FoodModel extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final List<String> searchKeywords;
  
  @HiveField(3)
  final String description;
  
  @HiveField(4)
  final List<String> images;
  
  // Attributes (mapping với master_data)
  @HiveField(5)
  final String cuisineId;
  
  @HiveField(6)
  final String mealTypeId;
  
  @HiveField(7)
  final List<String> flavorProfile;
  
  @HiveField(8)
  final List<String> allergenTags;
  
  // Logic giá & thời gian
  @HiveField(9)
  final int priceSegment; // 1: Cheap, 2: Mid, 3: High
  
  @HiveField(10)
  final int? avgCalories;
  
  @HiveField(11)
  final List<String> availableTimes; // ["morning", "dinner", "late_night"]
  
  // Context Scoring - Stored as JSON string for Hive compatibility
  @HiveField(12)
  final String contextScoresJson;
  
  // Deep Link Data
  @HiveField(13)
  final String mapQuery;
  
  // System Meta
  @HiveField(14)
  final bool isActive;
  
  @HiveField(15)
  final int createdAtMillis;
  
  @HiveField(16)
  final int updatedAtMillis;
  
  @HiveField(17)
  final int viewCount;
  
  @HiveField(18)
  final int pickCount;
  
  // Computed properties for easy access
  Map<String, double> get contextScores =>
      Map<String, double>.from(json.decode(contextScoresJson));
  
  DateTime get createdAt =>
      DateTime.fromMillisecondsSinceEpoch(createdAtMillis);
  
  DateTime get updatedAt =>
      DateTime.fromMillisecondsSinceEpoch(updatedAtMillis);

  FoodModel({
    required this.id,
    required this.name,
    required this.searchKeywords,
    required this.description,
    required this.images,
    required this.cuisineId,
    required this.mealTypeId,
    required this.flavorProfile,
    required this.allergenTags,
    required this.priceSegment,
    this.avgCalories,
    required this.availableTimes,
    required this.contextScoresJson,
    required this.mapQuery,
    required this.isActive,
    required this.createdAtMillis,
    required this.updatedAtMillis,
    required this.viewCount,
    required this.pickCount,
  });
  
  // Factory constructor for easy creation with Map
  factory FoodModel.create({
    required String id,
    required String name,
    required List<String> searchKeywords,
    required String description,
    required List<String> images,
    required String cuisineId,
    required String mealTypeId,
    required List<String> flavorProfile,
    required List<String> allergenTags,
    required int priceSegment,
    int? avgCalories,
    required List<String> availableTimes,
    required Map<String, double> contextScores,
    required String mapQuery,
    required bool isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
    required int viewCount,
    required int pickCount,
  }) {
    return FoodModel(
      id: id,
      name: name,
      searchKeywords: searchKeywords,
      description: description,
      images: images,
      cuisineId: cuisineId,
      mealTypeId: mealTypeId,
      flavorProfile: flavorProfile,
      allergenTags: allergenTags,
      priceSegment: priceSegment,
      avgCalories: avgCalories,
      availableTimes: availableTimes,
      contextScoresJson: json.encode(contextScores),
      mapQuery: mapQuery,
      isActive: isActive,
      createdAtMillis: createdAt.millisecondsSinceEpoch,
      updatedAtMillis: updatedAt.millisecondsSinceEpoch,
      viewCount: viewCount,
      pickCount: pickCount,
    );
  }

  factory FoodModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    final contextScoresMap = Map<String, double>.from(
      (data['context_scores'] as Map? ?? {}).map(
        (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
      ),
    );
    
    final createdAt = (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now();
    final updatedAt = (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now();
    
    return FoodModel(
      id: doc.id,
      name: data['name'] as String,
      searchKeywords: List<String>.from(data['search_keywords'] as List? ?? []),
      description: data['description'] as String? ?? '',
      images: List<String>.from(data['images'] as List? ?? []),
      cuisineId: data['cuisine_id'] as String,
      mealTypeId: data['meal_type_id'] as String,
      flavorProfile: List<String>.from(data['flavor_profile'] as List? ?? []),
      allergenTags: List<String>.from(data['allergen_tags'] as List? ?? []),
      priceSegment: data['price_segment'] as int? ?? 2,
      avgCalories: data['avg_calories'] as int?,
      availableTimes: List<String>.from(data['available_times'] as List? ?? []),
      contextScoresJson: json.encode(contextScoresMap),
      mapQuery: data['map_query'] as String? ?? '',
      isActive: data['is_active'] as bool? ?? true,
      createdAtMillis: createdAt.millisecondsSinceEpoch,
      updatedAtMillis: updatedAt.millisecondsSinceEpoch,
      viewCount: data['view_count'] as int? ?? 0,
      pickCount: data['pick_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'search_keywords': searchKeywords,
      'description': description,
      'images': images,
      'cuisine_id': cuisineId,
      'meal_type_id': mealTypeId,
      'flavor_profile': flavorProfile,
      'allergen_tags': allergenTags,
      'price_segment': priceSegment,
      'avg_calories': avgCalories,
      'available_times': availableTimes,
      'context_scores': contextScores,
      'map_query': mapQuery,
      'is_active': isActive,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'view_count': viewCount,
      'pick_count': pickCount,
    };
  }
}

