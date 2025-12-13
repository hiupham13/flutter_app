# Bottom Navigation Implementation

## Overview
Đã implement bottom navigation bar với 5 tabs để cải thiện user experience và navigation flow trong app "Hôm Nay Ăn Gì?".

## Implementation Date
13/12/2024

---

## Architecture

### Main Components

#### 1. MainScreen (`lib/features/main/main_screen.dart`)
**Wrapper screen** chứa bottom navigation bar và PageView để switch giữa các tabs.

**Features:**
- 5 tabs: Dashboard, Search, Favorites, History, Profile
- PageView cho smooth swipe navigation
- Animated tab transitions
- Support initialIndex parameter cho deep linking
- Logout confirmation dialog

**Tab Structure:**
```dart
static const List<Widget> _screens = [
  DashboardScreen(),    // Tab 0
  SearchScreen(),       // Tab 1
  FavoritesScreen(),    // Tab 2
  HistoryScreen(),      // Tab 3
  ProfileScreen(),      // Tab 4
];
```

**Bottom Navigation Items:**
```dart
BottomNavigationBarItem(
  icon: Icon(Icons.home_outlined),
  activeIcon: Icon(Icons.home),
  label: 'Trang chủ',
)
// ... 4 more items
```

---

### 2. Updated Dashboard (`lib/features/dashboard/presentation/dashboard_screen.dart`)

**Changes Made:**
1. **Simplified AppBar:**
   - Removed: Search, Profile navigation buttons (now in bottom nav)
   - Kept: Settings, Logout buttons
   - Added: Center title alignment
   - Added: Logout confirmation dialog

2. **Simplified Quick Actions:**
   - Removed: 2x2 grid with Favorites, History, Search, Refresh
   - Replaced with: "Bối cảnh hiện tại" info card + Refresh button
   - Better UX: Users directed to use bottom nav for main navigation

**Old Quick Actions (Removed):**
```dart
// 2x2 Grid with 4 cards:
// Row 1: Favorites, History
// Row 2: Search, Refresh
```

**New Quick Actions:**
```dart
// Info card với hint sử dụng bottom nav
Container(
  child: Row(
    children: [
      Icon(Icons.info_outline),
      Text('Kéo xuống để làm mới hoặc dùng thanh điều hướng bên dưới...'),
    ],
  ),
)
```

---

### 3. Router Updates (`lib/config/routes/app_router.dart`)

**Changes:**
1. **Updated imports:**
   - Added: `MainScreen`
   - Removed: Individual screen imports (FavoritesScreen, HistoryScreen, ProfileScreen, SearchScreen)

2. **Updated /dashboard route:**
```dart
GoRoute(
  path: '/dashboard',
  name: 'dashboard',
  pageBuilder: (context, state) {
    // Support query parameter: /dashboard?tab=0,1,2,3,4
    final tabParam = state.uri.queryParameters['tab'];
    final initialIndex = int.tryParse(tabParam ?? '0') ?? 0;
    
    return _buildSlidePage(
      state: state,
      child: MainScreen(initialIndex: initialIndex),
      offset: const Offset(0, 0.03),
    );
  },
),
```

3. **Removed individual routes:**
   - `/favorites` - Now tab 2 in MainScreen
   - `/search` - Now tab 1 in MainScreen
   - `/history` - Now tab 3 in MainScreen
   - `/profile` - Now tab 4 in MainScreen

4. **Updated result route fallback:**
```dart
// Changed from: const DashboardScreen()
// To: const MainScreen(initialIndex: 0)
```

---

## Features

### 1. Tab Navigation
- **PageView** cho smooth horizontal swipe
- **BottomNavigationBar** sync với PageView
- Smooth animations với `AppDurations.fast`

### 2. Deep Linking Support
Navigate to specific tab via URL:
```dart
context.goNamed('dashboard', queryParameters: {'tab': '2'}); // Favorites
context.goNamed('dashboard', queryParameters: {'tab': '3'}); // History
```

### 3. State Preservation
- Mỗi tab giữ state riêng khi switch
- PageView không dispose screens khi switch tabs
- ConsumerStatefulWidget pattern giữ Riverpod state

### 4. Logout Flow
- Confirmation dialog trước khi logout
- Clear navigation stack khi logout
- Redirect về login screen

