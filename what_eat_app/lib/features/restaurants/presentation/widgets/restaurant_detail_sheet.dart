import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../models/restaurant_model.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../config/theme/style_tokens.dart';
import '../../../../core/services/deep_link_service.dart';

/// Bottom sheet hiển thị chi tiết restaurant
class RestaurantDetailSheet extends StatelessWidget {
  final RestaurantModel restaurant;

  const RestaurantDetailSheet({
    super.key,
    required this.restaurant,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  if (restaurant.imageUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: restaurant.imageUrl!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 200,
                          color: Colors.grey[300],
                          child: const Icon(Icons.restaurant, size: 64),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Name and Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.name,
                          style: AppFonts.headlineSmall.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: restaurant.isOpen
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: restaurant.isOpen
                                ? Colors.green
                                : Colors.red,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              restaurant.isOpen
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              size: 16,
                              color: restaurant.isOpen
                                  ? Colors.green[700]
                                  : Colors.red[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              restaurant.statusText,
                              style: AppFonts.labelMedium.copyWith(
                                color: restaurant.isOpen
                                    ? Colors.green[700]
                                    : Colors.red[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Rating, Price, Distance
                  Row(
                    children: [
                      // Rating
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.amber[700],
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            restaurant.ratingDisplay,
                            style: AppFonts.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (restaurant.reviewCount > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              '(${restaurant.reviewCount} đánh giá)',
                              style: AppFonts.bodySmall.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(width: 16),
                      // Price
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          restaurant.priceLevel,
                          style: AppFonts.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Distance
                      if (restaurant.distanceDisplay != null) ...[
                        const Spacer(),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              restaurant.distanceDisplay!,
                              style: AppFonts.bodyMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  if (restaurant.description != null) ...[
                    Text(
                      restaurant.description!,
                      style: AppFonts.bodyMedium.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Address
                  _buildInfoRow(
                    icon: Icons.place,
                    label: 'Địa chỉ',
                    value: restaurant.address,
                  ),
                  const SizedBox(height: 12),

                  // Phone
                  if (restaurant.phoneNumber != null)
                    _buildInfoRow(
                      icon: Icons.phone,
                      label: 'Điện thoại',
                      value: restaurant.phoneNumber!,
                    ),
                  if (restaurant.phoneNumber != null)
                    const SizedBox(height: 12),

                  // Cuisines
                  if (restaurant.cuisines.isNotEmpty) ...[
                    Text(
                      'Ẩm thực',
                      style: AppFonts.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: restaurant.cuisines.map((cuisine) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            cuisine,
                            style: AppFonts.labelMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Opening Hours
                  if (restaurant.openingHours != null &&
                      restaurant.openingHours!.isNotEmpty) ...[
                    Text(
                      'Giờ mở cửa',
                      style: AppFonts.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...restaurant.openingHours!.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _getDayName(entry.key),
                              style: AppFonts.bodyMedium.copyWith(
                                color: Colors.grey[700],
                              ),
                            ),
                            Text(
                              entry.value,
                              style: AppFonts.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: AppShadows.medium,
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('Đóng'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _openDirections(context),
                      icon: const Icon(Icons.directions),
                      label: const Text('Chỉ đường'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build info row
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppFonts.labelSmall.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppFonts.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Get day name in Vietnamese
  String _getDayName(String dayKey) {
    const dayNames = {
      'monday': 'Thứ 2',
      'tuesday': 'Thứ 3',
      'wednesday': 'Thứ 4',
      'thursday': 'Thứ 5',
      'friday': 'Thứ 6',
      'saturday': 'Thứ 7',
      'sunday': 'Chủ nhật',
    };
    return dayNames[dayKey.toLowerCase()] ?? dayKey;
  }

  /// Open directions in Google Maps
  Future<void> _openDirections(BuildContext context) async {
    final deepLinkService = DeepLinkService();
    final success = await deepLinkService.openGoogleMapsWithCoordinates(
      restaurant.latitude,
      restaurant.longitude,
    );

    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể mở Google Maps'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}

