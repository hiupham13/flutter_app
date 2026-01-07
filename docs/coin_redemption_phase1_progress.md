# 🎁 Coin Redemption System - Phase 1 Progress

**Date:** 2026-01-06  
**Phase:** 1 - Foundation (Data Models & Constants)  
**Status:** Steps 1-3 Completed ✅

---

## 📊 Overview

Phase 1 tập trung vào xây dựng foundation cho Coin Redemption System:
- Data models cho redemption offers và user redemptions
- Extend transaction types để support redemption flows
- Define constants và limits cho redemption system

---

## ✅ Completed Tasks

### Phase 1.1: Redemption Data Models ✅

**File:** [`what_eat_app/lib/models/reward_model.dart`](../what_eat_app/lib/models/reward_model.dart:342)

#### 1. RedemptionType Enum
```dart
enum RedemptionType {
  voucher,      // Voucher nhà hàng
  cash,         // Rút tiền
  premium,      // Premium rewards
  merchandise,  // Quà tặng
}
```

**Extensions:**
- `displayName` - Tên hiển thị tiếng Việt
- `emoji` - Icon emoji cho mỗi type
- `color` - Màu đặc trưng cho UI

#### 2. RedemptionStatus Enum
```dart
enum RedemptionStatus {
  pending,      // Chờ xử lý
  processing,   // Đang xử lý
  completed,    // Hoàn thành
  failed,       // Thất bại
  cancelled,    // Đã hủy
  used,         // Đã sử dụng (for vouchers)
}
```

**Extensions:**
- `displayName` - Status text
- `color` - Status color
- `isFinal` - Check if status cannot be changed

#### 3. RedemptionOffer Model
**Purpose:** Global redemption offers available to all users

**Key Fields:**
- `id`, `title`, `description`
- `type: RedemptionType` - Loại reward
- `coinsRequired: int` - Số xu cần để đổi
- `cashValue: int` - Giá trị VND
- `imageUrl`, `isActive`, `expiryDate`
- `stockRemaining: int?` - Số lượng còn lại (null = unlimited)
- `terms: List<String>` - Điều kiện sử dụng
- `metadata: Map` - Additional data (partner info, etc.)

**Methods:**
- `fromFirestore()` / `toFirestore()` - Firebase serialization
- `isAvailable` - Check if offer can be redeemed
- `copyWith()` - Immutable updates

#### 4. UserRedemption Model
**Purpose:** User's redeemed rewards history

**Key Fields:**
- `id`, `userId`, `offerId`, `offerTitle`
- `type: RedemptionType`
- `coinsSpent: int`, `cashValue: int`
- `status: RedemptionStatus`
- `redeemedAt`, `completedAt`, `expiryDate`
- `voucherCode: String?` - For voucher type
- `qrCodeData: String?` - QR for in-store use
- `bankInfo: String?` - For cash type
- `failureReason: String?`

**Methods:**
- `fromFirestore()` / `toFirestore()`
- `isExpired` - Check if voucher expired
- `isUsable` - Check if voucher can be used
- `copyWith()`

**Firebase Collections:**
```
users/{userId}/redemptions/{redemptionId}
redemption_offers/{offerId}           (global)
redemption_partners/{partnerId}       (global)
```

---

### Phase 1.2: Extended TransactionType Enum ✅

**Files Modified:**
- [`what_eat_app/lib/models/reward_model.dart`](../what_eat_app/lib/models/reward_model.dart:156)
- [`what_eat_app/lib/features/rewards/presentation/transaction_history_screen.dart`](../what_eat_app/lib/features/rewards/presentation/transaction_history_screen.dart:1)

#### Added Transaction Types
```dart
enum TransactionType {
  earned,              // Existing
  spent,               // Existing (legacy)
  bonus,               // Existing
  refund,              // Existing
  redemption,          // NEW: Spent on redemption
  redemptionRefund,    // NEW: Refund from failed redemption
}
```

#### Updated Methods

**In reward_model.dart:**
- ✅ `displayText` getter - Added cases for new types
- ✅ `isCredit` getter - Include redemptionRefund as credit

**In transaction_history_screen.dart:**
- ✅ `_getTypeDisplayName()` - 2 implementations (screen + tile)
- ✅ `_getTypeDescription()` - Filter descriptions
- ✅ `_buildIcon()` - Icons for new types
- ✅ `_getDisplayText()` - Display text for tiles

**Fixed Switch Case Errors:** 6 switch statements updated across both files

---

### Phase 1.3: Redemption Constants ✅

**File:** [`what_eat_app/lib/core/constants/rewards_constants.dart`](../what_eat_app/lib/core/constants/rewards_constants.dart:88)

#### Redemption Limits
```dart
// Per day
static const int maxVouchersPerDay = 3;
static const int maxCashPerDay = 100000; // VND

// Per week
static const int maxVouchersPerWeek = 10;
static const int maxCashPerWeek = 500000; // VND

// Per month
static const int maxTotalRedemptionsPerMonth = 50;

// Account requirements
static const int minAccountAgeDaysForCash = 7;
static const int minBoxesOpenedForCash = 10;

// Voucher settings
static const int voucherValidityDays = 30;
static const int cashProcessingDays = 3; // fake
```

