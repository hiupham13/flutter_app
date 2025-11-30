Hiểu rồi. Bạn muốn một thiết kế **Production-Ready** (sẵn sàng chạy thực tế, có khả năng mở rộng, quản lý chặt chẽ), chứ không chỉ là bản MVP đơn giản.

Phiên bản trước là bản "tinh gọn" để chạy nhanh. Còn dưới đây là **Sơ đồ Cơ sở dữ liệu Hoàn chỉnh (Full Database Schema)** bao gồm cả quản lý Metadata (dữ liệu danh mục), Logs, Feedback, và Versioning để bạn không bị vỡ trận khi App có 10.000 users.

Chúng ta sẽ có **6 Collections chính** và các **Sub-collections**.

-----

### 🗺 TỔNG QUAN SƠ ĐỒ QUAN HỆ (LOGICAL MAP)

Tuy NoSQL không có "quan hệ" cứng như SQL, nhưng về logic chúng ta sẽ tổ chức như sau:

1.  **`master_data`**: Chứa các danh mục dùng chung (Loại món, Vùng miền, Dị ứng...).
2.  **`foods`**: Dữ liệu món ăn (Mapping với master\_data).
3.  **`users`**: Thông tin người dùng.
      * *Sub*: `favorites`, `blacklists`.
4.  **`activity_logs`**: Lịch sử hành vi (Tách riêng khỏi `users` để không làm nặng document user).
5.  **`feedback`**: Đánh giá/Report sai thông tin.
6.  **`app_configs`**: Cấu hình hệ thống động.

-----

### 📂 CHI TIẾT TỪNG COLLECTION

#### 1\. COLLECTION: `master_data` (Quản lý Danh mục)

*Mục đích:* Tránh hard-code trong App. Ví dụ sau này muốn thêm vị "Chua", chỉ cần thêm vào đây, App tự cập nhật dropdown.

  * **Doc ID:** `attributes`
    ```json
    {
      "cuisines": [
        {"id": "vn", "name": "Việt Nam", "icon": "🇻🇳"},
        {"id": "kr", "name": "Hàn Quốc", "icon": "🇰🇷"},
        {"id": "jp", "name": "Nhật Bản", "icon": "🇯🇵"}
      ],
      "meal_types": [
        {"id": "dry", "name": "Món khô"},
        {"id": "soup", "name": "Món nước"},
        {"id": "hotpot", "name": "Lẩu"},
        {"id": "snack", "name": "Ăn vặt"}
      ],
      "flavors": [
        {"id": "sour", "name": "Chua"},
        {"id": "spicy", "name": "Cay"},
        {"id": "sweet", "name": "Ngọt"},
        {"id": "salty", "name": "Mặn"}
      ],
      "allergens": [
        {"id": "seafood", "name": "Hải sản"},
        {"id": "peanut", "name": "Đậu phộng"},
        {"id": "dairy", "name": "Sữa"}
      ]
    }
    ```

#### 2\. COLLECTION: `foods` (Dữ liệu Core - Mở rộng)

*Mục đích:* Chứa đầy đủ thông tin để thuật toán chạy và hiển thị chi tiết.

  * **Doc ID:** `auto-generated` hoặc `slug-name` (vd: `pho-bo-ha-noi`)
    ```json
    {
      "id": "pho-bo-ha-noi",
      "name": "Phở Bò Tái",
      "search_keywords": ["phở bò", "noodle", "món nước", "ăn sáng"], // Array support search
      "description": "Nước dùng trong, bò tái mềm...",
      "images": [
        "url_anh_chinh.jpg",
        "url_anh_phu.jpg"
      ],
      
      // --- ATTRIBUTES (Dùng ID từ master_data) ---
      "cuisine_id": "vn",
      "meal_type_id": "soup",
      "flavor_profile": ["salty", "sweet_balance"],
      "allergen_tags": ["beef"], 

      // --- LOGIC GIÁ & THỜI GIAN ---
      "price_segment": 2, // 1:Cheap, 2:Mid, 3:High
      "avg_calories": 450,
      "available_times": ["morning", "dinner", "late_night"], // Không bán trưa
      
      // --- CONTEXT SCORING (Trọng số gợi ý) ---
      "context_scores": {
        "weather_hot": 0.5,   // Nóng ăn phở -> điểm thấp
        "weather_rain": 1.5,  // Mưa ăn phở -> điểm cao
        "mood_sick": 2.0,     // Ốm ăn phở -> điểm cực cao
        "companion_date": 0.8 // Hẹn hò ăn nước dễ bắn áo -> điểm thấp
      },

      // --- DEEP LINK DATA (Quan trọng cho Map) ---
      "map_query": "Phở bò ngon gần đây", // Key search Google Maps
      
      // --- SYSTEM META ---
      "is_active": true,       // Soft delete
      "created_at": Timestamp,
      "updated_at": Timestamp,
      "view_count": 1500,      // Để sort món phổ biến
      "pick_count": 300        // Số lần được user chọn
    }
    ```

#### 3\. COLLECTION: `users` (Hồ sơ người dùng)

