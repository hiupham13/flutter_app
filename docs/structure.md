Đây là cấu trúc thư mục **Clean & Agile** chuẩn, tối ưu nhất cho dự án **Flutter + Firebase** của bạn. Cấu trúc này tuân theo nguyên tắc **"Feature-First"** (Chia theo tính năng) kết hợp với **Repository Pattern**.

Nó giúp bạn code nhanh, dễ tìm file, và quan trọng nhất là dễ dàng mở rộng khi dự án lớn lên.

### 📂 CẤU TRÚC THƯ MỤC (PROJECT STRUCTURE)

```text
lib/
├── main.dart                       # 🚀 Điểm khởi chạy (Init Firebase, Config)
├── app.dart                        # 📱 Root Widget (MaterialApp, Providers Scope)
│
├── config/                         # ⚙️ Cấu hình toàn App
│   ├── routes/                     # Định nghĩa đường dẫn (GoRouter/AutoRoute)
│   └── theme/                      # Màu sắc, font chữ, style chung
│
├── core/                           # 🛠 TÀI NGUYÊN DÙNG CHUNG (Shared)
│   ├── constants/                  # String cứng, API keys, Enum
│   │   ├── app_colors.dart
│   │   └── firebase_collections.dart # Tên các collection ('foods', 'users')
│   ├── utils/                      # Hàm hỗ trợ (Helper)
│   │   ├── currency_formatter.dart
│   │   ├── date_formatter.dart
│   │   └── logger.dart
│   ├── services/                   # Service nền tảng (Third-party)
│   │   ├── location_service.dart   # Lấy GPS
│   │   ├── weather_service.dart    # Gọi API thời tiết
│   │   └── deep_link_service.dart  # Mở Google Maps
│   └── widgets/                    # UI Component dùng lại nhiều lần
│       ├── primary_button.dart
│       ├── custom_textfield.dart
│       └── loading_indicator.dart
│
├── models/                         # 📦 GLOBAL MODELS (Dữ liệu dùng xuyên suốt)
│   ├── user_model.dart             # Map từ Firebase Auth
│   └── food_model.dart             # ⭐️ Quan trọng: Map món ăn từ Firestore
│
└── features/                       # 🧩 CÁC TÍNH NĂNG (Chia theo nghiệp vụ)
    ├── auth/                       # Đăng nhập / Đăng ký
    │   ├── data/                   # Repo xử lý Auth Firebase
    │   ├── logic/                  # AuthController (Riverpod)
    │   └── presentation/           # LoginScreen, RegisterScreen
    │
    ├── onboarding/                 # Màn hình hỏi sở thích ban đầu
    │   └── ...
    │
    ├── dashboard/                  # Màn hình chính
    │   └── presentation/           # DashboardScreen (Kết hợp Weather + Action)
    │
    └── recommendation/             # ❤️ CORE FEATURE: Gợi ý món ăn
        ├── data/                   
        │   ├── repositories/       # 🛡 Lớp trung gian (Quyết định lấy Cache hay Firebase)
        │   │   └── food_repository.dart 
        │   └── sources/            # ☁️ Gọi trực tiếp Firestore
        │       └── food_firestore_service.dart
        │
        ├── logic/                  # 🧠 BỘ NÃO XỬ LÝ
        │   ├── scoring_engine.dart # ⭐️ Thuật toán tính điểm (Logic thuần)
        │   └── recommendation_provider.dart # Quản lý State (Loading/Success/Error)
        │
        └── presentation/           # 🎨 GIAO DIỆN
            ├── widgets/            # Widget con (InputBottomSheet, FoodCard)
            └── result_screen.dart  # Màn hình kết quả
```

-----

### 📝 GIẢI THÍCH CHI TIẾT CÁC THÀNH PHẦN QUAN TRỌNG

#### 1\. `lib/models/` (Bắt buộc có)

Đây là nơi bạn chuyển đổi dữ liệu từ "ngôn ngữ Firebase" (Map/JSON) sang "ngôn ngữ Flutter" (Class Object).

  * **`food_model.dart`**:
    ```dart
    class FoodModel {
      final String id;
      final String name;
      final int price;
      // ...
      factory FoodModel.fromFirestore(DocumentSnapshot doc) { ... }
    }
    ```

#### 2\. `features/recommendation/data/` (Thay thế Backend Folder)

Đây là nơi bạn giao tiếp với Firebase.

  * **`food_firestore_service.dart`**: Chỉ lo việc kết nối.
    ```dart
    // Chỉ làm 1 việc: Lấy raw data từ collection 'foods'
    Future<List<FoodModel>> fetchAllFoods() async { ... }
    ```
  * **`food_repository.dart`**: Logic lấy dữ liệu thông minh.
    ```dart
    // Kiểm tra: Nếu có mạng -> Gọi Service lấy mới -> Lưu Cache.
    // Nếu mất mạng -> Lấy từ Cache (Hive).
    ```

#### 3\. `features/recommendation/logic/` (Nơi chứa thuật toán)

Phần khó nhất của dự án nằm ở đây, tách biệt hoàn toàn với UI.

  * **`scoring_engine.dart`**: File này không chứa code Flutter UI, chỉ chứa logic tính toán.
    ```dart
    class ScoringEngine {
      double calculateScore(FoodModel food, WeatherContext weather) {
        // Nếu trời nóng (weather.temp > 35) mà món là Lẩu -> return score * 0.5
        // Nếu trời mưa -> return score * 1.5
      }
    }
    ```

#### 4\. `core/services/`

Nơi chứa các code không liên quan đến nghiệp vụ món ăn, nhưng cần để App chạy.

  * Ví dụ: `location_service.dart` chỉ trả về tọa độ `Lat/Lng`. Nó không cần biết bạn dùng tọa độ đó để tìm quán ăn hay tìm người yêu.

### ✅ LỢI ÍCH CỦA CẤU TRÚC NÀY

1.  **Dễ tìm code:** Lỗi ở màn hình "Gợi ý"? -\> Vào thư mục `features/recommendation`. Lỗi không đăng nhập được? -\> Vào `features/auth`. Không phải lục lọi lung tung.
2.  **Làm việc nhóm tốt:** Bạn làm folder `recommendation`, người khác làm `auth`, không bao giờ bị đụng code nhau (Git Conflict).
3.  **Dễ bảo trì:** Nếu sau này bạn muốn đổi thuật toán tính điểm, chỉ cần sửa đúng 1 file `scoring_engine.dart`, không sợ làm hỏng giao diện.
4.  **Chuẩn bị cho Scale:** Nếu App phức tạp lên, chỉ cần thêm folder tính năng mới vào `features/` là xong.

