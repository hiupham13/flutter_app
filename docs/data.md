# 📊 Dữ Liệu Firestore Hiện Tại

Tài liệu này mô tả cấu trúc và nội dung dữ liệu thực tế đang có trong Firestore của dự án "Hôm Nay Ăn Gì?".

**Cập nhật lần cuối:** Dựa trên dump từ Firestore Data Dumper

---

## 📋 1. MASTER DATA (`master_data/attributes`)

Dữ liệu danh mục dùng chung cho toàn bộ ứng dụng.

### 🍜 Cuisines (Vùng miền)
- **vn** - Việt Nam (icon: VN)
- **kr** - Hàn Quốc (icon: KR)

### 🍽️ Meal Types (Loại món)
- **soup** - Món nước
- **dry** - Món khô

### 🌶️ Flavors (Vị)
- **sour** - Chua
- **spicy** - Cay

### ⚠️ Allergens (Dị ứng)
- **seafood** - Hải sản

---

## 🍔 2. FOODS COLLECTION

**Tổng số món ăn:** 1 món

### Món ăn #1: Phở Bò Tái
- **Document ID:** `pho-bo-ha-noi`
- **Tên:** Phở Bò Tái
- **Mô tả:** Nước dùng trong, bò tái mềm...
- **Giá:** Segment 2 (Trung bình: 35k-80k)
- **Vùng miền:** vn (Việt Nam)
- **Loại món:** soup (Món nước)
- **Thời gian bán:** morning, dinner, late_night
- **Từ khóa tìm kiếm:** ["Phở bò", "noodle", "ăn sáng"]
- **Map Query:** "Phở bò ngon gần đây"
- **Hình ảnh:** ["https://link_anh_1.jpg"]

#### Context Scores (Điểm ngữ cảnh)
- `weather_hot`: 0.5 (Trời nóng → điểm thấp)
- `weather_rain`: 1.5 (Trời mưa → điểm cao)
- `mood_sick`: 2.0 (Ốm → điểm rất cao)

---

## 👤 3. USERS COLLECTION

**Tổng số users:** 1 user

### User #1: Developer Test
- **Document ID (UID):** `user_test_01`
- **Email:** dev@test.com
- **Tên:** Developer

#### Settings (Cài đặt)
- **Default Budget:** 2 (Trung bình)
- **Spice Tolerance:** 3 (Ăn cay cấp độ 3)
- **Blacklisted Foods:** ["bun_mam"] (Ghét món bún mắm)

---

## ⚙️ 4. APP CONFIGS COLLECTION

### Document: `global_config`
Cấu hình hệ thống toàn cục.

```json
{
  "maintenance": {
    "is_down": false,
    "message": "Server đang bảo trì"
  },
  "features": {
    "enable_slot_machine": true
  }
}
```

### Document: `copywriting`
Các câu joke và copywriting theo ngữ cảnh.

#### Weather Hot (Trời nóng)
- "Trời nóng thế này chỉ có ăn kem!"
- "Nóng chảy mỡ, đừng ăn lẩu nhé!"

#### Mood Stress (Tâm trạng stress)
- "Làm ly trà sữa full topping cho đời bớt khổ!"
- "Cay cấp độ 7 để quên sầu đi!"

---

## 📝 GHI CHÚ

### Dữ liệu còn thiếu/Chưa có:
- ❌ Collection `activity_logs` - Chưa có dữ liệu
- ❌ Collection `feedback` - Chưa có dữ liệu
- ⚠️ Foods collection chỉ có 1 món (cần thêm ít nhất 50-100 món cho MVP)
- ⚠️ Master Data còn thiếu nhiều options (ví dụ: meal_types thiếu "hotpot", "snack")

### Cấu trúc dữ liệu khớp với schema:
✅ Foods model khớp với `database.md`  
✅ Users model khớp với `database.md`  
✅ Master Data structure đúng  
✅ App Configs có đủ `global_config` và `copywriting`

---

## 🔄 HƯỚNG DẪN CẬP NHẬT

Khi có thay đổi dữ liệu trong Firestore:
1. Chạy app và nhấn nút "📋 Dump Firestore Data" trên Dashboard
2. Copy toàn bộ output từ Console
3. Cập nhật file `data.md` này với dữ liệu mới

