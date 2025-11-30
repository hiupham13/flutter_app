Dưới đây là nội dung file `overview_flutter.md` đã được tối ưu hóa, loại bỏ các phần rườm rà và cập nhật toàn bộ các tính năng "tự nhiên hóa" (ngữ cảnh, thời tiết, tài chính) mà chúng ta đã thảo luận. Bạn có thể copy toàn bộ nội dung bên dưới để thay thế file cũ.

-----

# Project Architecture: "Hôm Nay Ăn Gì?" (Smart Context-Aware Version)

## I. TỔNG QUAN NGHIỆP VỤ & LOGIC HỆ THỐNG

### 1\. Mục Tiêu Cốt Lõi

Giải quyết vấn đề "Hôm nay ăn gì?" một cách **tự nhiên, hài hước và phù hợp thực tế**. Hệ thống không chỉ đưa ra món ăn, mà đưa ra giải pháp dựa trên: **Túi tiền + Thời tiết + Cảm xúc + Người đi cùng.**

### 2\. Luồng Nghiệp Vụ Thông Minh (The "Natural" Flow)

1.  **Context Detection (Tự động):**
      * Khi App mở, tự động lấy dữ liệu: Giờ (Sáng/Trưa/Tối), Thời tiết (Nắng/Mưa/Lạnh - qua API), Vị trí.
      * *Ví dụ:* App nhận diện "Trưa nay 35°C, Nắng gắt".
2.  **Quick Trigger (Kích hoạt):**
      * Dashboard chào hỏi theo ngữ cảnh (VD: "Nắng thế này đừng ra đường, kiếm gì mát mát ăn đi\!").
      * User bấm nút **"Gợi ý ngay"** hoặc **"Quay thưởng"**.
3.  **Dynamic Input (Hỏi nhanh 3 giây):**
      * Hệ thống hỏi 3 biến số quan trọng nhất:
          * **Tiền:** "Cuối tháng" (Rẻ) vs "Vừa lãnh lương" (Sang).
          * **Bạn:** "Đi một mình" vs "Đi Date" vs "Nhóm lẩu".
          * **Mood:** "Bình thường" vs "Stress" vs "Chán đời".
4.  **Smart Recommendation (Xử lý):**
      * Lọc cứng (Dị ứng/Giá) -\> Tính điểm theo ngữ cảnh (Trời nóng giảm điểm món lẩu, tăng điểm món cuốn) -\> Random nhẹ.
5.  **Actionable Result (Kết quả):**
      * Hiển thị món ăn kèm **"Câu cà khịa/quan tâm"**.
      * Nút **"Tìm quán"** sẽ Deep Link thẳng sang Google Maps/ShopeeFood (Tiết kiệm chi phí xây map).

-----

## II. PHÂN TÍCH MODULE (MODULE BREAKDOWN)

### 1\. **CORE\_SERVICES\_MODULE** (Dịch vụ nền tảng)

  - **weather\_service**: Tích hợp OpenWeatherMap/AccuWeather (Lấy Temp, Weather Condition).
  - **location\_service**: Lấy toạ độ GPS hiện tại.
  - **time\_manager**: Logic xác định khung giờ ăn (Breakfast, Lunch, Dinner, Late Night).
  - **deep\_link\_service**: Tạo link mở Google Maps/Food Apps từ tên món ăn.

### 2\. **AUTH\_USER\_MODULE** (Quản lý người dùng)

  - **auth\_module**: Login/Register (Ưu tiên Google Sign-In).
  - **user\_profile\_module**: Lưu thông tin cơ bản.
  - **preference\_module**: Lưu khẩu vị gốc (Ăn chay/mặn, Dị ứng, Mức cay mặc định).
  - **wallet\_profile\_module**: Lưu thói quen chi tiêu (Sinh viên / Văn phòng / Sang chảnh).

