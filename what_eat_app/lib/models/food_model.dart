import 'package:cloud_firestore/cloud_firestore.dart';

class FoodModel {
  final String id;
  final String name;
  final List<String> searchKeywords;
  final String description;
  final List<String> images;
  
  // Attributes (mapping với master_data)
  final String cuisineId;
  final String mealTypeId;
  final List<String> flavorProfile;
  final List<String> allergenTags;
  
  // Logic giá & thời gian
  final int priceSegment; // 1: Cheap, 2: Mid, 3: High
  final int? avgCalories;
  final List<String> availableTimes; // ["morning", "dinner", "late_night"]
  
  // Context Scoring
  final Map<String, double> contextScores;
  
  // Deep Link Data
  final String mapQuery;
  
  // System Meta
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int viewCount;
  final int pickCount;

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
    required this.contextScores,
    required this.mapQuery,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.viewCount,
    required this.pickCount,
  });

  factory FoodModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
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
      contextScores: Map<String, double>.from(
        (data['context_scores'] as Map? ?? {}).map(
          (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
        ),
      ),
      mapQuery: data['map_query'] as String? ?? '',
      isActive: data['is_active'] as bool? ?? true,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
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

