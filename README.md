
-----

````markdown
# 🍜 HÔM NAY ĂN GÌ? (What To Eat Today?)

> **Smart Context-Aware Food Recommendation App** > Giải quyết câu hỏi thế kỷ: *"Trưa nay ăn gì?"* bằng thuật toán gợi ý dựa trên Thời tiết, Túi tiền và Cảm xúc.

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?style=flat&logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-Core-orange?style=flat&logo=firebase)
![Status](https://img.shields.io/badge/Status-In%20Development-green)

---

## 📖 Mục Lục
1. [Tổng Quan Dự Án](#-tổng-quan-dự-án)
2. [Tech Stack & Core Libraries](#-tech-stack--core-libraries)
3. [Kiến Trúc Hệ Thống](#-kiến-trúc-hệ-thống)
4. [Cấu Trúc Thư Mục](#-cấu-trúc-thư-mục)
5. [Cơ Sở Dữ Liệu (Firestore)](#-cơ-sở-dữ-liệu)
6. [Development Rules (QUAN TRỌNG)](#-development-rules-quan-trọng)
7. [Cài Đặt & Chạy](#-cài-đặt--chạy)

---

## 💡 Tổng Quan Dự Án

Ứng dụng giúp người dùng đưa ra quyết định ăn uống nhanh chóng dựa trên ngữ cảnh thực tế thay vì chỉ liệt kê món ăn vô hồn.

### Key Features (Tính năng cốt lõi)
* **Context Awareness:** Tự động nhận diện Thời tiết (Nắng/Mưa), Thời gian (Sáng/Trưa/Tối) để gợi ý.
* **Natural Filtering:** Lọc theo Túi tiền (Sinh viên/Sang chảnh), Người đi cùng (Gấu/Nhóm/Một mình).
* **Smart Scoring Algorithm:** Thuật toán tính điểm ưu tiên món phù hợp nhất với context hiện tại.
* **Cost-Saving Location:** Sử dụng **Deep Link** để mở Google Maps/ShopeeFood tìm quán (Không tích hợp Map SDK tốn phí).
* **Fun UX:** Giao diện vui vẻ, sử dụng các câu "cà khịa" (Copywriting) để tương tác tự nhiên.

---

## 🛠 Tech Stack & Core Libraries

Để đảm bảo tính thống nhất và hiệu năng, dự án sử dụng các công nghệ sau. **Tuyệt đối không tự ý thay thế nếu không có sự thảo luận.**

| Category | Technology | Lý do lựa chọn |
| :--- | :--- | :--- |
| **Frontend** | **Flutter** (Stable Channel) | Cross-platform, Performance cao. |
| **Backend** | **Firebase** (Auth, Firestore) | Serverless, Realtime, Dev nhanh. |
| **State Mngt** | **Riverpod** (flutter_riverpod) | An toàn, Testable, không bị magic như GetX. |
| **Navigation** | **GoRouter** | Quản lý Deep Link và Route lồng nhau tốt. |
| **Local DB** | **Hive** | NoSQL local database siêu nhanh để Cache món ăn. |
| **Network** | **Dio** | Gọi API Weather (mạnh hơn http client mặc định). |
| **Model Gen** | **Freezed** + **JsonSerializable** | Tự sinh code `copyWith`, `fromJson` an toàn. |

---

## 🏗 Kiến Trúc Hệ Thống

Dự án áp dụng kiến trúc **Feature-First** kết hợp **Repository Pattern**.

* **Feature-First:** Code được chia theo tính năng (Auth, Dashboard, Recommendation). Xóa tính năng = Xóa 1 folder.
* **Repository Pattern:** Tách biệt Logic lấy dữ liệu (Data Layer) và Giao diện (UI Layer).

### Data Flow Diagram
```mermaid
UI (Widget) -> Controller (Riverpod) -> Logic (Scoring Engine) -> Repository -> [Remote: Firebase] OR [Local: Hive]
````

-----

## 📂 Cấu Trúc Thư Mục

```text
lib/
├── main.dart                       # Entry Point
├── app.dart                        # Root Widget & Config
├── core/                           # TÀI NGUYÊN DÙNG CHUNG
│   ├── constants/                  # Colors, Strings, API Keys
│   ├── services/                   # WeatherService, LocationService
│   ├── utils/                      # Logger, Formatter
│   └── widgets/                    # Buttons, TextFields chuẩn
├── models/                         # GLOBAL MODELS (User, Food)
└── features/                       # TÍNH NĂNG NGHIỆP VỤ
    ├── auth/                       # Đăng nhập/ký
    ├── dashboard/                  # Màn hình chính
    └── recommendation/             # ⭐️ CORE FEATURE
        ├── data/                   # Data Layer (API & Repo)
        ├── logic/                  # Business Logic (Scoring Algo)
        └── presentation/           # UI (Screens & Widgets)
```

-----

## 💾 Cơ Sở Dữ Liệu

Sử dụng **Cloud Firestore**. Cấu trúc Schema chuẩn:

### 1\. Collections Chính

  * **`master_data/attributes`**: Danh mục dùng chung (Cuisines, Meal Types, Allergens).
  * **`foods`**: Danh sách món ăn. Chứa `price_segment`, `context_scores` (điểm số theo thời tiết/mood).
  * **`users`**: Profile người dùng và Settings (Ăn chay, Dị ứng).
  * **`activity_logs`**: Lưu lịch sử chọn món (Tách riêng để không nặng user doc).
  * **`app_configs`**: Cấu hình từ xa (Jokes, Feature Flags).

### 2\. Quy ước Enums (Convention)

  * **Price Segment:** `1` (Rẻ \<35k), `2` (Vừa 35-80k), `3` (Sang \>80k).
  * **Weather Code:** `hot` (\>32°C), `rain`, `cool`, `cold`.

-----

## 🚦 Development Rules (QUAN TRỌNG)

Để giữ code sạch và dễ bảo trì, mọi thành viên tuân thủ các quy tắc sau:

### 1\. Coding Style

  * Sử dụng **Linter** mặc định của Flutter (`flutter_lints`). Không được ignore warning trừ khi bất khả kháng.
  * **Naming:**
      * Tên file: `snake_case` (vd: `food_repository.dart`).
      * Tên class: `PascalCase` (vd: `FoodRepository`).
      * Tên biến: `camelCase` (vd: `foodList`).

### 2\. Logic Rules

  * **Tuyệt đối không** viết logic tính toán phức tạp (Scoring) trong file UI (`.dart` chứa Widget). Hãy đưa vào `logic/scoring_engine.dart`.
  * **Tuyệt đối không** gọi trực tiếp `FirebaseFirestore.instance` trong UI. Phải gọi qua `Repository`.
  * **Xử lý null:** Luôn define giá trị mặc định cho Model khi parse từ Firebase.

### 3\. Git Workflow

  * Nhánh chính: `main` (Production).
  * Nhánh phát triển: `develop`.
  * Nhánh tính năng: `feat/ten-tinh-nang` (vd: `feat/add-weather-api`).
  * **Commit Message:** Tuân thủ Conventional Commits.
      * `feat: thêm màn hình login`
      * `fix: sửa lỗi crash khi mất mạng`
      * `refactor: tối ưu code scoring`

-----

## 🚀 Cài Đặt & Chạy

1.  **Clone dự án:**
    ```bash
    git clone [repo_url]
    ```
2.  **Cài đặt dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Setup Firebase:**
      * Cài đặt `flutterfire_cli`.
      * Chạy `flutterfire configure` để liên kết dự án với Firebase Console.
4.  **Code generation (nếu dùng Freezed):**
    ```bash
    dart run build_runner build -d
    ```
5.  **Chạy App:**
    ```bash
    flutter run
    ```

-----
