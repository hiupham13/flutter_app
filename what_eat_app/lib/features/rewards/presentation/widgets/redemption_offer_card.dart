import 'package:flutter/material.dart';
import '../../../../models/reward_model.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../config/theme/style_tokens.dart';

/// Card widget hiển thị một redemption offer
/// 
/// Features:
/// - Type badge với emoji + color
/// - Title + description
/// - Coin price badge
/// - Cash value display
/// - Stock remaining indicator
/// - Expiry date warning
/// - Disabled state nếu không đủ coin
/// - Tap to view detail
class RedemptionOfferCard extends StatelessWidget {
  final RedemptionOffer offer;
  final bool canAfford;
  final VoidCallback onTap;

  const RedemptionOfferCard({
    super.key,
    required this.offer,
    required this.canAfford,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isExpiringSoon = offer.expiryDate != null &&
        offer.expiryDate!.difference(DateTime.now()).inDays <= 7;
    final isLowStock =
        offer.stockRemaining != null && offer.stockRemaining! <= 10;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: canAfford ? AppColors.primary.withOpacity(0.2) : Colors.grey[300]!,
          width: canAfford ? 2 : 1,
        ),
        boxShadow: AppShadows.small,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: Type badge + Stock/Expiry warnings
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Type badge
                    _buildTypeBadge(),
                    
                    // Warning badges
                    if (isLowStock || isExpiringSoon)
                      Row(
                        children: [
                          if (isLowStock)
                            _buildWarningBadge(
                              icon: Icons.inventory_2_outlined,
                              label: '${offer.stockRemaining} left',
                              color: Colors.orange,
                            ),
                          if (isLowStock && isExpiringSoon)
                            const SizedBox(width: 4),
                          if (isExpiringSoon)
                            _buildWarningBadge(
                              icon: Icons.access_time,
                              label: 'Sắp hết hạn',
                              color: Colors.red,
                            ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  offer.title,
                  style: AppFonts.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // Description
                Text(
                  offer.description,
                  style: AppFonts.bodySmall.copyWith(
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Divider
                Divider(color: Colors.grey[200], height: 1),
                const SizedBox(height: 12),

                // Footer row: Cash value + Coin price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Cash value
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Giá trị',
                          style: AppFonts.labelSmall.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${offer.cashValue.toStringAsFixed(0)}đ',
                          style: AppFonts.titleMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    // Coin price badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: canAfford
                            ? AppColors.primary.withOpacity(0.1)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.monetization_on,
                            color: canAfford ? Colors.amber : Colors.grey[400],
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${offer.coinsRequired}',
                            style: AppFonts.titleMedium.copyWith(
                              color: canAfford ? AppColors.primary : Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Không đủ coin warning
                if (!canAfford) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.red[700], size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Bạn chưa đủ coin để đổi',
                            style: AppFonts.labelSmall.copyWith(
                              color: Colors.red[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build type badge
  Widget _buildTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: offer.type.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            offer.type.emoji,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 4),
          Text(
            offer.type.displayName,
            style: AppFonts.labelSmall.copyWith(
              color: offer.type.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Build warning badge
  Widget _buildWarningBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 2),
          Text(
            label,
            style: AppFonts.labelSmall.copyWith(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
