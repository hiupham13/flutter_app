import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/reward_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../config/theme/style_tokens.dart';
import '../logic/rewards_provider.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/empty_state_widget.dart';
import 'widgets/redemption_offer_card.dart';

/// Màn hình hiển thị danh sách offers có thể đổi coin
/// 
/// Features:
/// - Hiển thị coin balance
/// - Filter theo type (All/Voucher/Cash/Premium)
/// - List offers với card design
/// - Pull-to-refresh
/// - Empty state handling
/// - Navigate to redemption detail
class RedemptionOffersScreen extends ConsumerStatefulWidget {
  const RedemptionOffersScreen({super.key});

  @override
  ConsumerState<RedemptionOffersScreen> createState() =>
      _RedemptionOffersScreenState();
}

class _RedemptionOffersScreenState
    extends ConsumerState<RedemptionOffersScreen> {
  RedemptionType? _selectedType;

  @override
  Widget build(BuildContext context) {
    final coinBalance = ref.watch(coinBalanceProvider);
    final offersAsync = _selectedType == null
        ? ref.watch(redemptionOffersProvider)
        : ref.watch(redemptionOffersByTypeProvider(_selectedType));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Đổi Coin'),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          // Coin balance chip
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              avatar: const Icon(
                Icons.monetization_on,
                color: Colors.amber,
                size: 20,
              ),
              label: Text(
                '$coinBalance',
                style: AppFonts.labelLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              backgroundColor: AppColors.primary.withOpacity(0.2),
              side: BorderSide.none,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          _buildFilterChips(),
          
          // Offers list
          Expanded(
            child: offersAsync.when(
              data: (offers) {
                if (offers.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.card_giftcard_outlined,
                    title: 'Chưa có offers',
                    subtitle: _selectedType == null
                        ? 'Hiện tại chưa có offers nào'
                        : 'Không có offers loại ${_selectedType!.displayName}',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(redemptionOffersProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: offers.length,
                    itemBuilder: (context, index) {
                      final offer = offers[index];
                      final canAfford = coinBalance >= offer.coinsRequired;
                      
                      return RedemptionOfferCard(
                        offer: offer,
                        canAfford: canAfford,
                        onTap: () => _showRedemptionDetail(offer, canAfford),
                      );
                    },
                  ),
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
                      'Lỗi tải offers',
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
                        ref.invalidate(redemptionOffersProvider);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build filter chips
  Widget _buildFilterChips() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: AppShadows.small,
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip(
            label: 'Tất cả',
            isSelected: _selectedType == null,
            onTap: () => setState(() => _selectedType = null),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: '${RedemptionType.voucher.emoji} Voucher',
            isSelected: _selectedType == RedemptionType.voucher,
            onTap: () => setState(() => _selectedType = RedemptionType.voucher),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: '${RedemptionType.cash.emoji} Rút tiền',
            isSelected: _selectedType == RedemptionType.cash,
            onTap: () => setState(() => _selectedType = RedemptionType.cash),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: '${RedemptionType.premium.emoji} Premium',
            isSelected: _selectedType == RedemptionType.premium,
            onTap: () => setState(() => _selectedType = RedemptionType.premium),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: AppFonts.labelMedium.copyWith(
        color: isSelected ? AppColors.primary : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  /// Show redemption detail bottom sheet
  void _showRedemptionDetail(RedemptionOffer offer, bool canAfford) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildRedemptionDetailSheet(offer, canAfford),
    );
  }

  Widget _buildRedemptionDetailSheet(RedemptionOffer offer, bool canAfford) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
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
                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: offer.type.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          offer.type.emoji,
                          style: const TextStyle(fontSize: 16),
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
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    offer.title,
                    style: AppFonts.headlineSmall,
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    offer.description,
                    style: AppFonts.bodyMedium.copyWith(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 24),

                  // Price info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Giá trị',
                              style: AppFonts.labelSmall.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${offer.cashValue.toStringAsFixed(0)}đ',
                              style: AppFonts.titleLarge.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Coin cần',
                              style: AppFonts.labelSmall.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.monetization_on,
                                  color: Colors.amber,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${offer.coinsRequired}',
                                  style: AppFonts.titleLarge.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Terms & conditions
                  if (offer.terms.isNotEmpty) ...[
                    Text(
                      'Điều kiện sử dụng',
                      style: AppFonts.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ...offer.terms.map((term) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• '),
                              Expanded(
                                child: Text(
                                  term,
                                  style: AppFonts.bodySmall.copyWith(
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 24),
                  ],

                  // Stock info
                  if (offer.stockRemaining != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              color: Colors.orange[700], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Còn ${offer.stockRemaining} suất',
                            style: AppFonts.bodySmall.copyWith(
                              color: Colors.orange[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Expiry info
                  if (offer.expiryDate != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time,
                              color: Colors.red[700], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Hết hạn: ${_formatDate(offer.expiryDate!)}',
                            style: AppFonts.bodySmall.copyWith(
                              color: Colors.red[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
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
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: const Text('Đóng'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: canAfford
                          ? () => _confirmRedemption(offer)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                      child: Text(
                        canAfford ? 'Đổi ngay' : 'Không đủ coin',
                        style: AppFonts.labelLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
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

  /// Confirm redemption dialog
  Future<void> _confirmRedemption(RedemptionOffer offer) async {
    Navigator.pop(context); // Close detail sheet

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đổi coin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn chắc chắn muốn đổi ${offer.coinsRequired} coin để nhận:'),
            const SizedBox(height: 12),
            Text(
              offer.title,
              style: AppFonts.titleMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Giá trị: ${offer.cashValue.toStringAsFixed(0)}đ',
              style: AppFonts.bodyMedium.copyWith(color: Colors.grey[700]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _processRedemption(offer);
    }
  }

  /// Process redemption
  Future<void> _processRedemption(RedemptionOffer offer) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: LoadingIndicator()),
      );

      // Call redemption API
      final redemption = await ref
          .read(redemptionControllerProvider)
          .redeemOffer(offer.id);

      if (mounted) {
        Navigator.pop(context); // Close loading

        // Show success
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[600], size: 32),
                const SizedBox(width: 12),
                const Text('Đổi thành công!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bạn đã đổi thành công ${offer.title}'),
                const SizedBox(height: 12),
                if (redemption.type == RedemptionType.voucher) ...[
                  const Text('Voucher đã được thêm vào "Voucher của tôi".'),
                  const Text('Bạn có thể sử dụng tại cửa hàng tham gia.'),
                ],
              ],
            ),
            actions: [
              if (redemption.type == RedemptionType.voucher)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed('my_vouchers');
                  },
                  child: const Text('Xem voucher'),
                ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading

        // Show error
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 32),
                SizedBox(width: 12),
                Text('Lỗi'),
              ],
            ),
            content: Text('Không thể đổi coin: ${e.toString()}'),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  /// Format date
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