*Mục đích:* Chỉ chứa thông tin Profile và Settings. Dữ liệu lịch sử nặng sẽ tách ra.

  * **Doc ID:** `uid` (Auth ID)
    ```json
    {
      "uid": "user_123",
      "info": {
        "display_name": "Tùng",
        "email": "tung@email.com",
        "avatar_url": "url..."
      },
      
      // --- SETTING CỨNG (Preferences) ---
      "settings": {
        "default_budget": 2,       // Thường ăn mức trung bình
        "spice_tolerance": 3,      // Ăn cay cấp 3
        "is_vegetarian": false,
        "blacklisted_foods": ["bun_mam"], // Ghét món này, không bao giờ hiện
        "excluded_allergens": ["peanut"]  // Dị ứng đậu phộng
      },

      // --- GAMIFICATION STATS ---
      "stats": {
        "streak_days": 5,          // Chuỗi 5 ngày dùng app liên tục
        "total_picked": 42
      },
      
      "fcm_token": "token_de_gui_thong_bao", // Push Notification
      "created_at": Timestamp,
      "last_login": Timestamp
    }
    ```

#### 4\. COLLECTION: `activity_logs` (Lịch sử & Training Data)

*Mục đích:* Lưu trữ từng lần user bấm "Gợi ý". Đây là **tài sản quý giá nhất** để làm AI sau này. Không lưu trong `users` vì nó sẽ phình to rất nhanh (MongoDB/Firestore limit 1MB/doc).

  * **Doc ID:** `auto-generated`
    ```json
    {
      "user_id": "user_123",
      "session_id": "session_abc", // Mã phiên làm việc
      "timestamp": Timestamp,
      
      // --- NGỮ CẢNH LÚC ĐÓ ---
      "context_snapshot": {
        "weather_temp": 36,
        "weather_condition": "sunny",
        "input_budget": 1,         // Lúc đó chọn "Ít tiền"
        "input_companion": "alone",// Lúc đó đi "Một mình"
        "input_mood": "stress"
      },
      
      // --- KẾT QUẢ GỢI Ý ---
      "recommended_foods": ["com_tam", "bun_thit_nuong", "banh_mi"],
      
      // --- HÀNH ĐỘNG CỦA USER ---
      "final_choice": "com_tam",   // User chốt món này
      "action_type": "click_map"   // User bấm nút tìm đường
    }
    ```

#### 5\. COLLECTION: `feedback` (Review & Report)

*Mục đích:* User báo cáo món ăn sai giá, quán đóng cửa, hoặc khen ngợi.

  * **Doc ID:** `auto-generated`
    ```json
    {
      "food_id": "pho-bo-ha-noi",
      "user_id": "user_123",
      "rating": 5, // 1-5 sao
      "tags": ["ngon", "dung_gia"],
      "comment": "Món này ăn mùa đông tuyệt vời",
      "created_at": Timestamp,
      "is_verified": false // Admin duyệt hay chưa
    }
    ```

#### 6\. COLLECTION: `app_configs` (Remote Config)

*Mục đích:* Điều khiển App từ xa mà không cần đẩy bản update lên Store.

  * **Doc ID:** `global_config`
    ```json
    {
      "maintenance": {
        "is_down": false,
        "message": "Server đang bảo trì 15 phút nhé!"
      },
      "features": {
        "enable_slot_machine": true, // Bật/tắt tính năng quay số
        "enable_ads": false
      },
      "algorithm_weights": { // Tinh chỉnh thuật toán không cần sửa code
        "weather_weight": 0.4,
        "mood_weight": 0.3,
        "history_weight": 0.3
      }
    }
    ```
  * **Doc ID:** `copywriting` (Chứa các câu jokes như đã bàn).

-----

### ⚡️ CHIẾN LƯỢC INDEXING (TỐI ƯU HIỆU NĂNG)

Firestore không tự động query nhiều trường cùng lúc nhanh được. Bạn cần tạo **Composite Indexes** trong Firebase Console cho các query phổ biến:

1.  **Lọc món ăn theo giá & loại:**
      * Fields: `price_segment` (Asc) + `cuisine_id` (Asc).
2.  **Lọc món theo thời gian:**
      * Fields: `available_times` (Array Contains) + `is_active` (Eq).
3.  **Lấy log của user theo thời gian:**
      * Fields: `user_id` (Asc) + `timestamp` (Desc).

-----

### 💡 TẠI SAO THIẾT KẾ NÀY TỐI ƯU?

1.  **Tách `master_data`:** Giúp App linh hoạt. Hôm nay có "Trà sữa", ngày mai trend "Trà mãng cầu" thì chỉ cần thêm vào DB, App tự hiện option chọn.
2.  **Tách `activity_logs`:** Giúp bảng `users` nhẹ. Logs có thể có hàng triệu dòng, nên để riêng để dễ query analtyics hoặc xóa bớt logs cũ (Data retention).
3.  **Metadata trong `foods`:** Lưu `pick_count`, `view_count` ngay trong món ăn giúp sort "Món Hot" cực nhanh mà không cần count lại từ bảng Logs.
4.  **Versioning:** `app_configs` giúp bạn quản lý feature flags. Nếu tính năng mới bị lỗi, bạn tắt nó từ xa (Remote Config) ngay lập tức.

Đây là cấu trúc Database đủ sức gánh cho App từ giai đoạn MVP đến khi có hàng chục nghìn User. Bạn hãy build theo schema này nhé\!