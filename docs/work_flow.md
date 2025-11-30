# Work Flow & Development Phases: "Hôm Nay Ăn Gì?"

Tài liệu này mô tả chi tiết từng phase và module cần hoàn thiện để đưa dự án từ trạng thái hiện tại đến sản phẩm hoàn chỉnh, production-ready.

---

## 📋 TỔNG QUAN CÁC PHASES

| Phase | Tên Phase | Mục tiêu | Thời gian ước tính | Trạng thái |
|-------|-----------|----------|-------------------|------------|
| **Phase 1** | Foundation & Core Infrastructure | Thiết lập nền tảng vững chắc | 1-2 tuần | ✅ Đã hoàn thành |
| **Phase 2** | Authentication & User Management | Quản lý người dùng và xác thực | 1 tuần | 🚧 Đang làm |
| **Phase 3** | Data Layer & Firebase Integration | Tích hợp Firebase và quản lý dữ liệu | 1-2 tuần | 🚧 Đang làm |
| **Phase 4** | Recommendation Engine & Logic | Hoàn thiện thuật toán gợi ý | 2 tuần | 🚧 Đang làm |
| **Phase 5** | UI/UX Implementation | Xây dựng giao diện người dùng | 2-3 tuần | ⏳ Chưa bắt đầu |
| **Phase 6** | Advanced Features & Polish | Tính năng nâng cao và tinh chỉnh | 1-2 tuần | ⏳ Chưa bắt đầu |
| **Phase 7** | Testing & Optimization | Kiểm thử và tối ưu hóa | 1 tuần | ⏳ Chưa bắt đầu |
| **Phase 8** | Deployment & Launch | Triển khai và phát hành | 1 tuần | ⏳ Chưa bắt đầu |

---

## 🏗️ PHASE 1: FOUNDATION & CORE INFRASTRUCTURE

**Mục tiêu:** Thiết lập cấu trúc dự án, cấu hình môi trường, và các service cơ bản.

### ✅ Modules đã hoàn thành:
- [x] Cấu trúc thư mục Feature-First
- [x] Models cơ bản (User, Food)
- [x] Core services (Location, Weather, Deep Link)
- [x] Theme & UI components cơ bản
- [x] Routing với GoRouter
- [x] State management với Riverpod
- [x] Firebase configuration

### 📦 Modules cần bổ sung:
- [ ] **Error Handling & Logging System**
  - [ ] Global error handler
  - [ ] Crash reporting setup (Firebase Crashlytics)
  - [ ] Logging service hoàn chỉnh

- [ ] **Network & Connectivity**
  - [ ] Network connectivity checker
  - [ ] Retry mechanism cho API calls
  - [ ] Offline mode detection

**Timeline:** 1-2 tuần (Đã hoàn thành ~80%)

---

## 🔐 PHASE 2: AUTHENTICATION & USER MANAGEMENT

**Mục tiêu:** Xây dựng hệ thống xác thực và quản lý thông tin người dùng.

### Module 2.1: Firebase Authentication Integration

**Tasks:**
- [ ] **Setup Firebase Auth Providers**
  - [ ] Google Sign-In integration
  - [ ] Email/Password authentication
  - [ ] Phone authentication (optional)
  - [ ] Anonymous authentication (cho guest mode)

- [ ] **Auth Service Layer**
  - [ ] `lib/features/auth/data/repositories/auth_repository.dart`
    - [ ] `signInWithGoogle()`
    - [ ] `signInWithEmail()`
    - [ ] `signUpWithEmail()`
    - [ ] `signOut()`
    - [ ] `getCurrentUser()`
  - [ ] Error handling cho các trường hợp lỗi

- [ ] **Auth State Management**
  - [ ] `lib/features/auth/logic/auth_provider.dart`
    - [ ] Auth state stream
    - [ ] User profile state
    - [ ] Auto-login on app start

