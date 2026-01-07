# 🎁 Đề xuất: Hệ thống quy đổi xu (Coin Redemption)

**Generated:** 2026-01-06  
**Status:** Proposal / Design Phase  
**Priority:** Medium-High (Feature expansion)

---

## 📊 Tổng quan

### Hiện trạng
- ✅ Người dùng kiếm xu từ Mystery Boxes
- ✅ Xu được tích lũy trong tài khoản
- ❌ **Chưa có cách sử dụng xu** (chỉ tích lũy)

### Vấn đề
- Xu không có giá trị thực tế → giảm động lực tham gia
- Người dùng hỏi: "Tôi dùng xu để làm gì?"
- Thiếu vòng quay kinh tế (earn → spend → earn)

### Giải pháp đề xuất
**Hệ thống quy đổi xu → Rewards thực tế:**
1. Tiền mặt (VND) - Chuyển khoản
2. Voucher nhà hàng - Giảm giá món ăn
3. Quà tặng độc quyền - Merchandise, food vouchers

---

## 💰 Phân tích Coin Economy hiện tại

### Nguồn thu xu (Earning)
| Nguồn | Số xu | Tần suất | Ghi chú |
|-------|-------|----------|---------|
| Bronze Box | 10-100 | 70% | Phổ biến |
| Silver Box | 100-500 | 20% | Hiếm |
| Gold Box | 500-1,000 | 8% | Rất hiếm |
| Diamond Box | 1,000-5,000 | 2% | Cực hiếm |
| Daily Login | 10 | Hàng ngày | Bonus |
| First Time | 100 | 1 lần | Welcome |
| Streak 3 days | +10% | Milestone | Multiplier |
| Streak 7 days | +25% | Milestone | Multiplier |
| Streak 30 days | +100% | Milestone | Multiplier |

**Trung bình 1 user/ngày:**
- 2-3 boxes × ~150 coins = **~300-450 coins/day**
- Daily bonus: +10 coins
- **Total: ~350-500 coins/day** (active user)

**Tích lũy 1 tháng:** ~10,500-15,000 coins

### Giới hạn hiện tại
- Max 5 boxes/day (anti-fraud)
- Cooldown 2h giữa các boxes
- Yêu cầu location verification
- Coin expiry: 90 ngày

---

## 🎯 Đề xuất 3 tầng Redemption

### 🥉 Tier 1: Voucher nhà hàng (Entry Level)
**Mục tiêu:** Dễ đạt, khuyến khích participation

| Voucher | Giá trị | Xu cần | Ưu đãi |
|---------|---------|--------|--------|
| Voucher 10K | 10,000 VND | 500 | Giảm 10K cho bill từ 50K |
| Voucher 20K | 20,000 VND | 900 | Giảm 20K cho bill từ 100K |
| Voucher 50K | 50,000 VND | 2,000 | Giảm 50K cho bill từ 200K |
| Free Drink | 15,000 VND | 600 | Nước ngọt/trà miễn phí |
| Free Dessert | 25,000 VND | 1,000 | Tráng miệng miễn phí |

**Tính năng:**
- Voucher code dạng QR
- Valid 30 ngày sau claim
- Dùng 1 lần tại nhà hàng partner
- Fake data: Mock các nhà hàng đối tác

**Thời gian đạt được:** 2-7 ngày cho active user

---

### 🥈 Tier 2: Cash Withdrawal (Mid Level)
**Mục tiêu:** Reward for loyal users

| Cash Amount | Giá trị VND | Xu cần | Tỷ lệ quy đổi |
|-------------|-------------|--------|---------------|
| 20,000 VND | 20,000 | 1,000 | 1:20 |
| 50,000 VND | 50,000 | 2,500 | 1:20 |
| 100,000 VND | 100,000 | 5,000 | 1:20 |
| 200,000 VND | 200,000 | 10,000 | 1:20 |

**Tỷ lệ quy đổi:** 1,000 coins = 50,000 VND (như đã define trong constants)

**Yêu cầu:**
- KYC verification (fake: chỉ cần phone number)
- Minimum balance: 1,000 coins
- Processing time: 3-5 ngày (fake: instant)
- Chuyển khoản qua bank/Momo/ZaloPay (fake: show success message)