---

## User Experience Improvements

### Before (Old Design):
```
Dashboard AppBar: [Search] [Settings] [Profile] [Logout]
Quick Actions Grid (2x2):
  - Favorites  | History
  - Search     | Refresh
```

**Problems:**
- Duplicate navigation options (Search, Favorites, History, Profile)
- Cluttered AppBar với 4 icons
- Quick Actions grid takes up space
- Navigation không consistent

### After (New Design):
```
Dashboard AppBar: [Settings] [Logout]
Bottom Navigation: [Dashboard] [Search] [Favorites] [History] [Profile]
Quick Actions: Info card + Refresh button
```

**Benefits:**
- ✅ Clean, consistent navigation pattern
- ✅ All main screens accessible from any tab
- ✅ Reduced cognitive load (bottom nav is standard pattern)
- ✅ More screen space for content
- ✅ Better mobile UX (thumb-friendly bottom bar)
- ✅ Familiar pattern for users

---

## Technical Details

### PageView Configuration
```dart
PageView(
  controller: _pageController,
  onPageChanged: _onPageChanged,
  children: _screens,
)
```

### BottomNavigationBar Configuration
```dart
BottomNavigationBar(
  currentIndex: _currentIndex,
  onTap: _onTabTapped,
  type: BottomNavigationBarType.fixed,
  selectedItemColor: AppColors.primary,
  unselectedItemColor: AppColors.textSecondary,
  items: [...],
)
```

### Tab Switching Logic
```dart
void _onTabTapped(int index) {
  setState(() => _currentIndex = index);
  _pageController.animateToPage(
    index,
    duration: AppDurations.fast,
    curve: Curves.easeInOut,
  );
}

void _onPageChanged(int index) {
  setState(() => _currentIndex = index);
}
```

---

## Files Modified

### Created:
1. `lib/features/main/main_screen.dart` - MainScreen với bottom nav

### Modified:
1. `lib/features/dashboard/presentation/dashboard_screen.dart`
   - Simplified AppBar (removed Search, Profile buttons)
   - Simplified Quick Actions (removed grid, added info card)
   - Added logout confirmation dialog

2. `lib/config/routes/app_router.dart`
   - Updated imports
   - Changed /dashboard route to use MainScreen
   - Removed individual routes (favorites, search, history, profile)
   - Updated result route fallback
   - Added tab query parameter support

### Deleted:
- Không có files bị xóa (legacy routes removed from router only)

---

## Testing Checklist

- [ ] Test tab switching via bottom nav
- [ ] Test swipe gestures between tabs
- [ ] Test deep linking với tab parameter
- [ ] Test logout confirmation dialog
- [ ] Test state preservation khi switch tabs
- [ ] Test navigation from Dashboard to Settings
- [ ] Test navigation from result screen back to Dashboard
- [ ] Test pull-to-refresh trên Dashboard
- [ ] Test all screens render correctly in tabs
- [ ] Test bottom nav visibility across all tabs

---

## Known Issues

**None currently identified**

---

## Future Enhancements

1. **Badge Notifications:**
   - Add badges to bottom nav items (e.g., "3 new favorites")
   - Implement notification count on History tab

2. **Tab Customization:**
   - Allow users to reorder tabs
   - Hide/show tabs based on preferences

3. **Gestures:**
   - Add long-press on tab for quick actions
   - Add pull-up gesture for quick menu

4. **Animation:**
   - Add custom page transition animations
   - Add hero animations between tabs

5. **Accessibility:**
   - Add semantic labels
   - Test with screen readers
   - Ensure proper focus management

---

## Notes

- Bottom navigation is **Material Design standard** for mobile apps
- Maximum **5 tabs** recommended for bottom nav (we use exactly 5)
- **Fixed type** used cho consistent tab widths
- All screens remain **stateful** khi switch tabs
- **PageView** cho better UX hơn stack-based navigation

---

## References

- [Material Design - Bottom Navigation](https://material.io/components/bottom-navigation)
- [Flutter PageView Documentation](https://api.flutter.dev/flutter/widgets/PageView-class.html)
- [GoRouter Deep Linking](https://pub.dev/documentation/go_router/latest/)