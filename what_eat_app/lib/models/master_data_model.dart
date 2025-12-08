// lib/models/master_data_model.dart

class MasterDataModel {
  final List<CategoryItem> cuisines;
  final List<CategoryItem> mealTypes;
  final List<CategoryItem> flavors;
  final List<CategoryItem> allergens;

  MasterDataModel({
    required this.cuisines,
    required this.mealTypes,
    required this.flavors,
    required this.allergens,
  });

  // Factory nhận dữ liệu từ Firestore (Map)
  factory MasterDataModel.fromMap(Map<String, dynamic> data) {
    return MasterDataModel(
      cuisines: _parseList(data['cuisines']),
      mealTypes: _parseList(data['meal_types']), // Chú ý key phải khớp trên Firebase
      flavors: _parseList(data['flavors']),
      allergens: _parseList(data['allergens']),
    );
  }

  // Hàm phụ trợ để parse List
  static List<CategoryItem> _parseList(dynamic list) {
    if (list is List) {
      return list.map((item) => CategoryItem.fromMap(item)).toList();
    }
    return [];
  }
}

class CategoryItem {
  final String id;
  final String name;
  final String? icon; // Icon có thể null

  CategoryItem({required this.id, required this.name, this.icon});

  factory CategoryItem.fromMap(Map<String, dynamic> map) {
    return CategoryItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      icon: map['icon'],
    );
  }
}