**Thời gian đạt được:** 7-30 ngày cho active user

---

### 🥇 Tier 3: Premium Rewards (High Level)
**Mục tiêu:** Aspirational goals

| Reward | Giá trị | Xu cần | Đặc biệt |
|--------|---------|--------|----------|
| Combo Meal | 100,000 VND | 5,000 | 2 món + nước tại partner |
| Monthly Pass | 300,000 VND | 15,000 | Free 1 món/ngày x 30 ngày |
| VIP Member | 500,000 VND | 25,000 | Priority support, exclusive boxes |
| Food Festival Pass | 200,000 VND | 10,000 | Vé tham gia sự kiện |
| Cooking Class | 400,000 VND | 20,000 | Workshop nấu ăn |

**Thời gian đạt được:** 1-3 tháng cho very active user

---

## 🏗️ Kiến trúc kỹ thuật

### 1. Data Models

#### RedemptionOffer Model (Mới)
```dart
enum RedemptionType {
  voucher,      // Voucher nhà hàng
  cash,         // Rút tiền
  premium,      // Premium rewards
  merchandise,  // Quà tặng
}

enum RedemptionStatus {
  pending,      // Chờ xử lý
  processing,   // Đang xử lý
  completed,    // Hoàn thành
  failed,       // Thất bại
  cancelled,    // Đã hủy
}

class RedemptionOffer {
  final String id;
  final String title;
  final String description;
  final RedemptionType type;
  final int coinsRequired;
  final int cashValue;           // VND
  final String? imageUrl;
  final bool isActive;
  final DateTime? expiryDate;
  final int? stockRemaining;     // Null = unlimited
  final List<String> terms;      // Điều kiện sử dụng
  final Map<String, dynamic>? metadata; // Partner info, etc.
}
```

#### UserRedemption Model (Mới)
```dart
class UserRedemption {
  final String id;
  final String userId;
  final String offerId;
  final RedemptionType type;
  final int coinsSpent;
  final int cashValue;
  final RedemptionStatus status;
  final DateTime redeemedAt;
  final DateTime? completedAt;
  final String? voucherCode;     // For voucher type
  final String? qrCode;          // QR for in-store use
  final String? bankInfo;        // For cash type
  final String? failureReason;
  final DateTime? expiryDate;
}
```

#### Extend TransactionType
```dart
enum TransactionType {
  earned,           // Existing
  spent,            // Existing
  bonus,            // Existing
  refund,           // Existing
  redemption,       // NEW: Spent on redemption
  redemptionRefund, // NEW: Refund from failed redemption
}
```

---

### 2. Firebase Collections Structure

```
users/
  {userId}/
    rewards_stats/
      summary         (existing)
    
    mystery_boxes/    (existing)
    
    coin_transactions/ (existing)
    
    redemptions/      (NEW)
      {redemptionId}
        - offer_id
        - coins_spent
        - status
        - redeemed_at
        - voucher_code
        - qr_code
        - expires_at
        - etc.

redemption_offers/    (NEW - global collection)
  {offerId}
    - title
    - type
    - coins_required
    - cash_value
    - stock_remaining
    - is_active
    - etc.

redemption_partners/  (NEW - fake data)
  {partnerId}
    - name
    - logo_url
    - locations[]
    - accepted_vouchers[]
```

---

### 3. Repository Methods (Extend RewardsRepository)

```dart
class RewardsRepository {
  // ========== EXISTING METHODS ==========
  // getUserStats()
  // generateMysteryBox()
  // openMysteryBox()
  // _addCoins()
  // _spendCoins()
  
  // ========== NEW REDEMPTION METHODS ==========
  
  /// Get available redemption offers
  Future<List<RedemptionOffer>> getRedemptionOffers({
    RedemptionType? type,
    int? maxCoins,
  });
  
  /// Redeem an offer
  Future<UserRedemption> redeemOffer(String offerId);
  
  /// Get user's redemption history
  Future<List<UserRedemption>> getRedemptionHistory({
    int limit = 50,
  });
  
  /// Get active vouchers (not expired, not used)
  Future<List<UserRedemption>> getActiveVouchers();
  
  /// Use a voucher (mark as used)
  Future<void> useVoucher(String redemptionId);
  
  /// Cancel redemption (refund coins)
  Future<void> cancelRedemption(String redemptionId);
  
  /// Process cash withdrawal (admin action - fake)
  Future<void> processCashWithdrawal(String redemptionId);
}
```

