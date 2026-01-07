# 🎁 Coin Redemption UI Implementation Plan

> **Timeline:** 4-5 ngày  
> **Status:** 📝 Planning Complete, Ready for Implementation  
> **Created:** 06/01/2026

---

## 📊 OVERVIEW

Backend cho Coin Redemption System đã hoàn thành 100%. Task này là implement UI screens để user có thể:
- Xem danh sách offers có thể đổi coin
- Đổi coin lấy rewards (voucher/cash/premium)
- Quản lý vouchers đã đổi
- Sử dụng vouchers tại cửa hàng

---

## ✅ ĐÃ HOÀN THÀNH

### Backend (100%)
- ✅ Data models: RedemptionOffer, UserRedemption
- ✅ Repository methods: getOffers, redeemOffer, getHistory, cancelRedemption, etc.
- ✅ Riverpod providers: 13 providers
- ✅ Mock data: 12 offers + 5 partners
- ✅ Constants: Limits, minimums, cooldowns

### UI Partial (10%)
- ✅ RedemptionOffersScreen created (có lỗi cần fix)
- ✅ AppShadows updated (small, medium, large lists)

---

## 🚀 IMPLEMENTATION TASKS

### PHASE 1: Fix Foundation (0.5 ngày)

#### Task 1.1: Add AppFonts to style_tokens.dart
**File:** `what_eat_app/lib/config/theme/style_tokens.dart`

```dart
class AppFonts {
  // Headline styles
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );
  
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );
  
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );
  
  // Title styles
  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
  
  static const TextStyle titleMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
  
  static const TextStyle titleSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
  
  // Body styles
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );
  
  // Label styles
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );
}
```

**Effort:** 15 phút

---

#### Task 1.2: Update EmptyStateWidget parameters
**File:** `what_eat_app/lib/core/widgets/empty_state_widget.dart`

Add optional parameters:
```dart
class EmptyStateWidget extends StatelessWidget {
  final IconData? icon;           // NEW - optional custom icon
  final String title;             // Keep required
  final String? subtitle;         // NEW - optional subtitle
  final String? message;          // OLD - keep for compatibility
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyStateWidget({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    this.message,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon ?? Icons.inbox_outlined,  // Use custom icon or default
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: AppFonts.titleLarge.copyWith(color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null || message != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle ?? message!,
              style: AppFonts.bodyMedium.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
          if (onAction != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAction,
              child: Text(actionLabel ?? 'Thử lại'),
            ),
          ],
        ],
      ),
    );
  }
}
```

**Effort:** 10 phút

---

#### Task 1.3: Fix RedemptionOffersScreen imports & shadows
**File:** `what_eat_app/lib/features/rewards/presentation/redemption_offers_screen.dart`

1. Remove import: `import 'widgets/redemption_offer_card.dart';` (sẽ tạo sau)
2. Comment out RedemptionOfferCard usage (dòng 99-103)
3. Fix shadow syntax:
```dart
// OLD
boxShadow: [AppShadows.small],

// NEW
boxShadow: AppShadows.small,
```

**Effort:** 5 phút

---

### PHASE 2: Create Widgets (1 ngày)

#### Task 2.1: Create RedemptionOfferCard widget
**File:** `what_eat_app/lib/features/rewards/presentation/widgets/redemption_offer_card.dart`

**Features:**
- Card design với gradient theo type
- Show: title, description, coin required, cash value
- Type badge (emoji + name)
- Stock info (nếu có)
- Expiry date (nếu có)
- Can afford indicator (disabled state nếu không đủ coin)
- Tap to view details

**Design:**
```dart
import 'package:flutter/material.dart';
import '../../../../models/reward_model.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../config/theme/style_tokens.dart';

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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: canAfford ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: offer.type.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(offer.type.emoji, style: TextStyle(fontSize: 14)),
                        SizedBox(width: 4),
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
                  SizedBox(height: 12),
                  
                  // Title
                  Text(
                    offer.title,
                    style: AppFonts.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6),
                  
                  // Description
                  Text(
                    offer.description,
                    style: AppFonts.bodySmall.copyWith(color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 16),
                  
                  // Price row
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
                          SizedBox(height: 2),
                          Text(
                            '${offer.cashValue.toStringAsFixed(0)}đ',
                            style: AppFonts.titleMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      
                      // Coin required
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: canAfford
                              ? Colors.amber[50]
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: canAfford
                                ? Colors.amber[700]!
                                : Colors.grey[400]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.monetization_on,
                              color: canAfford ? Colors.amber[700] : Colors.grey,
                              size: 18,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '${offer.coinsRequired}',
                              style: AppFonts.titleSmall.copyWith(
                                fontWeight: FontWeight.bold,
                                color: canAfford ? Colors.amber[900] : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // Stock/Expiry info
                  if (offer.stockRemaining != null || offer.expiryDate != null) ...[
                    SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (offer.stockRemaining != null)
                          _buildInfoChip(
                            icon: Icons.inventory_2_outlined,
                            label: 'Còn ${offer.stockRemaining}',
                            color: Colors.orange,
                          ),
                        if (offer.expiryDate != null)
                          _buildInfoChip(
                            icon: Icons.access_time,
                            label: _formatDate(offer.expiryDate!),
                            color: Colors.red,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            // Disabled overlay
            if (!canAfford)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Không đủ coin',
                        style: AppFonts.labelMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required MaterialColor color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color[700]),
          SizedBox(width: 4),
          Text(
            label,
            style: AppFonts.labelSmall.copyWith(
              color: color[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
```