- [ ] **Auth UI Screens**
  - [ ] `lib/features/auth/presentation/login_screen.dart` (đã có, cần hoàn thiện)
    - [ ] Google Sign-In button
    - [ ] Email/Password form
    - [ ] Loading states
    - [ ] Error messages
  - [ ] `lib/features/auth/presentation/register_screen.dart`
  - [ ] `lib/features/auth/presentation/forgot_password_screen.dart`

**Dependencies:** Firebase Auth, Google Sign-In plugin

**Timeline:** 3-4 ngày

---

### Module 2.2: User Profile Management

**Tasks:**
- [ ] **User Model Extension**
  - [ ] Cập nhật `lib/models/user_model.dart`
    - [ ] Thêm fields: preferences, settings, stats
    - [ ] `fromFirestore()` method
    - [ ] `toFirestore()` method

- [ ] **User Repository**
  - [ ] `lib/features/auth/data/repositories/user_repository.dart`
    - [ ] `createUserProfile()`
    - [ ] `updateUserProfile()`
    - [ ] `getUserProfile()`
    - [ ] `updatePreferences()`

- [ ] **User Profile Provider**
  - [ ] `lib/features/auth/logic/user_profile_provider.dart`
    - [ ] Stream user data
    - [ ] Update profile methods

**Dependencies:** Firestore, User Model

**Timeline:** 2-3 ngày

---

### Module 2.3: Onboarding Flow

**Tasks:**
- [ ] **Onboarding Screen**
  - [ ] `lib/features/onboarding/onboarding_screen.dart` (đã có, cần hoàn thiện)
    - [ ] Multi-step form
    - [ ] Step 1: Dị ứng (allergies)
    - [ ] Step 2: Khả năng ăn cay (spice tolerance slider)
    - [ ] Step 3: Mức chi tiêu mặc định (budget default)
    - [ ] Step 4: Sở thích ẩm thực (cuisines)
    - [ ] Progress indicator
    - [ ] Navigation (Next/Back/Skip)

- [ ] **Onboarding Logic**
  - [ ] `lib/features/onboarding/logic/onboarding_provider.dart`
    - [ ] Save preferences to Firestore
    - [ ] Mark onboarding as completed
    - [ ] Navigate to dashboard after completion

- [ ] **Onboarding State Management**
  - [ ] Check if user has completed onboarding
  - [ ] Route guard trong app router

**Dependencies:** User Repository, Firestore

**Timeline:** 3-4 ngày

**Tổng Phase 2:** 1 tuần

---

## 💾 PHASE 3: DATA LAYER & FIREBASE INTEGRATION

**Mục tiêu:** Hoàn thiện lớp dữ liệu, tích hợp Firestore, và implement caching.

### Module 3.1: Firestore Data Structure

**Tasks:**
- [ ] **Setup Firestore Collections**
  - [ ] Tạo collection `master_data` với document `attributes`
    - [ ] Cuisines (vn, kr, jp, ...)
    - [ ] Meal types (dry, soup, hotpot, snack)
    - [ ] Flavors (sour, spicy, sweet, salty)
    - [ ] Allergens (seafood, peanut, dairy)
  - [ ] Tạo collection `foods` với 50-100 món ăn ban đầu
    - [ ] Structure theo schema trong `database.md`
    - [ ] Images cho mỗi món
    - [ ] Context scores
    - [ ] Search keywords
  - [ ] Tạo collection `users` (sẽ được tạo tự động khi user đăng ký)
  - [ ] Tạo collection `activity_logs`
  - [ ] Tạo collection `app_configs` với document `global_config`

- [ ] **Firestore Security Rules**
  - [ ] Rules cho `users` collection (user chỉ đọc/ghi data của mình)
  - [ ] Rules cho `foods` collection (read-only cho users)
  - [ ] Rules cho `activity_logs` (users chỉ ghi log của mình)
  - [ ] Rules cho `master_data` (read-only)

**Dependencies:** Firebase Console, Database schema

**Timeline:** 2-3 ngày

---

### Module 3.2: Food Repository & Data Sources