---

### 4. Provider (Riverpod)

```dart
// Redemption offers provider
final redemptionOffersProvider = FutureProvider.autoDispose
    .family<List<RedemptionOffer>, RedemptionType?>((ref, type) async {
  final userId = ref.watch(currentUserProvider).value?.uid;
  if (userId == null) return [];
  
  final repo = RewardsRepository(userId: userId);
  return repo.getRedemptionOffers(type: type);
});

// User redemptions provider
final userRedemptionsProvider = StreamProvider.autoDispose((ref) {
  final userId = ref.watch(currentUserProvider).value?.uid;
  if (userId == null) return Stream.value([]);
  
  final repo = RewardsRepository(userId: userId);
  return repo.watchUserRedemptions();
});

// Active vouchers provider
final activeVouchersProvider = FutureProvider.autoDispose((ref) async {
  final userId = ref.watch(currentUserProvider).value?.uid;
  if (userId == null) return [];
  
  final repo = RewardsRepository(userId: userId);
  return repo.getActiveVouchers();
});
```

---

## 🎨 UI/UX Design

### 1. Redemption Store Screen (Mới)

**Navigation:** Bottom tab hoặc từ Profile → "Rewards Store"

**Layout:**
```
┌─────────────────────────────────────┐
│  💰 Số dư: 2,450 coins             │
│  (≈ 122,500 VND)                   │
├─────────────────────────────────────┤
│  [Voucher] [Tiền] [Premium] [All]  │ ← Tabs
├─────────────────────────────────────┤
│  🎟️ Voucher 10K                     │
│  500 coins | Còn 120 voucher       │
│  [Đổi ngay] →                       │
├─────────────────────────────────────┤
│  🎟️ Voucher 20K                     │
│  900 coins | Còn 85 voucher        │
│  [Đổi ngay] →                       │
├─────────────────────────────────────┤
│  💵 Rút 50,000 VND                  │
│  2,500 coins | Xử lý 3-5 ngày     │
│  [Yêu cầu rút] →                    │
└─────────────────────────────────────┘
```

**Features:**
- Filter by type (Voucher/Cash/Premium)
- Sort by coins required
- Show coin balance conversion
- Visual progress bar (bạn còn X coins nữa để đổi Y)

---

### 2. Redemption Confirmation Dialog

```
┌─────────────────────────────────────┐
│  ✅ Xác nhận đổi thưởng             │
├─────────────────────────────────────┤
│  🎟️ Voucher 20K                     │
│                                     │
│  Giá trị: 20,000 VND               │
│  Chi phí: 900 coins                │
│                                     │
│  Số dư hiện tại: 2,450 coins       │
│  Số dư sau đổi: 1,550 coins        │
│                                     │
│  ⚠️ Điều kiện:                      │
│  • Valid 30 ngày                   │
│  • Dùng cho bill từ 100K           │
│  • Không hoàn xu nếu hủy           │
│                                     │
│  [Hủy]        [Xác nhận đổi] →    │
└─────────────────────────────────────┘
```

---

### 3. My Vouchers Screen (Mới)

**Navigation:** From Profile or Redemption Store

```
┌─────────────────────────────────────┐
│  📱 Voucher của tôi                 │
├─────────────────────────────────────┤
│  [Đang dùng] [Đã dùng] [Hết hạn]   │ ← Tabs
├─────────────────────────────────────┤
│  🎟️ Voucher 20K                     │
│  Giảm 20K cho bill từ 100K         │
│  Hết hạn: 25/01/2026               │
│  [Xem QR Code] →                   │
├─────────────────────────────────────┤
│  💵 Rút 50,000 VND                  │
│  ⏳ Đang xử lý                      │
│  Dự kiến: 10/01/2026               │
│  [Chi tiết] →                       │
└─────────────────────────────────────┘
```

---

### 4. Voucher QR Screen