**Effort:** 2-3 giờ

---

### PHASE 3: My Vouchers Screen (1.5 ngày)

#### Task 3.1: Add qr_flutter package
**File:** `what_eat_app/pubspec.yaml`

```yaml
dependencies:
  qr_flutter: ^4.1.0
```

Run: `flutter pub get`

**Effort:** 2 phút

---

#### Task 3.2: Create MyVouchersScreen
**File:** `what_eat_app/lib/features/rewards/presentation/my_vouchers_screen.dart`

**Features:**
- Tab filter: All / Active / Used / Expired
- List vouchers
- Pull to refresh
- Empty state per tab
- Navigate to voucher detail

**Structure:**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/reward_model.dart';
import '../logic/rewards_provider.dart';
import 'widgets/voucher_card.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text('Voucher của tôi'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Tất cả'),
            Tab(text: 'Đang dùng'),
            Tab(text: 'Đã dùng'),
            Tab(text: 'Hết hạn'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVoucherList(null),                          // All
          _buildVoucherList(RedemptionStatus.completed),    // Active
          _buildVoucherList(RedemptionStatus.used),         // Used
          _buildVoucherList(null, onlyExpired: true),       // Expired
        ],
      ),
    );
  }

  Widget _buildVoucherList(RedemptionStatus? status, {bool onlyExpired = false}) {
    final vouchersAsync = status == RedemptionStatus.completed
        ? ref.watch(activeVouchersProvider)
        : ref.watch(redemptionsByStatusProvider(status));

    return vouchersAsync.when(
      data: (vouchers) {
        // Filter expired if needed
        final filtered = onlyExpired
            ? vouchers.where((v) => v.isExpired).toList()
            : vouchers;

        if (filtered.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.card_giftcard_outlined,
            title: 'Chưa có voucher',
            subtitle: _getEmptyMessage(status, onlyExpired),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(userRedemptionsProvider);
          },
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              return VoucherCard(
                redemption: filtered[index],
                onTap: () => _showVoucherDetail(filtered[index]),
              );
            },
          ),
        );
      },
      loading: () => Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  String _getEmptyMessage(RedemptionStatus? status, bool onlyExpired) {
    if (onlyExpired) return 'Không có voucher hết hạn';
    switch (status) {
      case RedemptionStatus.completed:
        return 'Bạn chưa có voucher nào đang sử dụng';
      case RedemptionStatus.used:
        return 'Bạn chưa sử dụng voucher nào';
      default:
        return 'Đổi coin để nhận voucher';
    }
  }

  void _showVoucherDetail(UserRedemption redemption) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VoucherDetailSheet(redemption: redemption),
    );
  }
}
```

**Effort:** 3-4 giờ

---

#### Task 3.3: Create VoucherCard widget
**File:** `what_eat_app/lib/features/rewards/presentation/widgets/voucher_card.dart`

**Features:**
- Show voucher info
- QR code preview (small)
- Status badge
- Expiry countdown
- Tap to see full QR code

**Effort:** 2-3 giờ

---

#### Task 3.4: Create VoucherDetailSheet
**File:** `what_eat_app/lib/features/rewards/presentation/widgets/voucher_detail_sheet.dart`

**Features:**
- Full voucher details
- Large QR code for scanning
- Voucher code text
- Terms & conditions
- Use voucher button (if active)
- Expiry info with countdown

**Effort:** 2-3 giờ

---

### PHASE 4: Routes & Navigation (0.5 ngày)

#### Task 4.1: Add routes to app_router.dart
**File:** `what_eat_app/lib/config/routes/app_router.dart`

Add after existing routes:
```dart
GoRoute(
  path: '/redemption-offers',
  name: 'redemption_offers',
  pageBuilder: (context, state) => _buildSlidePage(
    state: state,
    child: const RedemptionOffersScreen(),
    offset: const Offset(0.06, 0),
  ),
),
GoRoute(
  path: '/my-vouchers',
  name: 'my_vouchers',
  pageBuilder: (context, state) => _buildSlidePage(
    state: state,
    child: const MyVouchersScreen(),
    offset: const Offset(0.06, 0),
  ),
),
```

**Effort:** 10 phút

---

#### Task 4.2: Add navigation from Dashboard
**File:** `what_eat_app/lib/features/dashboard/presentation/dashboard_screen.dart`

Add button trong quick actions hoặc tạo card riêng:
```dart
ElevatedButton.icon(
  onPressed: () => context.push('/redemption-offers'),
  icon: Icon(Icons.card_giftcard),
  label: Text('Đổi Coin'),
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.accent,
  ),
)
```

**Effort:** 15 phút

---

#### Task 4.3: Add to Profile/Settings
**File:** `what_eat_app/lib/features/user/presentation/profile_screen.dart`

Add menu items:
```dart
ListTile(
  leading: Icon(Icons.card_giftcard),
  title: Text('Đổi Coin'),
  subtitle: Text('Xem offers và đổi coin'),
  trailing: Icon(Icons.chevron_right),
  onTap: () => context.push('/redemption-offers'),
),
ListTile(
  leading: Icon(Icons.confirmation_number),
  title: Text('Voucher của tôi'),
  subtitle: Text('Quản lý vouchers'),
  trailing: Icon(Icons.chevron_right),
  onTap: () => context.push('/my-vouchers'),
),
```

**Effort:** 10 phút

---

#### Task 4.4: Update CoinBalanceWidget tap action
**File:** `what_eat_app/lib/core/widgets/coin_balance_widget.dart`

Add navigation option:
```dart
onTap: onTap ?? () => context.push('/redemption-offers'),
```

**Effort:** 5 phút

---

#### Task 4.5: Add badge for active vouchers count
**File:** `what_eat_app/lib/features/user/presentation/profile_screen.dart` or Dashboard

Show badge với số vouchers active:
```dart
final vouchersCount = ref.watch(activeVouchersCountProvider);