**Tasks:**
- [ ] **Food Firestore Service** (đã có, cần hoàn thiện)
  - [ ] `lib/features/recommendation/data/sources/food_firestore_service.dart`
    - [ ] `fetchAllFoods()` - Lấy tất cả món ăn
    - [ ] `fetchFoodsByFilters()` - Lọc theo price, cuisine, etc.
    - [ ] `fetchFoodById()` - Lấy món theo ID
    - [ ] `searchFoods()` - Tìm kiếm theo keyword
    - [ ] Error handling

- [ ] **Food Repository** (đã có, cần hoàn thiện)
  - [ ] `lib/features/recommendation/data/repositories/food_repository.dart`
    - [ ] `getAllFoods()` - Lấy từ cache hoặc Firestore
    - [ ] `getFoodsByFilters()` - Lọc món ăn
    - [ ] Cache management (Hive)
    - [ ] Sync mechanism (background sync)
    - [ ] Offline-first approach

- [ ] **Master Data Repository**
  - [ ] `lib/core/data/repositories/master_data_repository.dart`
    - [ ] `getCuisines()`
    - [ ] `getMealTypes()`
    - [ ] `getFlavors()`
    - [ ] `getAllergens()`
    - [ ] Cache master data

**Dependencies:** Firestore, Hive

**Timeline:** 3-4 ngày

---

### Module 3.3: Local Storage & Caching

**Tasks:**
- [ ] **Hive Setup & Configuration**
  - [ ] Initialize Hive trong `main.dart` (đã có)
  - [ ] Tạo Hive adapters cho models
    - [ ] `FoodModelAdapter`
    - [ ] `UserModelAdapter`
    - [ ] `WeatherDataAdapter` (nếu cần)
  - [ ] Run code generation: `flutter pub run build_runner build`

- [ ] **Cache Service**
  - [ ] `lib/core/services/cache_service.dart`
    - [ ] `saveFoodsToCache()`
    - [ ] `getFoodsFromCache()`
    - [ ] `clearCache()`
    - [ ] `isCacheValid()` - Check cache expiry
    - [ ] Cache versioning

- [ ] **Offline Support**
  - [ ] Detect network status
  - [ ] Fallback to cache khi offline
  - [ ] Queue writes khi offline (sync later)

**Dependencies:** Hive, build_runner

**Timeline:** 2-3 ngày

---

### Module 3.4: Activity Logging

**Tasks:**
- [ ] **Activity Log Service**
  - [ ] `lib/core/services/activity_log_service.dart`
    - [ ] `logRecommendationRequest()` - Log khi user yêu cầu gợi ý
    - [ ] `logFoodSelection()` - Log khi user chọn món
    - [ ] `logMapClick()` - Log khi user bấm "Tìm quán"
    - [ ] Batch write để tối ưu cost

- [ ] **Analytics Integration**
  - [ ] Firebase Analytics events
    - [ ] `recommendation_requested`
    - [ ] `food_selected`
    - [ ] `map_opened`
    - [ ] `onboarding_completed`

**Dependencies:** Firestore, Firebase Analytics

**Timeline:** 1-2 ngày

**Tổng Phase 3:** 1-2 tuần

---

## 🧠 PHASE 4: RECOMMENDATION ENGINE & LOGIC

**Mục tiêu:** Hoàn thiện thuật toán gợi ý món ăn thông minh.

### Module 4.1: Scoring Engine Enhancement

**Tasks:**
- [ ] **Scoring Engine** (đã có, cần hoàn thiện)
  - [ ] `lib/features/recommendation/logic/scoring_engine.dart`
    - [ ] **Hard Filters:**
      - [ ] Filter by allergies
      - [ ] Filter by budget
      - [ ] Filter by dietary restrictions (vegetarian)
      - [ ] Filter by available time (morning/lunch/dinner)
    - [ ] **Context Scoring:**
      - [ ] Weather scorer (hot/cold/rain multiplier)
      - [ ] Mood scorer (stress/sick/happy)
      - [ ] Companion scorer (alone/date/group)
      - [ ] Time of day scorer
    - [ ] **Personalization:**
      - [ ] Boost recently eaten foods (avoid repetition)
      - [ ] Boost user's favorite cuisines
      - [ ] Penalize blacklisted foods
    - [ ] **Randomization:**
      - [ ] Add random factor (0-10% of score)
    - [ ] **Final Sorting:**
      - [ ] Sort by final score
      - [ ] Return top 3-5 recommendations

