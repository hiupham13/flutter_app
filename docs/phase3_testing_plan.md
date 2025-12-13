# Phase 3 Testing Plan & Quality Assurance

## Overview
Comprehensive testing cho tất cả Phase 3 features và Bottom Navigation implementation.

## Testing Date
13/12/2024

---

## Test Environment

### Prerequisites
- Flutter SDK: Latest stable
- Firebase: Configured và connected
- Test devices: Android/iOS emulator hoặc physical device
- Test data: Seed data loaded vào Firestore

### Test Users
- User 1: Email `test@example.com` - Normal user
- User 2: Email `test2@example.com` - User with history & favorites
- User 3: New user - Fresh account

---

## Phase 3.1: Search & Filter Screen

### Test Cases

#### TC-3.1.1: Basic Search
- [ ] **Given:** User on Search tab
- [ ] **When:** Enter "phở" in search field
- [ ] **Then:** List shows all foods containing "phở"
- [ ] **Expected:** Real-time search, debounced at 300ms

#### TC-3.1.2: Cuisine Filter
- [ ] **Given:** User on Search screen
- [ ] **When:** Select "vietnamese" cuisine chip
- [ ] **Then:** Only Vietnamese foods displayed
- [ ] **Expected:** Filter badge shows "1 bộ lọc"

#### TC-3.1.3: Price Filter
- [ ] **Given:** User on Search screen  
- [ ] **When:** Select "budget" price chip
- [ ] **Then:** Only low-price foods displayed
- [ ] **Expected:** Price badge shows on food cards

#### TC-3.1.4: Meal Type Filter
- [ ] **Given:** User on Search screen
- [ ] **When:** Select "breakfast" meal type
- [ ] **Then:** Only breakfast foods displayed
- [ ] **Expected:** Multiple filters can be combined

#### TC-3.1.5: Multiple Filters
- [ ] **Given:** User on Search screen
- [ ] **When:** Select cuisine + price + meal type
- [ ] **Then:** Foods match ALL selected filters (AND logic)
- [ ] **Expected:** Filter badge shows "3 bộ lọc"

#### TC-3.1.6: Clear All Filters
- [ ] **Given:** User has active filters
- [ ] **When:** Tap "Xóa bộ lọc" button
- [ ] **Then:** All filters cleared, full list shown
- [ ] **Expected:** Smooth animation, instant update

#### TC-3.1.7: Empty Search Results
- [ ] **Given:** User searches for non-existent food
- [ ] **When:** Type "xyz123"
- [ ] **Then:** Empty state with message displayed
- [ ] **Expected:** "Không tìm thấy món ăn phù hợp"

#### TC-3.1.8: Food Card Tap
- [ ] **Given:** User sees search results
- [ ] **When:** Tap on a food card
- [ ] **Then:** Navigate to Result screen
- [ ] **Expected:** Food details displayed correctly

---

## Phase 3.2: Image Caching

### Test Cases

#### TC-3.2.1: First Load (Cold Start)
- [ ] **Given:** Fresh app install, no cache
- [ ] **When:** Load food images
- [ ] **Then:** Images downloaded from network
- [ ] **Expected:** Loading indicators shown, then images

#### TC-3.2.2: Cached Images
- [ ] **Given:** Images loaded before
- [ ] **When:** Navigate back to same screen
- [ ] **Then:** Images load instantly from cache
- [ ] **Expected:** No loading indicators, instant display

#### TC-3.2.3: Network Error Handling
- [ ] **Given:** User offline or network error
- [ ] **When:** Try to load new images
- [ ] **Then:** Error placeholder shown
- [ ] **Expected:** App doesn't crash, graceful fallback

#### TC-3.2.4: Invalid Image URL
- [ ] **Given:** Food with broken image URL
- [ ] **When:** Load food card
- [ ] **Then:** Placeholder/error icon shown
- [ ] **Expected:** No crashes, clean UI

#### TC-3.2.5: Cache Performance
- [ ] **Given:** Scroll through long food list
- [ ] **When:** Scroll fast up/down
- [ ] **Then:** Smooth scrolling, images cached
- [ ] **Expected:** No flickering, fast load times

---

## Phase 3.3: Share Functionality

### Test Cases

#### TC-3.3.1: Share Food Recommendation
- [ ] **Given:** User on Result screen
- [ ] **When:** Tap "Chia sẻ" button
- [ ] **Then:** Share sheet appears
- [ ] **Expected:** Rich text with food name, cuisine, price