### 3\. **RECOMMENDATION\_ENGINE\_MODULE** (Core Algorithm)

  - **input\_collector\_widget**: UI BottomSheet thu thập nhanh input (Tiền, Mood, Bạn).
  - **filtering\_engine**:
      - **hard\_filter**: Loại bỏ món dị ứng, món quá ngân sách.
      - **time\_filter**: Loại bỏ món không bán giờ hiện tại (VD: Phở ít bán trưa).
  - **scoring\_engine**:
      - **weather\_scorer**: Tăng/giảm điểm dựa trên nhiệt độ.
      - **mood\_scorer**: Mood "Stress" ưu tiên đồ ngọt/cay; Mood "Sick" ưu tiên cháo/soup.
      - **social\_scorer**: Đi Date tránh mắm tôm; Đi nhóm ưu tiên Lẩu/Nướng.
  - **copywriting\_generator**: Sinh câu thoại vui nhộn đi kèm kết quả.

### 4\. **DATA\_MODULE** (Quản lý dữ liệu)

  - **food\_repository**: Quản lý danh sách món ăn từ Firestore.
  - **local\_storage**: Cache dữ liệu (Hive/Isar) để app chạy nhanh và offline mode.
  - **data\_seeder**: Script nạp 50-100 món ăn phổ biến ban đầu.

### 5\. **UI\_MODULES** (Giao diện)

  - **onboarding\_module**: Hỏi sở thích ngắn gọn, súc tích.
  - **dashboard\_module**:
      - **Context Header**: Hiển thị chào hỏi + Thời tiết.
      - **Trigger Button**: Nút bấm lớn / Slot Machine.
  - **result\_module**: Hiển thị món gợi ý, lý do, và nút hành động.

-----

## III. THUẬT TOÁN GỢI Ý CHI TIẾT (SCORING LOGIC)

Công thức: `FINAL_SCORE = (BASE_SCORE * MULTIPLIERS) + RANDOM_FACTOR`

### 1\. Các Yếu Tố "Lọc Cứng" (Hard Filters - Loại ngay lập tức)

  * **Dị ứng:** Món chứa thành phần User dị ứng.
  * **Ngân sách:** Giá trung bình món \> Ngân sách User chọn.
  * **Chế độ ăn:** User ăn chay -\> Loại món mặn.

### 2\. Các Yếu Tố "Tính Điểm Ngữ Cảnh" (Context Multipliers)

| Ngữ Cảnh | Điều Kiện | Tác Động Lên Món Ăn |
| :--- | :--- | :--- |
| **Thời tiết** | Nóng (\>32°C) | Món nước nóng x0.6 | Món nướng x0.8 | Salad, Cuốn x1.4 |
| | Mưa / Lạnh | Lẩu, Nướng, Cháo x1.5 | Salad, Đồ nguội x0.6 |
| **Người đi cùng** | Một mình (Alone) | Cơm dĩa, Tô (nhanh) x1.2 | Lẩu to x0.1 |
| | Hẹn hò (Date) | Món nặng mùi (Mắm) x0.1 | Không gian đẹp x1.3 |
| | Nhóm (Group) | Lẩu, Nướng, Combo x1.8 |
| **Tâm trạng** | Stress | Đồ ngọt, Cay cấp độ cao x1.4 |
| | Ốm/Mệt | Cháo, Soup x2.0 | Dầu mỡ x0.2 |

### 3\. Yếu Tố Ngẫu Nhiên (Natural Randomness)

  * Luôn cộng thêm `Random(0, 10)` điểm vào kết quả cuối để danh sách gợi ý luôn có sự thay đổi nhẹ, tránh nhàm chán.

-----

## IV. CẤU TRÚC DỮ LIỆU (FIRESTORE SCHEMA)

### 1\. Foods Collection (`/foods`)

```json
{
  "id": "bun_dau_mam_tom",
  "name": "Bún Đậu Mắm Tôm",
  "image_url": "url_to_image",
  "price_segment": 2,          // 1: <35k, 2: 35k-80k, 3: >100k
  "tags": ["bun", "man", "heavy", "street-food"],
  "weather_suitability": {
    "hot": 0.8,                // Hơi nồng khi trời nóng
    "rain": 1.2,               // Ăn khi mưa rất ngon
    "cold": 1.0
  },
  "best_companions": ["group", "alone"], // Date nên tránh
  "is_spicy_adjustable": true, // Có thể chỉnh độ cay (ớt)
  "search_keywords": ["bún đậu", "mẹt tá lả", "bún đậu gần đây"] // Keyword cho Google Maps
}
```

### 2\. User Collection (`/users`)