- [ ] **Scoring Tests**
  - [ ] Unit tests cho scoring logic
  - [ ] Test cases cho các scenarios khác nhau

**Dependencies:** Food Model, Weather Service, User Preferences

**Timeline:** 4-5 ngày

---

### Module 4.2: Recommendation Provider

**Tasks:**
- [ ] **Recommendation Provider** (đã có, cần hoàn thiện)
  - [ ] `lib/features/recommendation/logic/recommendation_provider.dart`
    - [ ] `getRecommendation()` - Main method
      - [ ] Collect context (weather, time, location)
      - [ ] Get user preferences
      - [ ] Fetch foods from repository
      - [ ] Run scoring engine
      - [ ] Return recommendations
    - [ ] State management:
      - [ ] Loading state
      - [ ] Success state (with recommendations)
      - [ ] Error state
    - [ ] `getAnotherRecommendation()` - Re-roll
    - [ ] `getRecommendationHistory()` - Lịch sử gợi ý

- [ ] **Context Manager**
  - [ ] `lib/core/services/context_manager.dart`
    - [ ] `getCurrentContext()` - Tổng hợp context
      - [ ] Weather data
      - [ ] Time of day
      - [ ] Location
      - [ ] User preferences

**Dependencies:** Scoring Engine, Food Repository, Weather Service, Location Service

**Timeline:** 3-4 ngày

---

### Module 4.3: Copywriting System

**Tasks:**
- [ ] **Copywriting Service**
  - [ ] `lib/core/services/copywriting_service.dart`
    - [ ] `getGreetingMessage()` - Câu chào theo context
    - [ ] `getRecommendationReason()` - Lý do gợi ý món
    - [ ] `getJokeMessage()` - Câu joke đi kèm
    - [ ] Load từ Firestore `app_configs/copywriting` hoặc local fallback

- [ ] **Copywriting Data**
  - [ ] Tạo document `copywriting` trong `app_configs`
    - [ ] `greetings` - Câu chào theo weather/mood
    - [ ] `reasons` - Lý do gợi ý
    - [ ] `jokes` - Câu joke vui nhộn
  - [ ] Local fallback data (nếu Firestore fail)

**Dependencies:** Firestore, Context Manager

**Timeline:** 2 ngày

**Tổng Phase 4:** 2 tuần

---

## 🎨 PHASE 5: UI/UX IMPLEMENTATION

**Mục tiêu:** Xây dựng giao diện đẹp, thân thiện và trải nghiệm người dùng tốt.

### Module 5.1: Dashboard Screen

**Tasks:**
- [ ] **Dashboard Screen** (đã có, cần hoàn thiện)
  - [ ] `lib/features/dashboard/presentation/dashboard_screen.dart`
    - [ ] **Context Header:**
      - [ ] Dynamic greeting message (theo weather/time)
      - [ ] Weather widget (temperature, condition, icon)
      - [ ] Background thay đổi theo weather
    - [ ] **Main Action Button:**
      - [ ] Large prominent button "Gợi ý ngay"
      - [ ] Alternative: Slot machine animation
      - [ ] Loading state
    - [ ] **Quick Actions:**
      - [ ] Favorites list (nếu có)
      - [ ] Recent recommendations
    - [ ] **Navigation:**
      - [ ] Profile button
      - [ ] Settings button