#### TC-3.3.2: Share Text Format
- [ ] **Given:** User shares food
- [ ] **When:** Check shared text
- [ ] **Then:** Contains: Name, Cuisine, Price, Context, App name
- [ ] **Expected:** "🍽️ Tôi được gợi ý món: [Name]..."

#### TC-3.3.3: Share to Different Apps
- [ ] **Given:** User taps share
- [ ] **When:** Select different share targets (WhatsApp, Messenger, etc.)
- [ ] **Then:** Text shared correctly to each app
- [ ] **Expected:** Consistent format across platforms

#### TC-3.3.4: Share with Context
- [ ] **Given:** User got recommendation with specific context
- [ ] **When:** Share the recommendation
- [ ] **Then:** Context included in share text
- [ ] **Expected:** "💰 Ngân sách: medium, 👥 Bối cảnh: alone"

#### TC-3.3.5: Cancel Share
- [ ] **Given:** User taps share button
- [ ] **When:** Cancel share sheet
- [ ] **Then:** Return to Result screen normally
- [ ] **Expected:** No side effects, smooth dismiss

---

## Phase 3.4: Full History Screen

### Test Cases

#### TC-3.4.1: Load Full History
- [ ] **Given:** User has recommendation history
- [ ] **When:** Navigate to History tab
- [ ] **Then:** All history items loaded, grouped by date
- [ ] **Expected:** "Hôm nay", "Hôm qua", "12/12/2024" labels

#### TC-3.4.2: Date Grouping - Today
- [ ] **Given:** User made recommendations today
- [ ] **When:** View history
- [ ] **Then:** Items under "Hôm nay" header
- [ ] **Expected:** Correct grouping, newest first

#### TC-3.4.3: Date Grouping - Yesterday
- [ ] **Given:** User has yesterday's history
- [ ] **When:** View history
- [ ] **Then:** Items under "Hôm qua" header
- [ ] **Expected:** Correct date calculation

#### TC-3.4.4: Date Grouping - Older Dates
- [ ] **Given:** User has history from last week
- [ ] **When:** View history
- [ ] **Then:** Items under "12/12/2024" format headers
- [ ] **Expected:** Correct date formatting (DD/MM/YYYY)

#### TC-3.4.5: Delete Single Item
- [ ] **Given:** User on History screen
- [ ] **When:** Tap delete icon on one item
- [ ] **Then:** Confirmation dialog shown
- [ ] **Expected:** "Bạn có chắc muốn xóa món này?"

#### TC-3.4.6: Confirm Delete Single
- [ ] **Given:** User confirms delete
- [ ] **When:** Tap "Xóa" in dialog
- [ ] **Then:** Item removed from list immediately
- [ ] **Expected:** Firestore updated, snackbar shown

#### TC-3.4.7: Clear All History
- [ ] **Given:** User has multiple history items
- [ ] **When:** Tap "Xóa tất cả" button
- [ ] **Then:** Confirmation dialog shown
- [ ] **Expected:** "Bạn có chắc muốn xóa toàn bộ lịch sử?"

#### TC-3.4.8: Confirm Clear All
- [ ] **Given:** User confirms clear all
- [ ] **When:** Tap "Xóa" in dialog
- [ ] **Then:** All items removed, empty state shown
- [ ] **Expected:** Firestore batch delete, success message

#### TC-3.4.9: Empty History State
- [ ] **Given:** User has no history
- [ ] **When:** View History tab
- [ ] **Then:** Empty state with message displayed
- [ ] **Expected:** "Chưa có lịch sử gợi ý nào"

#### TC-3.4.10: Pull to Refresh
- [ ] **Given:** User on History screen
- [ ] **When:** Pull down to refresh
- [ ] **Then:** History reloaded from Firestore
- [ ] **Expected:** Loading indicator, updated list

#### TC-3.4.11: Tap History Item
- [ ] **Given:** User views history
- [ ] **When:** Tap on a history food card
- [ ] **Then:** Navigate to Result screen
- [ ] **Expected:** Food details loaded correctly

#### TC-3.4.12: Image Caching in History
- [ ] **Given:** User views history multiple times
- [ ] **When:** Scroll through history list
- [ ] **Then:** Images loaded from cache instantly
- [ ] **Expected:** Smooth scrolling, no flicker

---

## Bottom Navigation Implementation

### Test Cases

#### TC-BN.1: Tab Switching via Bottom Nav
- [ ] **Given:** User on Dashboard tab
- [ ] **When:** Tap Search tab icon
- [ ] **Then:** Navigate to Search screen
- [ ] **Expected:** Smooth transition, bottom nav highlights correct tab