```
┌─────────────────────────────────────┐
│  🎟️ Voucher 20K                     │
├─────────────────────────────────────┤
│        ┌─────────────┐              │
│        │             │              │
│        │  QR CODE    │              │
│        │             │              │
│        └─────────────┘              │
│                                     │
│  Mã: VCH-2450-ABCD                 │
│                                     │
│  Cho nhân viên quét mã này khi     │
│  thanh toán để áp dụng ưu đãi.     │
│                                     │
│  ⚠️ Lưu ý:                          │
│  • Valid đến 25/01/2026            │
│  • Bill tối thiểu 100,000 VND      │
│  • Dùng 1 lần duy nhất             │
│                                     │
│  [Chia sẻ voucher] [Đóng]          │
└─────────────────────────────────────┘
```

---

### 5. Cash Withdrawal Flow

**Step 1: Select amount**
```
┌─────────────────────────────────────┐
│  💰 Rút tiền                        │
├─────────────────────────────────────┤
│  Chọn số tiền muốn rút:            │
│                                     │
│  ⭕ 20,000 VND (1,000 coins)        │
│  ⭕ 50,000 VND (2,500 coins)        │
│  ⭕ 100,000 VND (5,000 coins)       │
│  ⭕ 200,000 VND (10,000 coins)      │
│                                     │
│  [Tiếp tục] →                      │
└─────────────────────────────────────┘
```

**Step 2: Bank info (fake)**
```
┌─────────────────────────────────────┐
│  🏦 Thông tin nhận tiền             │
├─────────────────────────────────────┤
│  Ngân hàng:                        │
│  [Chọn ngân hàng ▼]                │
│                                     │
│  Số tài khoản:                     │
│  [____________]                     │
│                                     │
│  Tên chủ tài khoản:                │
│  [____________]                     │
│                                     │
│  ⏱️ Thời gian xử lý: 3-5 ngày      │
│                                     │
│  [Xác nhận rút tiền] →             │
└─────────────────────────────────────┘
```

**Step 3: Success (fake)**
```
┌─────────────────────────────────────┐
│  ✅ Yêu cầu rút tiền thành công     │
├─────────────────────────────────────┤
│  Số tiền: 50,000 VND               │
│  Mã giao dịch: WD-2450-XYZ         │
│                                     │
│  Tiền sẽ được chuyển đến tài khoản │
│  của bạn trong vòng 3-5 ngày làm   │
│  việc.                             │
│                                     │
│  Theo dõi tình trạng tại:          │
│  [Lịch sử giao dịch] →             │
│                                     │
│  [Đóng]                            │
└─────────────────────────────────────┘
```

---

## 🎮 Gamification Enhancements

### 1. Achievement Badges (Mới)
| Badge | Requirement | Reward |
|-------|-------------|--------|
| 🎫 First Redeemer | Đổi voucher đầu tiên | +50 coins |
| 💰 Cash Master | Rút tiền thành công | +100 coins |
| 🏆 Big Spender | Đổi 10,000 coins | +500 coins |
| 🌟 VIP Member | Đổi Premium reward | +1,000 coins |

### 2. Flash Deals (Tạm thời)
- Giảm 20% coins cần thiết
- Limited time (24h)
- Limited stock (100 vouchers)
- Create urgency

### 3. Referral Program
- Mời bạn bè → cả 2 nhận 200 coins
- Bạn bè đổi voucher đầu tiên → bạn nhận thêm 100 coins

---

## 📊 Fake Data Strategy

### Mock Redemption Offers