- [ ] **Dashboard Widgets**
  - [ ] `lib/features/dashboard/presentation/widgets/weather_card.dart`
  - [ ] `lib/features/dashboard/presentation/widgets/recommendation_button.dart`
  - [ ] `lib/features/dashboard/presentation/widgets/quick_favorites.dart`

**Dependencies:** Context Manager, Copywriting Service, Weather Service

**Timeline:** 4-5 ngày

---

### Module 5.2: Recommendation Input Bottom Sheet

**Tasks:**
- [ ] **Input Bottom Sheet**
  - [ ] `lib/features/recommendation/presentation/widgets/input_bottom_sheet.dart`
    - [ ] **Budget Selection:**
      - [ ] 3 options: Cuối tháng (Rẻ) / Bình dân / Sang chảnh
      - [ ] Icon-based selection
    - [ ] **Companion Selection:**
      - [ ] 3 options: Một mình / Hẹn hò / Nhóm bạn
      - [ ] Icon-based selection
    - [ ] **Mood Selection (Optional):**
      - [ ] Vui / Bình thường / Stress / Ốm
      - [ ] Icon-based selection
    - [ ] **Action Button:**
      - [ ] "CHỐT ĐƠN" button
      - [ ] Disabled state khi chưa chọn đủ
    - [ ] **Animations:**
      - [ ] Slide up animation
      - [ ] Selection animations

**Dependencies:** Recommendation Provider

**Timeline:** 3-4 ngày

---

### Module 5.3: Result Screen

**Tasks:**
- [ ] **Result Screen** (đã có, cần hoàn thiện)
  - [ ] `lib/features/recommendation/presentation/result_screen.dart`
    - [ ] **Food Card:**
      - [ ] Hero image (animated)
      - [ ] Food name (large, prominent)
      - [ ] Price range indicator
      - [ ] Tags (cuisine, meal type)
    - [ ] **Recommendation Info:**
      - [ ] Reason text ("Gợi ý vì...")
      - [ ] Joke message
    - [ ] **Action Buttons:**
      - [ ] Primary: "TÌM QUÁN NGAY" → Deep link to Google Maps
      - [ ] Secondary: "Gợi ý khác" → Re-roll
      - [ ] Tertiary: "Lưu vào yêu thích"
    - [ ] **Navigation:**
      - [ ] Back to dashboard
      - [ ] Share button (optional)

- [ ] **Result Widgets**
  - [ ] `lib/features/recommendation/presentation/widgets/food_card.dart`
  - [ ] `lib/features/recommendation/presentation/widgets/recommendation_reason.dart`
  - [ ] `lib/features/recommendation/presentation/widgets/action_buttons.dart`

**Dependencies:** Recommendation Provider, Deep Link Service

**Timeline:** 4-5 ngày

---

### Module 5.4: Core UI Components

**Tasks:**
- [ ] **Enhanced Core Widgets**
  - [ ] `lib/core/widgets/primary_button.dart` (nếu chưa có)
    - [ ] Loading state
    - [ ] Disabled state
    - [ ] Different sizes
  - [ ] `lib/core/widgets/custom_textfield.dart` (nếu chưa có)
  - [ ] `lib/core/widgets/loading_indicator.dart` (nếu chưa có)
  - [ ] `lib/core/widgets/error_widget.dart`
  - [ ] `lib/core/widgets/empty_state_widget.dart`

- [ ] **Food-related Widgets**
  - [ ] `lib/core/widgets/food_image_card.dart`
  - [ ] `lib/core/widgets/price_badge.dart`
  - [ ] `lib/core/widgets/food_tags_chip.dart`

**Timeline:** 2-3 ngày

---

### Module 5.5: Animations & Transitions

**Tasks:**
- [ ] **Page Transitions**
  - [ ] Custom route transitions
  - [ ] Hero animations cho food images
  - [ ] Slide transitions

- [ ] **Micro-interactions**
  - [ ] Button press animations
  - [ ] Loading shimmer effects
  - [ ] Success/error feedback animations

**Timeline:** 2-3 ngày

**Tổng Phase 5:** 2-3 tuần

---

