# 🎯 Lộ Trình Tiếp Theo - Next Steps

Dựa trên tình trạng hiện tại của dự án, đây là lộ trình được đề xuất để đưa dự án từ "Logic đã có" đến "Có thể test end-to-end".

**Nguyên tắc:** Làm theo **Vertical Slice** - hoàn thiện từng feature để có thể test được ngay.

---

## 🚀 PHASE NGAY LẬP TỨC: "The Walking Skeleton" (Khung xương biết đi)

**Mục tiêu:** Có thể bấm nút → Nhập thông tin → Xem kết quả món ăn

**Thời gian ước tính:** 3-5 ngày

### ✅ Đã có sẵn:
- ✅ Scoring Engine (logic tính điểm)
- ✅ Recommendation Provider (state management)
- ✅ Food Repository (lấy data từ Firestore)
- ✅ Weather Service, Location Service
- ✅ 1 món ăn trong Firestore (đủ để test)

### 🔨 Cần làm ngay:

#### 1. Context Manager (1 ngày)
**File:** `lib/core/services/context_manager.dart`

Tổng hợp tất cả context (weather, time, location) thành một object duy nhất.

```dart
class ContextManager {
  Future<RecommendationContext> getCurrentContext({
    required int budget,
    required String companion,
    String? mood,
  }) async {
    // Lấy location
    // Lấy weather
    // Xác định time of day
    // Return RecommendationContext
  }
}
```

**Tại sao quan trọng:** Cần để kết nối UI với Logic.

---

#### 2. Dashboard Screen - Hoàn thiện (1 ngày)
**File:** `lib/features/dashboard/presentation/dashboard_screen.dart`

**Cần có:**
- Weather widget hiển thị nhiệt độ, điều kiện thời tiết
- Câu chào động theo context (ví dụ: "Nắng 35°C, nóng chảy mỡ!")
- Nút lớn "Gợi ý ngay" hoặc "Quay số"
- Loading state khi đang xử lý

**Tại sao quan trọng:** Đây là màn hình đầu tiên user thấy.

---

#### 3. Input Bottom Sheet (1 ngày)
**File:** `lib/features/recommendation/presentation/widgets/input_bottom_sheet.dart`

**Cần có:**
- 3 lựa chọn:
  - 💰 **Budget:** Cuối tháng (1) / Bình dân (2) / Sang chảnh (3)
  - 👥 **Companion:** Một mình / Hẹn hò / Nhóm bạn
  - 😐 **Mood:** (Optional) Vui / Bình thường / Stress / Ốm
- Nút "CHỐT ĐƠN" để trigger recommendation
- Animation slide up

**Tại sao quan trọng:** Thu thập input từ user để chạy thuật toán.

---

#### 4. Result Screen - Hoàn thiện (1 ngày)
**File:** `lib/features/recommendation/presentation/result_screen.dart`

**Cần có:**
- Hiển thị món ăn (tên, hình ảnh placeholder, mô tả)
- Lý do gợi ý ("Gợi ý vì trời đang mưa...")
- Câu joke (lấy từ copywriting)
- Nút "TÌM QUÁN NGAY" → Deep link Google Maps
- Nút "Gợi ý khác" → Re-roll

**Tại sao quan trọng:** Đây là kết quả cuối cùng, user cần thấy được.

---

#### 5. Copywriting Service (0.5 ngày)
**File:** `lib/core/services/copywriting_service.dart`

Lấy câu joke từ Firestore `app_configs/copywriting` hoặc fallback local.

**Tại sao quan trọng:** Làm app "có hồn", không khô khan.

---

#### 6. Kết nối tất cả lại (0.5 ngày)
- Dashboard → Bấm nút → Mở Input Bottom Sheet
- Input Bottom Sheet → Chốt đơn → Gọi Recommendation Provider
- Recommendation Provider → Trả kết quả → Navigate đến Result Screen
- Result Screen → Hiển thị món + Copywriting

---

## 📊 KẾT QUẢ SAU PHASE NÀY

Sau khi hoàn thành, bạn sẽ có:
- ✅ **End-to-end flow hoàn chỉnh:** Bấm nút → Nhập thông tin → Xem kết quả
- ✅ **Có thể test được:** Chạy app và thấy món "Phở Bò Tái" được gợi ý
- ✅ **Có thể demo được:** Show cho người khác xem app hoạt động

---

## 🎯 PHASE TIẾP THEO (Sau khi có Walking Skeleton)

### Option A: Bổ sung dữ liệu (Nếu muốn test với nhiều món)
- Thêm 10-20 món ăn vào Firestore
- Test thuật toán với nhiều scenarios

### Option B: Hoàn thiện UI/UX
- Thêm animations đẹp hơn
- Thêm error handling
- Thêm empty states

### Option C: Authentication (Nếu cần)
- Google Sign-In
- User Profile Management
- Onboarding Flow

---

## ⚠️ NHỮNG GÌ KHÔNG CẦN LÀM NGAY

- ❌ **Hive Cache:** Có thể làm sau, hiện tại Firestore đã đủ nhanh
- ❌ **Activity Logging:** Có thể làm sau khi có user thật
- ❌ **Favorites/History:** Tính năng nâng cao, làm sau
- ❌ **Search:** Tính năng nâng cao, làm sau
- ❌ **Authentication:** Có thể dùng guest mode hoặc hardcode user tạm thời

---

## 🎬 BẮT ĐẦU TỪ ĐÂU?

**Đề xuất thứ tự:**

1. **Context Manager** (dễ nhất, là foundation)
2. **Copywriting Service** (đơn giản, tách biệt)
3. **Input Bottom Sheet** (UI component độc lập)
4. **Result Screen** (hiển thị kết quả)
5. **Dashboard Screen** (kết nối tất cả lại)
6. **Test end-to-end** (verify mọi thứ hoạt động)

---

## 💡 TIPS

1. **Làm từng bước nhỏ:** Mỗi file một lúc, test ngay sau khi xong
2. **Dùng placeholder data:** Không cần đợi có đủ dữ liệu, dùng 1 món hiện có
3. **Focus vào flow chính:** Bỏ qua edge cases, làm sau
4. **Test thường xuyên:** Chạy app sau mỗi thay đổi lớn

---


