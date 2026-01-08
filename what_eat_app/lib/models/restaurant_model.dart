/// Restaurant model for displaying nearby restaurants
/// Uses fake/seed data (Level 1 - Zero Cost approach)
class RestaurantModel {
  final String id;
  final String name;
  final String? description;
  final double latitude;
  final double longitude;
  final String address;
  final double rating; // 0.0 - 5.0
  final int reviewCount;
  final String priceLevel; // "$", "$$", "$$$", "$$$$"
  final bool isOpen;
  final String? imageUrl;
  final List<String> cuisines; // ["Vietnamese", "Noodles"]
  final String? phoneNumber;
  final String? website;
  final Map<String, String>? openingHours; // {"monday": "9:00-22:00", ...}
  
  // Computed properties
  double? distanceMeters; // Calculated from user location
  String? distanceDisplay; // "500m", "1.2km"

  RestaurantModel({
    required this.id,
    required this.name,
    this.description,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.rating,
    this.reviewCount = 0,
    required this.priceLevel,
    required this.isOpen,
    this.imageUrl,
    this.cuisines = const [],
    this.phoneNumber,
    this.website,
    this.openingHours,
    this.distanceMeters,
    this.distanceDisplay,
  });

  /// Create from JSON (for fake data)
  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    return RestaurantModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lng'] as num).toDouble(),
      address: json['address'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] as int? ?? 0,
      priceLevel: json['price'] as String? ?? '\$',
      isOpen: json['isOpen'] as bool? ?? true,
      imageUrl: json['image_url'] as String?,
      cuisines: json['cuisines'] != null
          ? List<String>.from(json['cuisines'] as List)
          : [],
      phoneNumber: json['phone'] as String?,
      website: json['website'] as String?,
      openingHours: json['opening_hours'] != null
          ? Map<String, String>.from(json['opening_hours'] as Map)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'lat': latitude,
      'lng': longitude,
      'address': address,
      'rating': rating,
      'review_count': reviewCount,
      'price': priceLevel,
      'isOpen': isOpen,
      'image_url': imageUrl,
      'cuisines': cuisines,
      'phone': phoneNumber,
      'website': website,
      'opening_hours': openingHours,
    };
  }

  /// Update distance (calculated from user location)
  RestaurantModel copyWithDistance({
    double? distanceMeters,
    String? distanceDisplay,
  }) {
    return RestaurantModel(
      id: id,
      name: name,
      description: description,
      latitude: latitude,
      longitude: longitude,
      address: address,
      rating: rating,
      reviewCount: reviewCount,
      priceLevel: priceLevel,
      isOpen: isOpen,
      imageUrl: imageUrl,
      cuisines: cuisines,
      phoneNumber: phoneNumber,
      website: website,
      openingHours: openingHours,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      distanceDisplay: distanceDisplay ?? this.distanceDisplay,
    );
  }

  /// Format rating display
  String get ratingDisplay => rating.toStringAsFixed(1);

  /// Format price level display
  String get priceDisplay => priceLevel;

  /// Get status text
  String get statusText => isOpen ? 'Đang mở' : 'Đã đóng';

  /// Get status color (for UI)
  String get statusColor => isOpen ? 'green' : 'red';
}