#### TC-BN.2: Tab Switching via Swipe
- [ ] **Given:** User on Dashboard tab
- [ ] **When:** Swipe left
- [ ] **Then:** Navigate to Search tab
- [ ] **Expected:** PageView animation, bottom nav syncs

#### TC-BN.3: All 5 Tabs Accessible
- [ ] **Given:** User on any tab
- [ ] **When:** Navigate through all 5 tabs
- [ ] **Then:** Dashboard → Search → Favorites → History → Profile
- [ ] **Expected:** All screens load correctly

#### TC-BN.4: State Preservation
- [ ] **Given:** User types in Search field
- [ ] **When:** Switch to Favorites tab, then back to Search
- [ ] **Then:** Search text still present
- [ ] **Expected:** Tab state preserved

#### TC-BN.5: Deep Link to Specific Tab
- [ ] **Given:** User clicks link with `?tab=2`
- [ ] **When:** App opens
- [ ] **Then:** Opens directly to Favorites tab
- [ ] **Expected:** Correct tab selected, navigation synced

#### TC-BN.6: Logout from MainScreen
- [ ] **Given:** User on any tab
- [ ] **When:** Tap logout button in MainScreen AppBar
- [ ] **Then:** Confirmation dialog shown
- [ ] **Expected:** "Bạn có chắc muốn đăng xuất?"

#### TC-BN.7: Confirm Logout
- [ ] **Given:** User confirms logout
- [ ] **When:** Tap "Đăng xuất" in dialog
- [ ] **Then:** Navigate to Login screen
- [ ] **Expected:** Auth state cleared, clean navigation

#### TC-BN.8: Cancel Logout
- [ ] **Given:** User taps logout
- [ ] **When:** Tap "Hủy" in dialog
- [ ] **Then:** Stay on current tab
- [ ] **Expected:** No side effects

#### TC-BN.9: Dashboard AppBar Simplified
- [ ] **Given:** User on Dashboard tab
- [ ] **When:** View AppBar
- [ ] **Then:** Only Settings button visible
- [ ] **Expected:** Clean UI, no logout button

#### TC-BN.10: Navigate to Settings
- [ ] **Given:** User on Dashboard
- [ ] **When:** Tap Settings icon
- [ ] **Then:** Navigate to Settings screen
- [ ] **Expected:** Full screen, back button works

---

## Integration Tests

### Test Cases

#### TC-INT.1: Search → Result → History Flow
- [ ] **Given:** User searches for food
- [ ] **When:** Tap food → Get recommendation → View History
- [ ] **Then:** New item appears in history
- [ ] **Expected:** Complete flow works end-to-end

#### TC-INT.2: Favorite → Share Flow
- [ ] **Given:** User on Favorites tab
- [ ] **When:** Tap favorite → Tap share
- [ ] **Then:** Share sheet opens with food details
- [ ] **Expected:** Correct food data shared

#### TC-INT.3: History → Delete → Refresh Flow
- [ ] **Given:** User deletes history item
- [ ] **When:** Pull to refresh
- [ ] **Then:** Item still deleted, list updated
- [ ] **Expected:** Firestore sync correct

#### TC-INT.4: Multiple Tabs State Management
- [ ] **Given:** User active in multiple tabs
- [ ] **When:** Make changes in one tab
- [ ] **Then:** Other tabs reflect changes on return
- [ ] **Expected:** Riverpod state synced

#### TC-INT.5: Offline Mode
- [ ] **Given:** User goes offline
- [ ] **When:** Navigate app, view cached data
- [ ] **Then:** Cached content works, new requests fail gracefully
- [ ] **Expected:** No crashes, clear error messages

---

## Performance Tests

### Test Cases

#### TC-PERF.1: App Cold Start Time
- [ ] **Given:** Fresh app launch
- [ ] **When:** Measure time to Dashboard
- [ ] **Then:** < 3 seconds on mid-range device
- [ ] **Expected:** Fast startup

#### TC-PERF.2: Tab Switch Performance
- [ ] **Given:** User switches tabs rapidly
- [ ] **When:** Tap 5 tabs in quick succession
- [ ] **Then:** No lag, smooth transitions
- [ ] **Expected:** < 200ms per switch

#### TC-PERF.3: Image Load Performance
- [ ] **Given:** User scrolls long food list
- [ ] **When:** Fast scroll through 50+ items
- [ ] **Then:** Images load smoothly from cache
- [ ] **Expected:** 60fps maintained

