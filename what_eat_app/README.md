# Hôm Nay Ăn Gì? - What Eat App

Ứng dụng gợi ý món ăn thông minh dựa trên ngữ cảnh (thời tiết, túi tiền, tâm trạng, người đi cùng).

## 🚀 Công nghệ sử dụng

- **Flutter** - Framework phát triển ứng dụng đa nền tảng
- **Firebase** - Backend services (Auth, Firestore, Analytics)
- **Riverpod** - State management
- **Hive** - Local storage/cache
- **Dio** - HTTP client cho API calls
- **GoRouter** - Navigation & routing

## 📁 Cấu trúc dự án

Dự án được tổ chức theo nguyên tắc **Feature-First** kết hợp với **Repository Pattern**:

```
lib/
├── main.dart                       # Điểm khởi chạy (Init Firebase, Config)
├── app.dart                        # Root Widget (MaterialApp, Providers Scope)
│
├── config/                         # Cấu hình toàn App
│   ├── routes/                     # Định nghĩa đường dẫn (GoRouter)
│   └── theme/                      # Màu sắc, font chữ, style chung
│
├── core/                           # Tài nguyên dùng chung
│   ├── constants/                  # String cứng, API keys, Enum
│   ├── utils/                      # Hàm hỗ trợ (Helper)
│   ├── services/                   # Service nền tảng (Third-party)
│   └── widgets/                    # UI Component dùng lại nhiều lần
│
├── models/                         # Global Models
│   ├── user_model.dart
│   └── food_model.dart
│
└── features/                       # Các tính năng (Chia theo nghiệp vụ)
    ├── auth/                       # Đăng nhập / Đăng ký
    ├── onboarding/                 # Màn hình hỏi sở thích ban đầu
    ├── dashboard/                  # Màn hình chính
    └── recommendation/             # Core Feature: Gợi ý món ăn
        ├── data/                   # Repositories & Sources
        ├── logic/                  # Scoring Engine & Providers
        └── presentation/           # UI Screens & Widgets
```

## 🛠️ Setup & Installation

### 1. Cài đặt dependencies

```bash
cd what_eat_app
flutter pub get
```

### 2. Setup Firebase

1. Tạo project mới trên [Firebase Console](https://console.firebase.google.com/)
2. Thêm Android/iOS app vào project
3. Download file cấu hình:
   - Android: `google-services.json` → đặt vào `android/app/`
   - iOS: `GoogleService-Info.plist` → đặt vào `ios/Runner/`
4. Cài đặt FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```
5. Chạy lệnh để tự động cấu hình:
   ```bash
   flutterfire configure
   ```

### 3. Cấu hình API Keys

- **Weather Service**: 
  - Ứng dụng sử dụng [Open-Meteo API](https://open-meteo.com/) - **miễn phí và không cần API key**
  - Service đã được cấu hình sẵn trong `lib/core/services/weather_service.dart`
  - Không cần cấu hình thêm gì, có thể sử dụng ngay

### 4. Chạy ứng dụng

```bash
flutter run
```

## 📝 Tính năng chính

### ✅ Đã hoàn thành (Cấu trúc cơ bản)

- [x] Cấu trúc dự án theo Feature-First
- [x] Models (User, Food)
- [x] Core services (Location, Weather, Deep Link)
- [x] Repository pattern cho Food data
- [x] Scoring Engine (Thuật toán gợi ý)
- [x] State management với Riverpod
- [x] Routing với GoRouter
- [x] Theme & UI components cơ bản

### 🚧 Đang phát triển

- [ ] Firebase Authentication
- [ ] Onboarding flow
- [ ] Dashboard UI với context awareness
- [ ] Recommendation UI (Input bottom sheet, Result screen)
- [ ] Hive cache implementation
- [ ] Activity logs tracking

## 📚 Tài liệu tham khảo

Xem thêm trong thư mục `docs/`:
- `structure.md` - Cấu trúc dự án chi tiết
- `overview_flutter.md` - Tổng quan kiến trúc
- `database.md` - Schema database Firestore
- `system_flow.md` - Luồng hoạt động hệ thống
- `work_flow.md` - **Workflow & Development Phases** (Chi tiết từng phase và module)

## 🤝 Đóng góp

Dự án này được phát triển theo nguyên tắc Clean & Agile, tập trung vào:
- Code sạch, dễ đọc
- Dễ bảo trì và mở rộng
- Performance tối ưu
- User experience tốt

## 📄 License

Private project - All rights reserved