## 🚀 PHASE 6: ADVANCED FEATURES & POLISH

**Mục tiêu:** Thêm tính năng nâng cao và tinh chỉnh trải nghiệm.

### Module 6.1: Favorites & History

**Tasks:**
- [ ] **Favorites Feature**
  - [ ] `lib/features/favorites/presentation/favorites_screen.dart`
  - [ ] Add/remove favorite
  - [ ] Favorites list
  - [ ] Quick access từ dashboard

- [ ] **Recommendation History**
  - [ ] `lib/features/history/presentation/history_screen.dart`
  - [ ] View past recommendations
  - [ ] Re-select from history

**Timeline:** 2-3 ngày

---

### Module 6.2: Search & Filter

**Tasks:**
- [ ] **Food Search**
  - [ ] `lib/features/search/presentation/search_screen.dart`
  - [ ] Search by name/keyword
  - [ ] Filter by price, cuisine, meal type
  - [ ] Search results display

**Timeline:** 2-3 ngày

---

### Module 6.3: Settings & Preferences

**Tasks:**
- [ ] **Settings Screen**
  - [ ] `lib/features/settings/presentation/settings_screen.dart`
    - [ ] Update preferences
    - [ ] Change default budget
    - [ ] Update allergies
    - [ ] Theme toggle (light/dark)
    - [ ] Language settings (nếu có)
    - [ ] Logout option

**Timeline:** 2 ngày

---

### Module 6.4: Feedback & Reporting

**Tasks:**
- [ ] **Feedback System**
  - [ ] `lib/features/feedback/presentation/feedback_screen.dart`
  - [ ] Report wrong food info
  - [ ] Rate recommendation
  - [ ] Submit feedback

**Timeline:** 1-2 ngày

---

### Module 6.5: Performance Optimization

**Tasks:**
- [ ] **Image Optimization**
  - [ ] Lazy loading images
  - [ ] Image caching
  - [ ] Placeholder images

- [ ] **Code Optimization**
  - [ ] Remove unused code
  - [ ] Optimize rebuilds
  - [ ] Memory leak checks

**Timeline:** 2-3 ngày

**Tổng Phase 6:** 1-2 tuần

---

## 🧪 PHASE 7: TESTING & OPTIMIZATION

**Mục tiêu:** Đảm bảo chất lượng và hiệu suất ứng dụng.

### Module 7.1: Unit Testing

**Tasks:**
- [ ] **Logic Tests**
  - [ ] Scoring engine tests
  - [ ] Repository tests
  - [ ] Service tests

- [ ] **Model Tests**
  - [ ] Model serialization tests
  - [ ] Model validation tests

**Timeline:** 2-3 ngày

---

### Module 7.2: Widget Testing

**Tasks:**
- [ ] **UI Component Tests**
  - [ ] Core widgets tests
  - [ ] Feature screens tests
  - [ ] Integration tests cho main flows

**Timeline:** 2-3 ngày

---

### Module 7.3: Manual Testing & QA

**Tasks:**
- [ ] **Test Scenarios**
  - [ ] Happy path testing
  - [ ] Error handling testing
  - [ ] Offline mode testing
  - [ ] Different device sizes
  - [ ] Different Android versions

- [ ] **Bug Fixing**
  - [ ] Fix critical bugs
  - [ ] Fix UI/UX issues
  - [ ] Performance improvements

**Timeline:** 2-3 ngày

**Tổng Phase 7:** 1 tuần

---

## 🚢 PHASE 8: DEPLOYMENT & LAUNCH

**Mục tiêu:** Chuẩn bị và phát hành ứng dụng.

### Module 8.1: Pre-Launch Preparation

**Tasks:**
- [ ] **App Icons & Assets**
  - [ ] App icon (all sizes)
  - [ ] Splash screen
  - [ ] Store screenshots
  - [ ] Feature graphics

- [ ] **App Store Listings**
  - [ ] App description (Vietnamese & English)
  - [ ] Keywords
  - [ ] Privacy policy
  - [ ] Terms of service

