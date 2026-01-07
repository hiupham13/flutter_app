import 'package:flutter/material.dart';
import '../../../../models/reward_model.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../config/theme/style_tokens.dart';

/// Card widget hiển thị một voucher đã đổi
/// 
/// Features:
/// - Status badge (Active/Used/Expired)
/// - Title + value
/// - Expiry date display
/// - Visual differentiation by status
/// - Tap to view QR code detail
class VoucherCard extends StatelessWidget {
  final UserRedemption redemption;
  final VoidCallback onTap;

  const VoucherCard({
    super.key,
    required this.redemption,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isExpired = redemption.isExpired;
    final isUsed = redemption.status == RedemptionStatus.used;
    final isUsable = redemption.isUsable;

    // Determine card appearance based on status
    final Color borderColor;
    final Color backgroundColor;
    final double opacity;

    if (isUsable) {
      borderColor = AppColors.primary;
      backgroundColor = Colors.white;
      opacity = 1.0;
    } else if (isUsed) {
      borderColor = Colors.grey[400]!;
      backgroundColor = Colors.grey[50]!;
      opacity = 0.7;
    } else if (isExpired) {
      borderColor = Colors.red[300]!;
      backgroundColor = Colors.red[50]!;
      opacity = 0.7;
    } else {
      // pending, processing, etc.
      borderColor = Colors.orange[300]!;
      backgroundColor = Colors.orange[50]!;
      opacity = 0.9;
    }

    return Opacity(
      opacity: opacity,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: isUsable ? AppShadows.small : [],
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
                  // Header row: Type + Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Type badge
                      _buildTypeBadge(),
                      
                      // Status badge
                      _buildStatusBadge(),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    redemption.offerTitle,
                    style: AppFonts.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isUsable ? Colors.black : Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Value
                  Text(
                    'Giá trị: ${redemption.cashValue.toStringAsFixed(0)}đ',
                    style: AppFonts.bodyMedium.copyWith(
                      color: isUsable ? AppColors.primary : Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Divider
                  Divider(color: Colors.grey[300], height: 1),
                  const SizedBox(height: 12),

                  // Footer: Voucher code + Expiry date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Voucher code
                      if (redemption.voucherCode != null)
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.confirmation_number_outlined,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  redemption.voucherCode!,
                                  style: AppFonts.labelSmall.copyWith(
                                    color: Colors.grey[700],
                                    fontFamily: 'monospace',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Expiry date
                      if (redemption.expiryDate != null) ...[
                        const SizedBox(width: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: isExpired ? Colors.red[700] : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(redemption.expiryDate!),
                              style: AppFonts.labelSmall.copyWith(
                                color: isExpired ? Colors.red[700] : Colors.grey[700],
                                fontWeight: isExpired ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),

                  // QR code hint for usable vouchers
                  if (isUsable) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.qr_code_2,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Nhấn để xem QR code',
                            style: AppFonts.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Expired/Used message
                  if (isExpired && !isUsed) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.error_outline, size: 14, color: Colors.red[700]),
                        const SizedBox(width: 6),
                        Text(
                          'Voucher đã hết hạn',
                          style: AppFonts.labelSmall.copyWith(
                            color: Colors.red[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ] else if (isUsed) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.check_circle_outline, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(
                          'Đã sử dụng',
                          style: AppFonts.labelSmall.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
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
        color: redemption.type.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            redemption.type.emoji,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 4),
          Text(
            redemption.type.displayName,
            style: AppFonts.labelSmall.copyWith(
              color: redemption.type.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Build status badge
  Widget _buildStatusBadge() {
    final Color color;
    final String label;
    
    if (redemption.isUsable) {
      color = Colors.green;
      label = 'Khả dụng';
    } else if (redemption.status == RedemptionStatus.used) {
      color = Colors.grey;
      label = 'Đã dùng';
    } else if (redemption.isExpired) {
      color = Colors.red;
      label = 'Hết hạn';
    } else {
      color = redemption.status.color;
      label = redemption.status.displayName;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: AppFonts.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  /// Format date
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