#### Default Offer Values
```dart
// Vouchers
static const int voucher10kCoins = 500;
static const int voucher20kCoins = 900;
static const int voucher50kCoins = 2000;

// Cash
static const int cash20kCoins = 1000;
static const int cash50kCoins = 2500;
static const int cash100kCoins = 5000;
static const int cash200kCoins = 10000;

// Premium
static const int monthlyPassCoins = 15000;
static const int premiumRewardMinCoins = 10000;
```

**Existing Constants Used:**
- `minimumRedemptionCoins = 50`
- `coinsPerVND = 20` (1000 coins = 50,000 VND)
- `redemptionsCollection = 'redemptions'`

---

## 📈 Statistics

### Code Changes
| Metric | Count |
|--------|-------|
| Models Created | 2 (RedemptionOffer, UserRedemption) |
| Enums Added | 2 (RedemptionType, RedemptionStatus) |
| Enum Values Extended | 1 (TransactionType: +2 values) |
| Constants Added | 20 |
| Files Modified | 3 |
| Lines Added | ~450 |
| Switch Cases Fixed | 6 |

### Files Modified
1. ✅ `what_eat_app/lib/models/reward_model.dart` (+400 lines)
2. ✅ `what_eat_app/lib/features/rewards/presentation/transaction_history_screen.dart` (+12 lines)
3. ✅ `what_eat_app/lib/core/constants/rewards_constants.dart` (+60 lines)

---

## 🏗️ Architecture Highlights

### Data Model Design
- **Immutable models** với `copyWith()` methods
- **Firebase integration** với `fromFirestore()` / `toFirestore()`
- **Type-safe enums** với extensions for UI
- **Nullable fields** cho optional data
- **Metadata support** cho flexibility

### Constants Organization
- Grouped by purpose (Limits, Offers, Settings)
- Clear naming conventions
- Documented với comments
- Easy to adjust values

### Backward Compatibility
- Existing `TransactionType` values unchanged
- New types added without breaking changes
- Legacy `spent` type maintained
- All switch cases updated

---

## 🔄 Next Steps

### Phase 1.4: Extend RewardsRepository (In Progress)
- [ ] Add `getRedemptionOffers()` method
- [ ] Add `redeemOffer()` method
- [ ] Add `getRedemptionHistory()` method
- [ ] Add `getActiveVouchers()` method
- [ ] Add `useVoucher()` method
- [ ] Add `cancelRedemption()` method
- [ ] Add validation logic
- [ ] Add anti-fraud checks

### Phase 1.5: Mock Redemption Offers Data
- [ ] Create mock voucher offers (3 tiers)
- [ ] Create mock cash offers (4 tiers)
- [ ] Create mock premium offers (2-3 items)
- [ ] Create mock partner restaurants
- [ ] Generate QR code data
- [ ] Setup data seeding

### Phase 1.6: Setup Redemption Providers
- [ ] Create `redemptionOffersProvider`
- [ ] Create `userRedemptionsProvider`
- [ ] Create `activeVouchersProvider`
- [ ] Create helper providers for filtering
- [ ] Setup state management

### Phase 1.7: Unit Tests
- [ ] Test RedemptionOffer model
- [ ] Test UserRedemption model
- [ ] Test repository methods
- [ ] Test validation logic
- [ ] Test anti-fraud checks
- [ ] Coverage target: 80%+

---

## 💡 Key Decisions Made

### 1. Separation of Offer and Redemption
- **RedemptionOffer**: Global templates (what can be redeemed)
- **UserRedemption**: User-specific instances (what user redeemed)
- **Benefit**: Clear separation, easy to manage stock, flexible pricing

### 2. Enum-based Type System
- Used enums instead of strings for type safety
- Extensions for UI display logic
- **Benefit**: Compile-time safety, autocomplete support

### 3. Flexible Metadata Field
- `Map<String, dynamic>` for extensibility
- Can store partner info, terms, special flags
- **Benefit**: Future-proof, no schema changes needed

### 4. Status-based Workflow
- 6 distinct statuses for redemption lifecycle
- `isFinal` property to prevent invalid transitions
- **Benefit**: Clear state machine, easy to track

### 5. Dual Transaction Types
- `redemption` - Main spending transaction
- `redemptionRefund` - Separate refund type
- **Benefit**: Clear audit trail, easier analytics

---

## 🎯 Phase 1 Completion Status

**Overall:** 3/7 Steps Completed (43%)

- ✅ Step 1.1: Data Models (100%)
- ✅ Step 1.2: Transaction Types (100%)
- ✅ Step 1.3: Constants (100%)
- ⏳ Step 1.4: Repository Extension (0%)
- ⏳ Step 1.5: Mock Data (0%)
- ⏳ Step 1.6: Providers (0%)
- ⏳ Step 1.7: Tests (0%)

**Est. Time Remaining:** 12-16 hours for Phase 1 completion

---

## 📝 Notes

### Testing Strategy
- Will use existing test infrastructure (flutter_test + mockito)
- Focus on business logic first, UI tests later
- Aim for >80% coverage on critical paths

### Mock Data Strategy
- All data will be fake but realistic
- Partner restaurants will be well-known Vietnamese brands
- QR codes will be generated but not validated
- Cash withdrawal will show instant success (fake processing)

### Future Considerations
- Real partner integration API (Phase 3+)
- Actual QR code scanning (Phase 3+)
- Real payment gateway for cash (Phase 4+)
- Admin dashboard for offer management (Phase 5+)

---

**Last Updated:** 2026-01-06 20:59 ICT  
**Next Update:** After Phase 1.4 completion