- [ ] **Firebase Production Setup**
  - [ ] Production Firebase project
  - [ ] Security rules review
  - [ ] Analytics setup
  - [ ] Crashlytics setup

**Timeline:** 2-3 ngày

---

### Module 8.2: Build & Release

**Tasks:**
- [ ] **Android Build**
  - [ ] Generate signed APK/AAB
  - [ ] Version code/name update
  - [ ] ProGuard/R8 configuration
  - [ ] Test release build

- [ ] **iOS Build** (nếu có)
  - [ ] Xcode configuration
  - [ ] App Store Connect setup
  - [ ] TestFlight testing

- [ ] **Release Checklist**
  - [ ] All features tested
  - [ ] No critical bugs
  - [ ] Performance acceptable
  - [ ] Analytics working
  - [ ] Crashlytics working

**Timeline:** 2-3 ngày

---

### Module 8.3: Launch & Monitoring

**Tasks:**
- [ ] **App Store Submission**
  - [ ] Google Play Console setup
  - [ ] Upload AAB
  - [ ] Submit for review

- [ ] **Post-Launch Monitoring**
  - [ ] Monitor crash reports
  - [ ] Monitor analytics
  - [ ] User feedback collection
  - [ ] Performance monitoring

**Timeline:** Ongoing

**Tổng Phase 8:** 1 tuần

---

## 📊 TỔNG KẾT TIMELINE

| Phase | Thời gian | Tổng cộng |
|-------|-----------|-----------|
| Phase 1 | 1-2 tuần | ✅ Hoàn thành |
| Phase 2 | 1 tuần | 1 tuần |
| Phase 3 | 1-2 tuần | 2-3 tuần |
| Phase 4 | 2 tuần | 4-5 tuần |
| Phase 5 | 2-3 tuần | 6-8 tuần |
| Phase 6 | 1-2 tuần | 7-10 tuần |
| Phase 7 | 1 tuần | 8-11 tuần |
| Phase 8 | 1 tuần | 9-12 tuần |

**Tổng thời gian ước tính:** 9-12 tuần (2.5-3 tháng) để hoàn thiện dự án từ đầu đến cuối.

---

## 🎯 PRIORITY MATRIX

### High Priority (Must Have)
- Phase 2: Authentication & User Management
- Phase 3: Data Layer & Firebase Integration
- Phase 4: Recommendation Engine & Logic
- Phase 5: UI/UX Implementation (Core screens)

### Medium Priority (Should Have)
- Phase 6: Advanced Features (Favorites, Search)
- Phase 7: Testing & Optimization

### Low Priority (Nice to Have)
- Phase 6: Advanced Features (Feedback, Settings nâng cao)
- Phase 8: iOS deployment (nếu chỉ focus Android trước)

---

## 📝 NOTES & BEST PRACTICES

1. **Agile Development:** Làm theo vertical slices (từng feature hoàn chỉnh) thay vì làm tuần tự frontend/backend.

2. **Incremental Delivery:** Mỗi phase nên có deliverable có thể test được.

3. **Code Review:** Review code sau mỗi module lớn.

4. **Documentation:** Cập nhật documentation khi thêm tính năng mới.

5. **Version Control:** Commit thường xuyên với messages rõ ràng.

6. **Testing:** Viết test song song với development, không để đến cuối.

---

## 🔄 ITERATION & IMPROVEMENTS

Sau khi hoàn thành MVP, có thể tiếp tục phát triển:

- **Machine Learning:** Sử dụng activity logs để train model cá nhân hóa
- **Social Features:** Chia sẻ recommendations với bạn bè
- **Restaurant Integration:** Tích hợp với GrabFood, ShopeeFood APIs
- **Gamification:** Achievements, streaks, points
- **Multi-language:** Hỗ trợ tiếng Anh, tiếng Việt

---

**Cập nhật lần cuối:** [Ngày hiện tại]
**Version:** 1.0.0