#### TC-PERF.4: Search Debounce
- [ ] **Given:** User types rapidly in search
- [ ] **When:** Type "phở bò"
- [ ] **Then:** Only 1 search fired after 300ms
- [ ] **Expected:** No stuttering, efficient

#### TC-PERF.5: History Load Time
- [ ] **Given:** User has 100+ history items
- [ ] **When:** Open History tab
- [ ] **Then:** List loads in < 2 seconds
- [ ] **Expected:** Pagination if needed

---

## UI/UX Tests

### Test Cases

#### TC-UI.1: Bottom Nav Icons & Labels
- [ ] **Given:** User views bottom nav
- [ ] **When:** Check all 5 tabs
- [ ] **Then:** Icons and labels correct
- [ ] **Expected:** Dashboard, Search, Favorites, History, Profile

#### TC-UI.2: Active Tab Highlighting
- [ ] **Given:** User on specific tab
- [ ] **When:** Check bottom nav
- [ ] **Then:** Correct tab highlighted in primary color
- [ ] **Expected:** Clear visual feedback

#### TC-UI.3: Pull-to-Refresh Indicator
- [ ] **Given:** User on refreshable screen
- [ ] **When:** Pull down
- [ ] **Then:** Circular progress indicator shown
- [ ] **Expected:** Standard Material Design indicator

#### TC-UI.4: Empty States
- [ ] **Given:** User on screens with no data
- [ ] **When:** View Search (no results), History (empty), Favorites (empty)
- [ ] **Then:** Friendly empty state messages
- [ ] **Expected:** Icons + helpful text

#### TC-UI.5: Loading States
- [ ] **Given:** Data loading
- [ ] **When:** View screens during load
- [ ] **Then:** Shimmer loading indicators shown
- [ ] **Expected:** Smooth, professional look

#### TC-UI.6: Error States
- [ ] **Given:** Network error occurs
- [ ] **When:** Try to load data
- [ ] **Then:** Error message with retry option
- [ ] **Expected:** User-friendly, actionable

---

## Accessibility Tests

### Test Cases

#### TC-A11Y.1: Screen Reader Support
- [ ] **Given:** TalkBack/VoiceOver enabled
- [ ] **When:** Navigate through tabs
- [ ] **Then:** All elements readable
- [ ] **Expected:** Semantic labels present

#### TC-A11Y.2: Touch Target Sizes
- [ ] **Given:** User taps UI elements
- [ ] **When:** Check all interactive elements
- [ ] **Then:** Minimum 48x48dp touch targets
- [ ] **Expected:** Easy to tap, no accidental taps

#### TC-A11Y.3: Color Contrast
- [ ] **Given:** User checks text readability
- [ ] **When:** View all screens
- [ ] **Then:** WCAG AA contrast ratio met
- [ ] **Expected:** Text clearly readable

---

## Security Tests

### Test Cases

#### TC-SEC.1: Authentication Required
- [ ] **Given:** User not logged in
- [ ] **When:** Try to access protected features
- [ ] **Then:** Redirect to login
- [ ] **Expected:** No unauthorized access

#### TC-SEC.2: Data Isolation
- [ ] **Given:** Multiple users
- [ ] **When:** Login as different users
- [ ] **Then:** Only see own data (history, favorites)
- [ ] **Expected:** No data leakage

---

## Test Summary Template

```
Phase 3.5 Testing Results
Date: [Date]
Tester: [Name]

Total Test Cases: 80+
Passed: __ / 80
Failed: __ / 80
Blocked: __ / 80

Critical Issues: __
Major Issues: __
Minor Issues: __

Pass Rate: __%

Overall Status: [PASS/FAIL/PARTIAL]
```

---

## Test Execution Commands

### Run Unit Tests
```bash
cd what_eat_app
flutter test
```

### Run Integration Tests
```bash
cd what_eat_app
flutter test integration_test/
```

### Run on Device
```bash
flutter run --release
```

### Check Code Coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

---

## Known Issues to Verify Fixed

1. ~~Quick Actions grid layout issue~~ → Fixed (replaced with info card)
2. ~~Duplicate navigation buttons~~ → Fixed (bottom nav implemented)
3. ~~No logout confirmation~~ → Fixed (dialog added)
4. ~~History not full-featured~~ → Fixed (full CRUD operations)

---

## Post-Testing Actions

- [ ] Document all bugs found
- [ ] Create bug tickets in issue tracker
- [ ] Update documentation with test results
- [ ] Sign off on Phase 3 completion
- [ ] Plan Phase 4 features if applicable