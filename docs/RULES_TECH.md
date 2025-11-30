Đây là file `RULES_TECH.md` tóm tắt toàn bộ các phiên bản và cấu hình "xương máu" mà bạn vừa trải qua. Bạn hãy copy nội dung này vào dự án để làm kim chỉ nam cho cả team (Hiếu & Minh), đảm bảo sau này không ai tự ý nâng cấp gây lỗi.

-----

### 📄 File: `RULES_TECH.md`

````markdown
# 🛡️ RULES TECH & VERSION CONTROL
> Tài liệu quy định phiên bản thư viện và cấu hình Build để tránh xung đột (Conflict) cho dự án "Hôm Nay Ăn Gì".

---

## 1. 🧱 CORE ENVIRONMENT (Môi trường lõi)
Bắt buộc cài đặt đúng các phiên bản sau để build được App:

| Công nghệ | Phiên bản (Version) | Ghi chú |
| :--- | :--- | :--- |
| **Flutter SDK** | Stable (Latest) | Hiện tại đang dùng bản 3.x trở lên. |
| **Java (JDK)** | **17** | Cấu hình trong Gradle là `JavaVersion.VERSION_17`. |
| **Kotlin** | Latest | Gradle Plugin tự quản lý. |
| **Android NDK** | Auto | **KHÔNG** tải thủ công. Để Gradle tự tải khi build lỗi. |
| **Windows Mode**| **Developer Mode** | Bắt buộc bật (Settings -> Update -> Developer Mode) để hỗ trợ Symlink. |

---

## 2. 📦 LIBRARY VERSIONS (Phiên bản thư viện)
Hiện tại dự án đang chạy ổn định với các version sau. **TUYỆT ĐỐI KHÔNG** chạy `flutter pub upgrade --major-versions` nếu không có sự đồng ý của cả team.

### 🔴 DANGER ZONE (Cấm tự ý nâng cấp)
Các thư viện này đang có bản mới (Major Update) nhưng gây lỗi cấu trúc (Breaking Changes). Giữ nguyên bản hiện tại:

* **flutter_riverpod**: `^2.6.1` (Không lên v3.0.x)
* **go_router**: `^14.8.1` (Không lên v17.0.x)
* **firebase_core**: `^3.15.2` (Không lên v4.x)
* **cloud_firestore**: `^5.6.12` (Không lên v6.x)
* **firebase_auth**: `^5.7.0` (Không lên v6.x)

*(Lý do: Các bản mới yêu cầu migrate code rất nhiều, hiện tại ưu tiên dev tính năng trước).*

---

## 3. 🤖 ANDROID BUILD RULES (Quan trọng)

File `android/app/build.gradle.kts` phải tuân thủ nghiêm ngặt cấu trúc dưới đây để tránh lỗi: `Inconsistent JVM Target` và lỗi `Lint`.

### 3.1. Java & Kotlin Version Sync (Bắt buộc)
Phải ép buộc cả Java và Kotlin cùng dùng version **17**.

```kotlin
// Trong block android { ... }
compileOptions {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
}

// Ở CUỐI CÙNG file (Ngoài block android) - Fix lỗi Kotlin 21 vs Java 17
tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}
````

### 3.2. Lint Options (Để build Release)

Bắt buộc tắt check Lint để không bị chặn khi build file `.aab`.

```kotlin
// Trong block android { ... }
lint {
    checkReleaseBuilds = false
    abortOnError = false
}
```

### 3.3. Signing Config (Key thật)

Sử dụng file `key.properties` (không commit lên Git) để đọc cấu hình.

```kotlin
// Chỉ dùng signingConfig cho bản release
buildTypes {
    getByName("release") {
        signingConfig = signingConfigs.getByName("release")
        isMinifyEnabled = false // Giữ false để tránh lỗi mất file R8
        isShrinkResources = false
    }
}
```

-----

## 4\. 🚀 DEPLOYMENT FLOW (Quy trình đóng gói)

Khi muốn build bản mới để test hoặc nộp Store:

1.  **Tăng version:** Mở `pubspec.yaml`, sửa dòng `version: 1.0.0+1` lên `+2`, `+3`...
2.  **Clean rác:** Chạy `flutter clean` && `flutter pub get`.
3.  **Build lệnh:**
      * Cho CH Play: `flutter build appbundle --release`
      * Cho cài thử máy bạn bè: `flutter build apk --release`

-----

## 5\. ⚠️ TROUBLESHOOTING (Sửa lỗi nhanh)

  * **Lỗi `NDK not found/corrupted`:** Vào folder NDK trên máy, xóa folder phiên bản lỗi đi -\> Chạy lại lệnh build để nó tự tải.
  * **Lỗi `Symlink`:** Bật Developer Mode trên Windows lên.
  * **Lỗi `Different roots`:** Đảm bảo Project nằm cùng ổ đĩa với Flutter SDK (Khuyên dùng ổ **C:**).

<!-- end list -->

```

---