```dart
final mockRedemptionOffers = [
  // TIER 1: Vouchers
  RedemptionOffer(
    id: 'vchr_10k',
    title: 'Voucher 10,000 VND',
    description: 'Giảm 10K cho bill từ 50K tại các nhà hàng đối tác',
    type: RedemptionType.voucher,
    coinsRequired: 500,
    cashValue: 10000,
    imageUrl: 'https://...',
    isActive: true,
    stockRemaining: 120,
    terms: [
      'Valid 30 ngày từ ngày đổi',
      'Áp dụng cho bill từ 50,000 VND',
      'Không hoàn trả xu nếu hủy',
      'Dùng 1 lần duy nhất',
    ],
  ),
  
  // TIER 2: Cash
  RedemptionOffer(
    id: 'cash_50k',
    title: 'Rút 50,000 VND',
    description: 'Chuyển khoản 50K vào tài khoản của bạn',
    type: RedemptionType.cash,
    coinsRequired: 2500,
    cashValue: 50000,
    isActive: true,
    terms: [
      'Xử lý trong 3-5 ngày làm việc',
      'Cần xác minh số điện thoại',
      'Không áp dụng cho tài khoản mới (<7 ngày)',
    ],
  ),
  
  // TIER 3: Premium
  RedemptionOffer(
    id: 'monthly_pass',
    title: 'Monthly VIP Pass',
    description: 'Free 1 món/ngày x 30 ngày tại các nhà hàng đối tác',
    type: RedemptionType.premium,
    coinsRequired: 15000,
    cashValue: 300000,
    imageUrl: 'https://...',
    isActive: true,
    stockRemaining: 20,
    terms: [
      'Valid 30 ngày từ ngày kích hoạt',
      'Chọn 1 món dưới 100K mỗi ngày',
      'Không chuyển nhượng',
      'Không hoàn trả xu',
    ],
  ),
];
```

### Mock Partner Restaurants

```dart
final mockPartners = [
  {
    'id': 'partner_1',
    'name': 'Cơm Tấm Sài Gòn',
    'logo': 'https://...',
    'locations': ['Quận 1', 'Quận 3', 'Quận 5'],
    'accepted_vouchers': ['vchr_10k', 'vchr_20k'],
  },
  {
    'id': 'partner_2',
    'name': 'Phở 24',
    'logo': 'https://...',
    'locations': ['Quận 1', 'Quận 7', 'Bình Thạnh'],
    'accepted_vouchers': ['vchr_10k', 'vchr_20k', 'vchr_50k'],
  },
  // ... more partners
];
```

### Mock Processing Flow

```dart
Future<void> _mockCashWithdrawal(String redemptionId) async {
  // Step 1: Create redemption with status = pending
  await _createRedemption(redemptionId, status: RedemptionStatus.pending);
  
  // Step 2: Simulate processing (instant for demo)
  await Future.delayed(Duration(seconds: 2));
  
  // Step 3: Update to processing
  await _updateRedemptionStatus(redemptionId, RedemptionStatus.processing);
  
  // Step 4: Simulate completion after 5 seconds (in real: 3-5 days)
  await Future.delayed(Duration(seconds: 5));
  
  // Step 5: Mark as completed
  await _updateRedemptionStatus(redemptionId, RedemptionStatus.completed);
  
  // In production: This would be manual admin approval
}
```

---

## 🔐 Security & Anti-Fraud

### 1. Redemption Limits
```dart
class RedemptionLimits {
  // Per day
  static const int maxVouchersPerDay = 3;
  static const int maxCashPerDay = 100000; // VND
  
  // Per week
  static const int maxVouchersPerWeek = 10;
  static const int maxCashPerWeek = 500000; // VND
  
  // Per month
  static const int maxTotalRedemptionsPerMonth = 50;
  
  // Account requirements
  static const int minAccountAgeDays = 7; // For cash withdrawal
  static const int minBoxesOpenedForCash = 10;
}
```

### 2. Verification Requirements
| Redemption Type | Requirements |
|-----------------|--------------|
| Voucher (<1000 coins) | None |
| Voucher (>1000 coins) | Phone verified |
| Cash (any amount) | Phone + Account >7 days |
| Premium (>10k coins) | Phone + Email + 10+ boxes opened |

### 3. Fraud Detection
```dart
// Check suspicious patterns
- Rút tiền ngay sau khi kiếm xu (< 1 giờ)
- Multiple accounts cùng 1 số điện thoại
- Redemption velocity quá cao (>10 trong 1 giờ)
- Same bank account used across multiple users
```

---

## 📈 Analytics & KPIs

### Track these metrics:
1. **Redemption Rate:** % users đổi thưởng / total users
2. **Average Time to First Redemption:** Ngày từ lúc đăng ký đến đổi đầu tiên
3. **Popular Redemptions:** Voucher nào được đổi nhiều nhất
4. **Coin Burn Rate:** Số xu được tiêu mỗi ngày
5. **Refund Rate:** % redemptions bị hủy/failed

---

## 🗓️ Implementation Roadmap