// Display badge
if (vouchersCount > 0)
  Badge(
    label: Text('$vouchersCount'),
    child: Icon(Icons.card_giftcard),
  )
```

**Effort:** 15 phút

---

### PHASE 5: Testing & Polish (1 ngày)

#### Task 5.1: Manual Testing
- [ ] Test redemption flow end-to-end
- [ ] Test all filter tabs
- [ ] Test QR code generation
- [ ] Test expiry date logic
- [ ] Test can afford logic
- [ ] Test error states
- [ ] Test loading states
- [ ] Test empty states
- [ ] Test navigation
- [ ] Test pull to refresh

**Effort:** 3 giờ

---

#### Task 5.2: Bug Fixes
Fix any issues found during testing

**Effort:** 2-3 giờ

---

#### Task 5.3: UI Polish
- Adjust spacing
- Improve animations
- Better error messages
- Add haptic feedback
- Improve loading indicators

**Effort:** 2 giờ

---

#### Task 5.4: Documentation
Update docs:
- Feature completion summary
- User guide
- Screenshots
- API documentation

**Effort:** 1 giờ

---

## 📅 TIMELINE SUMMARY

### Day 1 (8h)
- **Morning (4h):**
  - Fix foundation (AppFonts, EmptyStateWidget, shadows)
  - Create RedemptionOfferCard widget
  - Fix RedemptionOffersScreen

- **Afternoon (4h):**
  - Test RedemptionOffersScreen
  - Start MyVouchersScreen

### Day 2 (8h)
- **Morning (4h):**
  - Complete MyVouchersScreen
  - Create VoucherCard widget

- **Afternoon (4h):**
  - Create VoucherDetailSheet
  - Test voucher screens

### Day 3 (8h)
- **Morning (4h):**
  - QR code integration
  - Add routes
  - Add navigation links

- **Afternoon (4h):**
  - Manual testing
  - Bug fixes

### Day 4 (4h)
- **Morning (2h):**
  - UI polish
  - Final testing

- **Afternoon (2h):**
  - Documentation
  - Deployment prep

---

## 🎯 ACCEPTANCE CRITERIA

- [ ] User có thể xem danh sách redemption offers
- [ ] User có thể filter offers theo type
- [ ] User có thể đổi coin lấy reward
- [ ] User thấy confirmation trước khi đổi
- [ ] User thấy success/error message sau khi đổi
- [ ] User có thể xem vouchers đã đổi
- [ ] User có thể scan QR code tại cửa hàng
- [ ] User thấy expiry date và countdown
- [ ] User không thể đổi offer không đủ coin
- [ ] System validate stock và expiry date
- [ ] Navigation flow mượt mà
- [ ] UI đẹp và consistent với app
- [ ] Error handling đầy đủ
- [ ] Loading states appropriate
- [ ] Empty states informative

---

## 📝 NOTES

### Dependencies
- qr_flutter: ^4.1.0 (for QR code generation)

### Design Considerations
- Use type.color for badges and cards
- Show clear can afford indicators
- Prominent QR codes for easy scanning
- Clear expiry warnings
- Smooth animations for better UX

### Security Considerations
- Validate redemption on backend (already done)
- Check coin balance before redemption
- Prevent double redemption
- Track usage for analytics

### Future Enhancements
- Push notifications for expiring vouchers
- Share vouchers with friends
- Voucher recommendations
- Gamification (redeem milestones)

---

**Document Version:** 1.0  
**Last Updated:** 06/01/2026  
**Status:** Ready for Implementation