```json
{
  "uid": "user_123",
  "name": "Nguyễn Văn A",
  "allergies": ["tôm", "đậu phộng"],
  "preferences": {
    "spice_tolerance": 2,      // 0-5
    "budget_default": 1,       // Thường ăn rẻ
    "fav_cuisines": ["vn", "kr"]
  },
  "history": {                 // Dùng để Machine Learning sau này
    "last_eaten": ["pho_bo", "com_tam"],
    "rejected_tags": ["bun_mam"]
  }
}
```

### 3\. Copywriting Collection (`/configs/copywriting`)

  * Lưu các câu jokes theo key: `weather_hot`, `wallet_empty`, `mood_stress` để app lấy về hiển thị ngẫu nhiên.

-----

## V. USER FLOW & UI DESIGN

### 1\. Màn hình Onboarding (Thu thập Data gốc)

  * **Mục tiêu:** Nhanh, không làm User nản.
  * **Câu hỏi:**
    1.  Bạn có dị ứng gì không? (List tags: Hải sản, Đậu...)
    2.  Khả năng ăn cay? (Thanh trượt 0-5).
    3.  Mức chi tiêu thường ngày cho 1 bữa? (\<30k, 30-70k, \>100k).

### 2\. Màn hình Dashboard (Ngữ cảnh)

  * **Header:** Thay đổi background theo thời tiết thực tế.
      * *Text:* "Chào [Tên], Sài Gòn đang 36 độ, nóng chảy mỡ\! ☀️"
  * **Center Action:**
      * Widget lớn hoặc Slot Machine.
      * Text: "Bấm nút giải cứu cái bụng đói\!"
  * **Quick Select:** List "Món ruột" (Favorites).

### 3\. Màn hình Quick Input (BottomSheet)

  * Hiện lên khi bấm nút ở Dashboard. Dạng Icon to dễ chọn:
      * 💰 **Ví tiền:** [Cuối tháng] - [Bình dân] - [Sang chảnh]
      * 👥 **Đi cùng:** [1 Mình] - [Gấu] - [Đồng nghiệp]
      * 😐 **Tâm trạng:** [Vui] - [Buồn/Stress] - [Bình thường]
  * Button: **"CHỐT ĐƠN"**

### 4\. Màn hình Kết Quả (Result)

  * **Thẻ Món Ăn:** Hình ảnh hấp dẫn (Hero Animation).
  * **Tên Món:** To, rõ ràng.
  * **Lý Do:** "💡 *Gợi ý món này vì trời đang mưa và bạn cần món nước ấm.*"
  * **Câu Joke:** "Nhớ xin thêm trà đá nhé, món này hơi cay đấy\!"
  * **Primary Button:** **"TÌM QUÁN NGAY"** -\> Mở Google Maps với keyword tương ứng.
  * **Secondary Button:** **"Gợi ý khác"** (Re-roll).

-----

## VI. CHIẾN LƯỢC TRIỂN KHAI (TIMELINE & TIPS)

### Phase 1: The Core & Data (Tuần 1-2)

  * Dựng khung Flutter, Firebase Auth, Firestore.
  * **Quan trọng:** Tạo bộ dữ liệu 50 món ăn "quốc dân" (Cơm tấm, Phở, Bún bò, Bánh mì...).
  * Viết logic lọc món cơ bản.

### Phase 2: Context Awareness (Tuần 3)

  * Tích hợp API Thời tiết.
  * Xây dựng module "Scoring Engine" theo ngữ cảnh (Weather, Companion).
  * Thêm Input BottomSheet.

### Phase 3: Natural Feel & Polish (Tuần 4)

  * Viết bộ Copywriting (Jokes, Lời dẫn).
  * Tích hợp Deep Link (url\_launcher) sang Google Maps/Grab/ShopeeFood.
  * Hoàn thiện UI/UX, Animation.

### Lưu ý quan trọng:

  * **Về Map:** Không build map trong app (tốn tiền & công sức). Hãy dùng Deep Link để tận dụng review/location có sẵn của Google Maps.
  * **Về Data:** Tập trung chất lượng 50 món đầu tiên. Tag đầy đủ (cay, nóng, giá tiền) để thuật toán chạy chính xác.