### Phase 1: Foundation (Week 1-2)
- [ ] Tạo data models (RedemptionOffer, UserRedemption)
- [ ] Extend RewardsRepository với redemption methods
- [ ] Setup Firebase collections
- [ ] Seed fake redemption offers
- [ ] Unit tests cho redemption logic

### Phase 2: Voucher System (Week 3-4)
- [ ] Redemption Store screen UI
- [ ] Voucher redemption flow
- [ ] QR code generation
- [ ] My Vouchers screen
- [ ] Voucher usage tracking

### Phase 3: Cash Withdrawal (Week 5-6)
- [ ] Cash withdrawal form UI
- [ ] Bank info collection (fake)
- [ ] Processing status tracking
- [ ] Mock approval flow
- [ ] Transaction history integration

### Phase 4: Premium Rewards (Week 7-8)
- [ ] Premium offer designs
- [ ] Special redemption flows
- [ ] Achievement badges
- [ ] Referral program
- [ ] Flash deals system

### Phase 5: Polish & Testing (Week 9-10)
- [ ] Anti-fraud checks
- [ ] Error handling
- [ ] Edge cases
- [ ] Integration tests
- [ ] User acceptance testing

---

## 💡 Đề xuất bổ sung

### 1. Tier-based Membership
- **Bronze:** 0-5,000 coins earned (lifetime)
  - Standard redemption rates
- **Silver:** 5,000-20,000 coins earned
  - 5% discount on all redemptions
- **Gold:** 20,000-50,000 coins earned
  - 10% discount + early access to Flash Deals
- **Diamond:** 50,000+ coins earned
  - 15% discount + exclusive premium rewards

### 2. Seasonal Events
- **Tết Event:** Double coins, special vouchers
- **Mid-Autumn:** Moon cake vouchers
- **Black Friday:** 50% off all redemptions

### 3. Social Features
- Share vouchers với bạn bè (gift)
- Leaderboard: Top redeemers mỗi tháng
- Community challenges: "Cả nhóm cùng đổi 1000 vouchers → unlock special reward"

### 4. Partner Integration (Future - Real)
- API cho restaurants verify vouchers
- Real-time stock updates
- Partner dashboard
- Commission tracking

---

## 🎯 Expected Impact

### User Engagement
- ↑ 40% Daily Active Users (có mục đích rõ ràng)
- ↑ 60% Session length (explore rewards store)
- ↑ 80% Retention rate (có incentive quay lại)

### Monetization (Future)
- Partner commission từ vouchers được dùng
- Premium membership fees
- Sponsored redemption offers

### Product Growth
- Viral effect từ referral program
- User-generated content (share vouchers)
- Network effect (more users → better deals)

---

## ⚠️ Risks & Mitigations

### Risk 1: Coin inflation
**Mitigation:**
- Coin expiry (90 days)
- Redemption limits
- Monitor economy balance

### Risk 2: Fraud/abuse
**Mitigation:**
- Anti-fraud checks
- Account verification
- Manual review cho cash >100K

### Risk 3: User disappointment (fake data)
**Mitigation:**
- Clear communication đây là demo
- Show "Coming Soon" tags
- Realistic mock data

### Risk 4: Technical complexity
**Mitigation:**
- Start with vouchers (simplest)
- Iterate based on feedback
- Comprehensive testing

---

## 📝 Next Steps

### Immediate (This week):
1. ✅ Review proposal với team
2. ✅ Finalize coin economy (exchange rates)
3. ✅ Design mockups cho key screens
4. ✅ Create technical spec document

### Short-term (Next sprint):
1. Implement data models
2. Extend repository
3. Seed fake data
4. Build Redemption Store UI

### Medium-term (Next month):
1. Complete voucher system
2. Add cash withdrawal
3. Testing & refinement
4. Soft launch to beta users

---

**Kết luận:** Hệ thống redemption sẽ biến xu từ "vô nghĩa" thành "có giá trị thực tế", tăng động lực tham gia và retention rate đáng kể. Start với vouchers (dễ nhất), scale dần lên cash và premium rewards.

**Recommendation:** Bắt đầu với **Phase 1-2 (Voucher System)** để validate concept trước khi invest vào cash withdrawal.
