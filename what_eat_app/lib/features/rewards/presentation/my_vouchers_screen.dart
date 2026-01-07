import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../models/reward_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../config/theme/style_tokens.dart';
import '../logic/rewards_provider.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/empty_state_widget.dart';
import 'widgets/voucher_card.dart';

/// Màn hình "Voucher của tôi"
/// 
/// Features:
/// - Hiển thị danh sách voucher đã đổi
/// - Filter theo status (All/Active/Used/Expired)
/// - Tap voucher để xem QR code chi tiết
/// - Pull-to-refresh
/// - Empty state cho từng filter
class MyVouchersScreen extends ConsumerStatefulWidget {
  const MyVouchersScreen({super.key});

  @override
  ConsumerState<MyVouchersScreen> createState() => _MyVouchersScreenState();
}

class _MyVouchersScreenState extends ConsumerState<MyVouchersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allVouchersAsync = ref.watch(userRedemptionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Voucher của tôi'),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: AppFonts.labelMedium.copyWith(fontWeight: FontWeight.bold),
          unselectedLabelStyle: AppFonts.labelMedium,
          tabs: const [
            Tab(text: 'Tất cả'),
            Tab(text: 'Có thể dùng'),
            Tab(text: 'Đã dùng'),
            Tab(text: 'Hết hạn'),
          ],
        ),
      ),
      body: allVouchersAsync.when(
        data: (allVouchers) {
          // Filter vouchers by status
          // Active = completed and not expired and not used
          final activeVouchers = allVouchers
              .where((v) =>
                  v.status == RedemptionStatus.completed &&
                  v.status != RedemptionStatus.used &&
                  !v.isExpired)
              .toList();
          final usedVouchers = allVouchers
              .where((v) => v.status == RedemptionStatus.used)
              .toList();
          // Expired = has expiryDate and is past it
          final expiredVouchers = allVouchers
              .where((v) => v.isExpired)
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildVoucherList(allVouchers, 'all'),
              _buildVoucherList(activeVouchers, 'active'),
              _buildVoucherList(usedVouchers, 'used'),
              _buildVoucherList(expiredVouchers, 'expired'),
            ],
          );
        },
        loading: () => const Center(child: LoadingIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Lỗi tải vouchers',
                style: AppFonts.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: AppFonts.bodySmall.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(userRedemptionsProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build voucher list for a tab
  Widget _buildVoucherList(List<UserRedemption> vouchers, String filterType) {
    if (vouchers.isEmpty) {
      return _buildEmptyState(filterType);
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(userRedemptionsProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: vouchers.length,
        itemBuilder: (context, index) {
          final voucher = vouchers[index];
          return VoucherCard(
            redemption: voucher,
            onTap: () => _showVoucherDetail(voucher),
          );
        },
      ),
    );
  }

  /// Build empty state for each filter
  Widget _buildEmptyState(String filterType) {
    String title;
    String subtitle;
    IconData icon;

    switch (filterType) {
      case 'all':
        title = 'Chưa có voucher nào';
        subtitle = 'Đổi coin để nhận voucher ưu đãi';
        icon = Icons.card_giftcard_outlined;
        break;
      case 'active':
        title = 'Không có voucher khả dụng';
        subtitle = 'Đổi coin để nhận voucher mới';
        icon = Icons.local_activity_outlined;
        break;
      case 'used':
        title = 'Chưa sử dụng voucher nào';
        subtitle = 'Voucher đã sử dụng sẽ hiển thị ở đây';
        icon = Icons.done_all;
        break;
      case 'expired':
        title = 'Không có voucher hết hạn';
        subtitle = 'Voucher hết hạn sẽ hiển thị ở đây';
        icon = Icons.history;
        break;
      default:
        title = 'Không có voucher';
        subtitle = '';
        icon = Icons.card_giftcard_outlined;
    }

    return Center(
      child: EmptyStateWidget(
        icon: icon,
        title: title,
        subtitle: subtitle,
        actionLabel: filterType == 'all' || filterType == 'active'
            ? 'Đổi coin'
            : null,
        onAction: filterType == 'all' || filterType == 'active'
            ? () {
                Navigator.pop(context); // Go back to redemption offers
              }
            : null,
      ),
    );
  }

  /// Show voucher detail bottom sheet với QR code
  void _showVoucherDetail(UserRedemption voucher) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildVoucherDetailSheet(voucher),
    );
  }

  Widget _buildVoucherDetailSheet(UserRedemption voucher) {
    final isExpired = voucher.isExpired;
    final isUsed = voucher.status == RedemptionStatus.used;
    final canUse = voucher.isUsable; // completed, not expired, not used

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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Status badge
                  _buildStatusBadge(voucher.status),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    voucher.offerTitle,
                    style: AppFonts.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Value
                  Text(
                    '${voucher.cashValue.toStringAsFixed(0)}đ',
                    style: AppFonts.titleLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // QR Code (only if active)
                  if (canUse) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[300]!),
                        boxShadow: AppShadows.medium,
                      ),
                      child: Column(
                        children: [
                          // QR Code
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: QrImageView(
                              data: voucher.qrCodeData ?? voucher.voucherCode ?? voucher.id,
                              version: QrVersions.auto,
                              size: 200,
                              backgroundColor: Colors.white,
                              errorCorrectionLevel: QrErrorCorrectLevel.M,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Mã: ${voucher.voucherCode ?? 'N/A'}',
                            style: AppFonts.labelLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Đưa mã QR này cho nhân viên để quét',
                      style: AppFonts.bodySmall.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Redemption info
                  _buildInfoRow('Ngày đổi', _formatDate(voucher.redeemedAt)),
                  if (voucher.expiryDate != null)
                    _buildInfoRow('Hết hạn', _formatDate(voucher.expiryDate!)),
                  if (voucher.completedAt != null)
                    _buildInfoRow('Hoàn thành', _formatDate(voucher.completedAt!)),
                  const SizedBox(height: 24),

                  // Note: Terms are stored in RedemptionOffer, not UserRedemption
                  // Could fetch offer details if needed, but skip for now

                  // Expired/Used message
                  if (isExpired || isUsed) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isExpired ? Colors.red[50] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isExpired ? Icons.error_outline : Icons.check_circle_outline,
                            color: isExpired ? Colors.red[700] : Colors.grey[700],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isExpired
                                  ? 'Voucher này đã hết hạn và không thể sử dụng'
                                  : 'Voucher này đã được sử dụng',
                              style: AppFonts.bodyMedium.copyWith(
                                color: isExpired ? Colors.red[700] : Colors.grey[700],
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

          // Close button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: AppShadows.medium,
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Đóng'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build status badge
  Widget _buildStatusBadge(RedemptionStatus status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case RedemptionStatus.completed:
        color = Colors.green;
        label = 'Có thể sử dụng';
        icon = Icons.check_circle;
        break;
      case RedemptionStatus.used:
        color = Colors.grey;
        label = 'Đã sử dụng';
        icon = Icons.done_all;
        break;
      case RedemptionStatus.pending:
        color = Colors.orange;
        label = 'Chờ xử lý';
        icon = Icons.hourglass_empty;
        break;
      case RedemptionStatus.processing:
        color = Colors.blue;
        label = 'Đang xử lý';
        icon = Icons.sync;
        break;
      case RedemptionStatus.failed:
        color = Colors.red;
        label = 'Thất bại';
        icon = Icons.error_outline;
        break;
      case RedemptionStatus.cancelled:
        color = Colors.grey;
        label = 'Đã hủy';
        icon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppFonts.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Build info row
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppFonts.bodyMedium.copyWith(color: Colors.grey[600]),
          ),
          Text(
            value,
            style: AppFonts.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  /// Format date
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
