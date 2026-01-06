# 🗺️ Mystery Box System - Week 2-4 Roadmap

> **Current Status:** Week 1 Complete (Backend Ready)  
> **Next Phase:** Week 2 - UI Components  
> **Goal:** Complete MVP trong 3 tuần

---

## 📅 WEEK 2: UI COMPONENTS (Day 6-10)

### Day 6: Coin Balance Widget ⭐⭐⭐

**File:** `lib/core/widgets/coin_balance_widget.dart`

**Features:**
```dart
✨ Display current coin balance
✨ Animated counter (number rolling effect)
✨ Tap to navigate to transaction history
✨ Gradient background (gold theme)
✨ Pulse animation on update
```

**Implementation:**
```dart
class CoinBalanceWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(coinBalanceProvider);
    
    return GestureDetector(
      onTap: () => context.push('/transactions'),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(Icons.monetization_on, color: Colors.white),
            SizedBox(width: 8),
            AnimatedFlipCounter(
              value: balance,
              duration: Duration(milliseconds: 500),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Testing:**
- [ ] Balance updates correctly
- [ ] Animation smooth
- [ ] Tap navigation works
- [ ] Looks good on all screens

**Effort:** 4-6 hours

---

### Day 7: Mystery Box Card Widget ⭐⭐⭐⭐

**File:** `lib/features/rewards/presentation/widgets/mystery_box_card.dart`

**Features:**
```dart
✨ Show box rarity (color-coded)
✨ Unopened indicator (badge)
✨ Hover/press animation
✨ Shimmer effect for unopened
✨ Disabled state for opened
```

**Design Specs:**
```
Bronze Box: 
  - Color: #CD7F32 (brown)
  - Icon: 📦
  
Silver Box:
  - Color: #C0C0C0 (silver)
  - Icon: 🎁
  
Gold Box:
  - Color: #FFD700 (gold)
  - Icon: 💎
  
Diamond Box:
  - Color: #B9F2FF (diamond)
  - Icon: ✨
  - Rainbow gradient border
