# 🔍 Google Sign-In Troubleshooting Guide

## ✅ Đã sửa

1. ✅ Thêm `serverClientId` vào `GoogleSignIn`
2. ✅ Sửa `firebase_options.dart` để dùng appId của `com.wheateat.app`
3. ✅ Cải thiện error handling và logging

---

## 🔍 Checklist kiểm tra

### 1. OAuth Consent Screen - Test Users

**Vấn đề:** Ở Testing mode, chỉ email trong Test users mới đăng nhập được.

**Cách kiểm tra:**
1. Vào: https://console.cloud.google.com/apis/credentials/consent?project=futter-app-a0120
2. Scroll xuống phần "Test users"
3. Kiểm tra xem email của bạn có trong danh sách không

**Cách sửa:**
- Nếu chưa có, click "Add users"
- Thêm email chính xác (không có khoảng trắng)
- Đợi 2-5 phút để cập nhật

---

### 2. SHA-1 Fingerprint

**Vấn đề:** SHA-1 của release keystore chưa được thêm vào Firebase.

**Cách kiểm tra:**
1. Lấy SHA-1 của release keystore:
   ```bash
   keytool -list -v -keystore android/app/upload-keystore.jks -alias upload
   ```
2. Vào Firebase Console → Project Settings → Your apps → Android app (`com.wheateat.app`)
3. Kiểm tra SHA-1 fingerprints
4. So sánh với SHA-1 vừa lấy

**Cách sửa:**
- Nếu thiếu, thêm SHA-1 mới vào Firebase
- Tải lại `google-services.json`
- Thay thế file cũ trong `android/app/`

---

### 3. Firebase App ID

**Vấn đề:** Code đang dùng appId sai.

**Đã sửa:** ✅ `firebase_options.dart` đã dùng appId đúng: `651f269b460ab9ea71f2bb`

**Kiểm tra lại:**
- `firebase_options.dart` line 56: `appId: '1:55060102370:android:651f269b460ab9ea71f2bb'`
- `build.gradle.kts` line 29: `applicationId = "com.wheateat.app"`

---

### 4. Server Client ID

**Vấn đề:** `serverClientId` thiếu hoặc sai.

**Đã sửa:** ✅ Đã thêm `serverClientId` vào `GoogleSignIn`

**Kiểm tra lại:**
- `auth_repository.dart` line 20: `serverClientId: '55060102370-kv68udhnuvo0p4gjr2dt95paufck8iik.apps.googleusercontent.com'`
- Đây là Web client ID (client_type: 3) từ `google-services.json`

---

### 5. Rebuild App

**Vấn đề:** Code đã sửa nhưng app chưa được rebuild.

**Cách sửa:**
```bash
cd what_eat_app
flutter clean
flutter pub get
flutter build appbundle --release
```

Hoặc test với debug:
```bash
flutter run
```

---

### 6. Xem Log để Debug

**Sau khi rebuild, test lại và xem log:**

Log sẽ hiển thị:
- ✅ `🔵 [GoogleSignIn] Starting Google Sign-In process...`
- ✅ `✅ [GoogleSignIn] Google user obtained`
- ✅ `✅ [GoogleSignIn] Authentication tokens obtained`
- ✅ `✅ [GoogleSignIn] Firebase sign-in successful!`

Nếu có lỗi:
- ❌ `❌ [GoogleSignIn] idToken is NULL!` → serverClientId sai
- ❌ `❌ [GoogleSignIn] FirebaseAuthException` → Xem error code và message

**Các error code thường gặp:**
- `10` (DEVELOPER_ERROR) → SHA-1 không khớp
- `12500` (SIGN_IN_CANCELLED) → Email không có trong Test users
- `7` (NETWORK_ERROR) → Lỗi mạng hoặc Firebase chưa enable
- `8` (INTERNAL_ERROR) → Thiếu serverClientId hoặc cấu hình sai

---

## 🚀 Các bước tiếp theo

1. **Kiểm tra Test users** (quan trọng nhất)
2. **Kiểm tra SHA-1 fingerprint**
3. **Rebuild app** (`flutter clean` + `flutter build appbundle --release`)
4. **Test lại và xem log**
5. **Nếu vẫn lỗi, gửi log để debug**

---

## 📝 Lưu ý

- Sau khi thêm Test users, đợi 2-5 phút
- Sau khi thêm SHA-1, tải lại `google-services.json`
- Sau khi sửa code, phải rebuild app
- Xem log để biết lỗi cụ thể

---

## 🔗 Links hữu ích

- OAuth Consent Screen: https://console.cloud.google.com/apis/credentials/consent?project=futter-app-a0120
- Firebase Console: https://console.firebase.google.com/project/futter-app-a0120/settings/general
- Google Cloud Console: https://console.cloud.google.com/apis/credentials?project=futter-app-a0120