```

**Implementation:**
```dart
class MysteryBoxCard extends StatelessWidget {
  final RewardBox box;
  final VoidCallback onTap;
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: box.isOpened ? null : onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: _getGradient(box.rarity),
          borderRadius: BorderRadius.circular(16),
          boxShadow: box.isOpened ? [] : [
            BoxShadow(
              color: _getColor(box.rarity).withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Shimmer effect if unopened
            if (!box.isOpened) ShimmerEffect(),
            
            // Box content
            Column(
              children: [
                Text(box.rarity.emoji, style: TextStyle(fontSize: 48)),
                Text(box.rarity.displayName),
                if (!box.isOpened) 
                  Text('Tap to Open', style: TextStyle(fontSize: 12)),
              ],
            ),
            
            // Unopened badge
            if (!box.isOpened)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text('!', style: TextStyle(color: Colors.white)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

**Testing:**
- [ ] All 4 rarities display correctly
- [ ] Animations smooth
- [ ] Shimmer effect working
- [ ] Disabled state correct

**Effort:** 6-8 hours

---

### Day 8-9: Box Opening Screen ⭐⭐⭐⭐⭐

**File:** `lib/features/rewards/presentation/box_opening_screen.dart`

**Features:**
```dart
✨ Full-screen modal
✨ Box shaking animation (anticipation)
✨ Box opening animation (reveal)
✨ Coins flying out animation
✨ Confetti for big wins (500+ coins)
✨ Fireworks for jackpot (1000+ coins)
✨ Final reveal with coin amount
✨ Share button
✨ Sound effects (optional)
```

**Animation Sequence:**
```
1. Box appears (scale up)             → 0.5s
2. User taps "Open"                   
3. Box shakes 3 times                 → 1.0s
4. Box opens (lid flies up)           → 0.5s
5. Coins fly out                      → 1.0s
6. Confetti (if big win)              → 2.0s
7. Final reveal (total coins)         → 0.5s
8. Buttons appear (share, continue)   → 0.3s

Total: ~5.8 seconds
```

**Implementation:**
```dart
class BoxOpeningScreen extends ConsumerStatefulWidget {
  final RewardBox box;
  
  @override
  ConsumerState<BoxOpeningScreen> createState() => _BoxOpeningScreenState();
}

class _BoxOpeningScreenState extends ConsumerState<BoxOpeningScreen>
    with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late AnimationController _openController;
  late AnimationController _coinsController;
  late AnimationController _confettiController;
  
  BoxOpeningPhase _phase = BoxOpeningPhase.initial;
  int? _coinsAwarded;
  
  @override
  void initState() {
    super.initState();
    _initAnimations();
  }
  
  void _initAnimations() {
    _shakeController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _openController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    
    _coinsController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _confettiController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );
  }
  
  Future<void> _startOpening() async {
    setState(() => _phase = BoxOpeningPhase.shaking);
    
    // 1. Shake animation
    await _shakeController.forward();
    
    setState(() => _phase = BoxOpeningPhase.opening);
    
    // 2. Open animation
    await _openController.forward();
    
    // 3. Actually open box (backend call)
    final coins = await ref.read(rewardsControllerProvider)
        .openMysteryBox(widget.box.id);
    
    setState(() {
      _coinsAwarded = coins;
      _phase = BoxOpeningPhase.revealing;
    });
    
    // 4. Coins flying out
    await _coinsController.forward();
    
    // 5. Confetti if big win
    if (RewardsConstants.isBigWin(coins)) {
      setState(() => _phase = BoxOpeningPhase.celebrating);
      await _confettiController.forward();
    }
    
    // 6. Final reveal
    setState(() => _phase = BoxOpeningPhase.complete);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Stack(
        children: [
          // Background gradient
          _buildBackground(),
          
          // Main content based on phase
          Center(
            child: _buildPhaseContent(),
          ),
          
          // Confetti overlay
          if (_phase == BoxOpeningPhase.celebrating)
            ConfettiWidget(controller: _confettiController),
          
          // Buttons (bottom)
          if (_phase == BoxOpeningPhase.complete)
            _buildBottomButtons(),
        ],
      ),
    );
  }
  
  Widget _buildPhaseContent() {
    switch (_phase) {
      case BoxOpeningPhase.initial:
        return _buildInitialBox();
      case BoxOpeningPhase.shaking:
        return _buildShakingBox();
      case BoxOpeningPhase.opening:
        return _buildOpeningBox();
      case BoxOpeningPhase.revealing:
      case BoxOpeningPhase.celebrating:
        return _buildRevealingCoins();
      case BoxOpeningPhase.complete:
        return _buildFinalReveal();
    }
  }
}

enum BoxOpeningPhase {
  initial,
  shaking,
  opening,
  revealing,
  celebrating,
  complete,
}
```

**Assets needed:**
```
assets/animations/
  - box_shake.json (Lottie)
  - box_open.json (Lottie)
  - coins_flying.json (Lottie)
  - confetti.json (Lottie)
  - fireworks.json (Lottie)
  
assets/sounds/ (optional)
  - box_shake.mp3
  - box_open.mp3
  - coins_drop.mp3
  - celebration.mp3
```

**Testing:**
- [ ] All animations smooth (60fps)
- [ ] Sequence timing correct
- [ ] Backend call succeeds
- [ ] Big win detection working
- [ ] Share button functional

**Effort:** 12-16 hours

---

### Day 10: Transaction History Screen ⭐⭐⭐

**File:** `lib/features/rewards/presentation/transaction_history_screen.dart`

**Features:**
```dart
✨ List all transactions
✨ Grouped by date (Hôm nay, Hôm qua, DD/MM/YYYY)
✨ Filter by type (earned, spent, bonus)
✨ Search by description
✨ Pull-to-refresh
✨ Infinite scroll
```

**Implementation:**
```dart
class TransactionHistoryScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionHistoryProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Lịch Sử Giao Dịch'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: transactions.when(
        data: (txns) => _buildTransactionList(txns),
        loading: () => LoadingIndicator(),
        error: (e, st) => ErrorWidget(message: e.toString()),
      ),
    );
  }
  
  Widget _buildTransactionList(List<CoinTransaction> transactions) {
    final grouped = _groupByDate(transactions);
    
    return ListView.builder(
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final entry = grouped.entries.elementAt(index);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                entry.key,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...entry.value.map((txn) => TransactionTile(
              transaction: txn,
            )),
          ],
        );
      },
    );
  }
}

class TransactionTile extends StatelessWidget {
  final CoinTransaction transaction;
  
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _buildIcon(),
      title: Text(transaction.displayText),
      subtitle: Text(_formatTime(transaction.timestamp)),
      trailing: Text(
        '${transaction.isCredit ? '+' : '-'}${transaction.amount}',
        style: TextStyle(
          color: transaction.isCredit ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
```

**Testing:**
- [ ] List displays correctly
- [ ] Grouping works
- [ ] Filter functional
- [ ] Pull-to-refresh works

**Effort:** 6-8 hours

---

## 📅 WEEK 3: INTEGRATION & POLISH (Day 11-15)

### Day 11: Integrate với Recommendation Flow ⭐⭐⭐⭐⭐

**Goal:** User nhận mystery box sau khi follow recommendation

**Changes needed:**

1. **Result Screen** - Add "Claim Reward" section
```dart
// lib/features/recommendation/presentation/result_screen.dart

Widget _buildClaimRewardSection() {
  return FutureBuilder<bool>(
    future: ref.read(rewardsControllerProvider).canClaimBox(),
    builder: (context, snapshot) {
      if (snapshot.data != true) return SizedBox.shrink();
      
      return Card(
        child: Column(
          children: [
            Text('🎁 Nhận Quà Khi Đi Ăn!'),
            Text('Nhận mystery box khi xác nhận đã đi ăn món này'),
            ElevatedButton(
              onPressed: () => _showClaimDialog(context),
              child: Text('Tôi Đã Đi Ăn Món Này'),
            ),
          ],
        ),
      );
    },
  );
}
```

2. **Claim Dialog** - Location verification + Box generation
```dart
Future<void> _showClaimDialog(BuildContext context) async {
  showDialog(
    context: context,
    builder: (context) => ClaimRewardDialog(
      food: currentFood,
      recommendationId: recommendationId,
    ),
  );
}
```

3. **ClaimRewardDialog Widget**
```dart
class ClaimRewardDialog extends ConsumerStatefulWidget {
  final FoodModel food;
  final String recommendationId;
  
  @override
  _ClaimRewardDialogState createState() => _ClaimRewardDialogState();
}

class _ClaimRewardDialogState extends ConsumerState<ClaimRewardDialog> {
  ClaimPhase _phase = ClaimPhase.confirm;
  String? _error;
  RewardBox? _box;
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: _buildPhaseContent(),
      ),
    );
  }
  
  Widget _buildPhaseContent() {
    switch (_phase) {
      case ClaimPhase.confirm:
        return _buildConfirmation();
      case ClaimPhase.verifying:
        return _buildVerification();
      case ClaimPhase.generating:
        return _buildGeneration();
      case ClaimPhase.success:
        return _buildSuccess();
      case ClaimPhase.error:
        return _buildError();
    }
  }
  
  Future<void> _handleClaim() async {
    setState(() => _phase = ClaimPhase.verifying);
    
    // 1. Verify location (if restaurant has coordinates)
    if (widget.food.hasLocation) {
      final result = await LocationVerificationService().quickVerify(
        restaurantLat: widget.food.latitude!,
        restaurantLon: widget.food.longitude!,
      );
      
      if (!result.isVerified) {
        setState(() {
          _phase = ClaimPhase.error;
          _error = result.reason;
        });
        return;
      }
    }
    
    setState(() => _phase = ClaimPhase.generating);
    
    // 2. Generate mystery box
    try {
      final box = await ref.read(rewardsControllerProvider)
          .generateMysteryBox(
        sourceRecommendationId: widget.recommendationId,
      );
      
      setState(() {
        _phase = ClaimPhase.success;
        _box = box;
      });
      
      // Auto-dismiss after 2 seconds
      Future.delayed(Duration(seconds: 2), () {
        Navigator.pop(context);
        _navigateToBoxOpening(box);
      });
    } catch (e) {
      setState(() {
        _phase = ClaimPhase.error;
        _error = e.toString();
      });
    }
  }
  
  void _navigateToBoxOpening(RewardBox box) {
    context.push('/box-opening', extra: box);
  }
}

enum ClaimPhase {
  confirm,
  verifying,
  generating,
  success,
  error,
}
```

**Testing:**
- [ ] Claim flow works end-to-end
- [ ] Location verification correct
- [ ] Box generated successfully
- [ ] Navigation to opening screen works
- [ ] Error handling proper

**Effort:** 8-10 hours

---

### Day 12-13: Animations & Polish ⭐⭐⭐⭐

**Tasks:**
1. ✨ Add Lottie animations
2. ✨ Add sound effects (optional)
3. ✨ Polish all transitions
4. ✨ Add haptic feedback
5. ✨ Optimize performance

**Implementation:**
```dart
// Add lottie package
dependencies:
  lottie: ^2.7.0
  
// Add audioplayers (optional)
  audioplayers: ^5.2.1
```

**Download Lottie animations:**
- https://lottiefiles.com/search?q=gift%20box
- https://lottiefiles.com/search?q=coins
- https://lottiefiles.com/search?q=confetti

**Effort:** 10-12 hours

---

### Day 14-15: Dashboard Integration ⭐⭐⭐

**Goal:** Show coin balance & pending boxes on Dashboard

**Changes:**
```dart
// lib/features/dashboard/presentation/dashboard_screen.dart

Widget _buildRewardsSection() {
  return Column(
    children: [
      // Coin balance (top right corner)
      Positioned(
        top: 16,
        right: 16,
        child: CoinBalanceWidget(),
      ),
      
      // Pending boxes indicator
      Consumer(
        builder: (context, ref, child) {
          final count = ref.watch(pendingBoxesCountProvider);
          
          if (count == 0) return SizedBox.shrink();
          
          return GestureDetector(
            onTap: () => context.push('/pending-boxes'),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.card_giftcard, size: 32),
                    SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bạn có $count hộp quà chưa mở!'),
                        Text('Nhấn để mở ngay', 
                          style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ],
  );
}
```

**Testing:**
- [ ] Coin balance visible
- [ ] Updates in real-time
- [ ] Pending boxes shows correct count
- [ ] Tap navigation works

**Effort:** 4-6 hours

---

## 📅 WEEK 4: TESTING & POLISH (Day 16-20)

### Day 16-17: Unit Tests ⭐⭐⭐⭐

**Files to test:**
```dart
test/rewards/
  ├── reward_model_test.dart
  ├── rewards_repository_test.dart
  ├── rewards_provider_test.dart
  ├── location_verification_test.dart
  └── box_probability_test.dart
```

**Key tests:**
```dart
// Test box probability distribution
test('Box rarity distribution follows probabilities', () {
  final results = <BoxRarity, int>{};
  
  // Generate 10,000 boxes
  for (int i = 0; i < 10000; i++) {
    final box = generateMysteryBox();
    results[box.rarity] = (results[box.rarity] ?? 0) + 1;
  }
  
  // Check distribution (with 5% tolerance)
  expect(results[BoxRarity.bronze] / 10000, closeTo(0.70, 0.05));
  expect(results[BoxRarity.silver] / 10000, closeTo(0.20, 0.05));
  expect(results[BoxRarity.gold] / 10000, closeTo(0.08, 0.03));
  expect(results[BoxRarity.diamond] / 10000, closeTo(0.02, 0.02));
});

// Test anti-fraud
test('Cannot claim more than 5 boxes per day', () async {
  for (int i = 0; i < 5; i++) {
    final canClaim = await repository.canClaimBox();
    expect(canClaim, true);
    await repository.generateMysteryBox();
  }
  
  final canClaimSixth = await repository.canClaimBox();
  expect(canClaimSixth, false);
});
```

**Effort:** 12-16 hours

---

### Day 18-19: Manual Testing ⭐⭐⭐⭐⭐

**Test Scenarios:**

1. **Happy Path**
   - [ ] User picks recommendation
   - [ ] Claims reward
   - [ ] Location verified
   - [ ] Box generated
   - [ ] Opens box
   - [ ] Coins awarded
   - [ ] Balance updated

2. **Edge Cases**
   - [ ] No internet connection
   - [ ] GPS disabled
   - [ ] Too far from restaurant
   - [ ] Already claimed 5 boxes today
   - [ ] Cooldown active
   - [ ] Box already opened

3. **Error Handling**
   - [ ] Firebase errors
   - [ ] Location errors
   - [ ] Permission denied
   - [ ] Network timeout

4. **Performance**
   - [ ] Box opening animation smooth
   - [ ] No lag on list scrolling
   - [ ] Memory usage acceptable
   - [ ] Battery drain minimal

**Effort:** 12-16 hours

---

### Day 20: Bug Fixes & Final Polish ⭐⭐⭐⭐⭐

**Tasks:**
- [ ] Fix all critical bugs
- [ ] Fix all major bugs
- [ ] Address minor UX issues
- [ ] Optimize performance
- [ ] Final code cleanup
- [ ] Update documentation

**Effort:** 8-10 hours

---

## 🎯 DEFINITION OF DONE

### Week 2 (UI Components)
- [x] Coin balance widget functional
- [x] Mystery box card displays correctly
- [x] Box opening screen với full animations
- [x] Transaction history screen complete
- [x] All widgets responsive

### Week 3 (Integration)
- [x] Claim reward flow working
- [x] Location verification integrated
- [x] Dashboard shows rewards section
- [x] Navigation between screens smooth
- [x] Lottie animations added

### Week 4 (Testing)
- [x] 20+ unit tests passing
- [x] All manual test scenarios pass
- [x] Performance acceptable (60fps)
- [x] No critical bugs
- [x] Documentation complete

---

## 📊 SUCCESS METRICS

### Technical
- Code coverage > 70%
- All animations 60fps
- Box generation < 500ms
- No memory leaks
- Battery drain < 5% per hour

### Business
- 80%+ users claim at least 1 box
- Average 3 boxes per user per month
- Redemption rate > 30%
- User satisfaction > 4/5 stars

---

## 🚀 LAUNCH CHECKLIST

**Pre-Launch:**
- [ ] All features complete
- [ ] All tests passing
- [ ] Performance optimized
- [ ] Firebase rules deployed
- [ ] Analytics events added
- [ ] Crashlytics configured

**Launch:**
- [ ] Soft launch to 100 users
- [ ] Monitor for 48 hours
- [ ] Fix critical issues
- [ ] Full launch to all users

**Post-Launch:**
- [ ] Monitor metrics daily
- [ ] Gather user feedback
- [ ] Plan Phase 2 features
- [ ] Iterate based on data

---

**Timeline Summary:**
- Week 1: ✅ Complete (Backend)
- Week 2: UI Components (5 days)
- Week 3: Integration (5 days)
- Week 4: Testing (5 days)
- **Total: 20 days to MVP**

**Next Action:** Start Day 6 - Coin Balance Widget 🎨

---

*Let's build amazing gamification! 🚀*