# Scripts Directory

Các script Node.js hỗ trợ import và upload dữ liệu cho ứng dụng What Eat.

## Scripts

1. **upload-to-cloudinary.js** - Upload ảnh lên Cloudinary
2. **import-to-firestore.js** - Import dữ liệu món ăn vào Firestore

---

# Cloudinary Batch Upload Script

Script Node.js để upload nhiều file ảnh lên Cloudinary cùng lúc với Public ID được chỉ định tự động.

## Cài Đặt

### Bước 1: Cài đặt Node.js

Đảm bảo đã cài đặt Node.js (version 14 trở lên):
- Download: https://nodejs.org/
- Kiểm tra: `node --version`

### Bước 2: Cài đặt Dependencies

```bash
cd scripts
npm install
```

## Cấu Hình Cloudinary API

### Cách 1: Sử Dụng File .env (Khuyến Nghị) ⭐

1. **Tạo file `.env` trong folder `scripts`**:

```env
CLOUDINARY_CLOUD_NAME=dinrpqxne
CLOUDINARY_API_KEY=your_api_key_here
CLOUDINARY_API_SECRET=your_api_secret_here
```

2. **Script sẽ tự động đọc file `.env`** khi chạy

⚠️ **Lưu ý**: File `.env` đã được thêm vào `.gitignore`, không lo bị commit lên Git.

### Cách 2: Environment Variables (Terminal)

Export trực tiếp trong terminal:

**Windows (PowerShell):**
```powershell
$env:CLOUDINARY_CLOUD_NAME="dinrpqxne"
$env:CLOUDINARY_API_KEY="your_api_key"
$env:CLOUDINARY_API_SECRET="your_api_secret"
```

**Linux/Mac:**
```bash
export CLOUDINARY_CLOUD_NAME=dinrpqxne
export CLOUDINARY_API_KEY=your_api_key
export CLOUDINARY_API_SECRET=your_api_secret
```

### Cách 3: Sửa Trực Tiếp Trong Script

Mở file `upload-to-cloudinary.js` và sửa:

```javascript
cloudinary.config({
  cloud_name: 'dinrpqxne',
  api_key: 'your_api_key_here',
  api_secret: 'your_api_secret_here',
});
```

### Lấy API Credentials

1. Đăng nhập Cloudinary Dashboard: https://cloudinary.com/console
2. Vào **Settings** → **Security**
3. Copy **API Key** và **API Secret**

⚠️ **Lưu ý**: Không commit API credentials vào Git!

## Sử Dụng

### Cú Pháp Cơ Bản

```bash
node upload-to-cloudinary.js <folder-path> [options]
```

### Ví Dụ

#### Upload tất cả ảnh trong folder `./images`:

```bash
node upload-to-cloudinary.js ./images
```

#### Upload với folder tùy chỉnh:

```bash
node upload-to-cloudinary.js ./images --folder foods
```

#### Upload với overwrite (ghi đè file đã tồn tại):

```bash
node upload-to-cloudinary.js ./images --folder foods --overwrite
```

#### Xem hướng dẫn:

```bash
node upload-to-cloudinary.js --help
```

## Vị Trí Đặt Folder Images

Folder chứa ảnh có thể đặt ở **bất kỳ đâu**, không nhất thiết phải trong folder `scripts`.

### Các Vị Trí Có Thể Đặt:

1. **Trong folder `scripts`** (dễ quản lý):
   ```
   scripts/
   ├── upload-to-cloudinary.js
   ├── package.json
   └── images/
       ├── pho-bo.jpg
       ├── banh-mi.jpg
       └── ...
   ```
   Chạy: `node upload-to-cloudinary.js ./images`

2. **Trong root project**:
   ```
   what_eat_app/
   ├── scripts/
   │   └── upload-to-cloudinary.js
   └── images/
       ├── pho-bo.jpg
       └── ...
   ```
   Chạy: `node scripts/upload-to-cloudinary.js ../images`

3. **Ở bất kỳ đâu trên máy**:
   ```
   C:\Users\YourName\Pictures\food-images\
   ```
   Chạy: `node upload-to-cloudinary.js "C:\Users\YourName\Pictures\food-images"`

### Lưu Ý:

- **Đường dẫn tương đối**: Dùng `./images` hoặc `../images` (từ vị trí chạy script)
- **Đường dẫn tuyệt đối**: Dùng full path như `C:\path\to\images` hoặc `/home/user/images`
- **Tên folder**: Có thể đặt tên bất kỳ, không nhất thiết là `images`

## Cách Hoạt Động

1. **Đọc tất cả file ảnh** trong folder được chỉ định
2. **Tự động tạo Public ID** từ tên file (bỏ extension):
   - `pho-bo.jpg` → Public ID: `pho-bo`
   - `banh-mi.png` → Public ID: `banh-mi`
3. **Upload lên Cloudinary** với Public ID được chỉ định
4. **Hiển thị kết quả** (thành công/thất bại)

## Format Tên File

- Tên file phải khớp với `food.id` (sau khi normalize)
- Extension: `.jpg`, `.jpeg`, `.png`, `.webp`
- Ví dụ:
  - `pho-bo.jpg` → Public ID: `pho-bo`
  - `banh-mi.png` → Public ID: `banh-mi`

## Output

Script sẽ hiển thị:
- Danh sách file tìm thấy
- Tiến trình upload
- Kết quả (thành công/thất bại)
- Public ID và URL của mỗi file

## Troubleshooting

### Lỗi: "Chưa cấu hình Cloudinary API credentials"

→ Kiểm tra đã set environment variables hoặc sửa trong script chưa

### Lỗi: "Folder không tồn tại"

→ Kiểm tra đường dẫn folder có đúng không

### Lỗi: "File already exists"

→ Thêm option `--overwrite` để ghi đè file đã tồn tại

### File upload nhưng Public ID có suffix

→ Đảm bảo Public ID được chỉ định rõ ràng (script tự động làm điều này)

## Ví Dụ Hoàn Chỉnh

### Ví Dụ 1: Folder Images Trong Scripts (Khuyến Nghị)

1. **Tạo folder `images` trong `scripts`**:
   ```bash
   cd scripts
   mkdir images
   # Copy các file ảnh vào folder images
   ```

2. **Cấu trúc**:
   ```
   scripts/
   ├── upload-to-cloudinary.js
   ├── package.json
   └── images/
       ├── pho-bo.jpg
       ├── banh-mi.jpg
       ├── bun-cha.jpg
       └── tra-sua-tran-chau.jpg
   ```

3. **Set environment variables**:
   ```bash
   export CLOUDINARY_API_KEY=your_key
   export CLOUDINARY_API_SECRET=your_secret
   ```

4. **Chạy script** (từ folder `scripts`):
   ```bash
   node upload-to-cloudinary.js ./images --folder foods --overwrite
   ```

### Ví Dụ 2: Folder Images Ở Root Project

1. **Tạo folder `images` ở root**:
   ```bash
   # Từ root project
   mkdir images
   # Copy các file ảnh vào folder images
   ```

2. **Cấu trúc**:
   ```
   what_eat_app/
   ├── scripts/
   │   ├── upload-to-cloudinary.js
   │   └── package.json
   └── images/
       ├── pho-bo.jpg
       └── ...
   ```

3. **Chạy script** (từ folder `scripts`):
   ```bash
   cd scripts
   node upload-to-cloudinary.js ../images --folder foods --overwrite
   ```

### Ví Dụ 3: Folder Images Ở Vị Trí Khác

1. **Tạo folder ở bất kỳ đâu** (ví dụ: Desktop):
   ```
   C:\Users\YourName\Desktop\food-images\
   ```

2. **Chạy script** với đường dẫn tuyệt đối:
   ```bash
   cd scripts
   node upload-to-cloudinary.js "C:\Users\YourName\Desktop\food-images" --folder foods
   ```

### Kết quả:

```
🚀 Bắt đầu upload ảnh lên Cloudinary...

📁 Folder: ./images
📂 Cloudinary folder: foods
🔄 Overwrite: Có
☁️  Cloud name: dinrpqxne

📸 Tìm thấy 4 file ảnh:

  1. pho-bo.jpg → Public ID: pho-bo
  2. banh-mi.jpg → Public ID: banh-mi
  3. bun-cha.jpg → Public ID: bun-cha
  4. tra-sua-tran-chau.jpg → Public ID: tra-sua-tran-chau

⏳ Đang upload...

[1/4] Uploading pho-bo.jpg... ✅
[2/4] Uploading banh-mi.jpg... ✅
[3/4] Uploading bun-cha.jpg... ✅
[4/4] Uploading tra-sua-tran-chau.jpg... ✅

==================================================
📊 Kết quả:

✅ Thành công: 4
❌ Thất bại: 0

✅ Files đã upload thành công:
  - pho-bo.jpg
    Public ID: foods/pho-bo
    URL: https://res.cloudinary.com/dinrpqxne/image/upload/v1234567890/foods/pho-bo.jpg

  ...

==================================================
✨ Hoàn thành!
```

---

# Firestore Import Script

Script Node.js để import dữ liệu món ăn từ JSON file vào Firestore collection `foods`.

## Cấu Hình Firebase

### Cách 1: Sử Dụng Service Account JSON File (Khuyến Nghị) ⭐

**Bước 1: Tải Service Account Key từ Firebase Console**

1. Đăng nhập [Firebase Console](https://console.firebase.google.com/)
2. Chọn project của bạn
3. Click vào **⚙️ Settings** (bánh răng) ở góc trên bên trái
4. Chọn **Project settings**
5. Vào tab **Service accounts**
6. Click nút **Generate new private key**
7. Xác nhận trong popup (cảnh báo về bảo mật)
8. File JSON sẽ được tải xuống tự động (tên file thường là `your-project-name-firebase-adminsdk-xxxxx-xxxxxxxxxx.json`)

**Bước 2: Di chuyển file JSON vào folder `scripts`**

- Copy file JSON vừa tải về vào folder `scripts/`
- Đổi tên cho dễ nhớ (ví dụ: `serviceAccountKey.json`)

**Bước 3: Tạo file `.env` trong folder `scripts`**

Tạo file `.env` với nội dung:

```env
FIREBASE_SERVICE_ACCOUNT=./serviceAccountKey.json
```

⚠️ **Lưu ý**: Thay `serviceAccountKey.json` bằng tên file thực tế của bạn.

### Cách 2: Sử Dụng Environment Variables

Nếu bạn muốn dùng environment variables thay vì file JSON, bạn cần lấy các giá trị từ Service Account JSON file:

**Bước 1: Mở Service Account JSON file** (đã tải ở Cách 1)

File JSON có dạng:
```json
{
  "type": "service_account",
  "project_id": "your-project-id",
  "private_key_id": "...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com",
  ...
}
```

**Bước 2: Lấy các giá trị cần thiết**

- `FIREBASE_PROJECT_ID` = giá trị của `project_id` trong JSON
- `FIREBASE_CLIENT_EMAIL` = giá trị của `client_email` trong JSON
- `FIREBASE_PRIVATE_KEY` = giá trị của `private_key` trong JSON (giữ nguyên cả `\n`)

**Bước 3: Tạo file `.env` trong folder `scripts`**

```env
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...\n-----END PRIVATE KEY-----\n"
```

⚠️ **Lưu ý quan trọng**: 
- File `.env` đã được thêm vào `.gitignore`, không lo bị commit lên Git
- Với `FIREBASE_PRIVATE_KEY`, cần:
  - Giữ nguyên format với `\n` (sẽ được convert thành newline tự động)
  - Đặt trong dấu ngoặc kép `"..."` 
  - Copy toàn bộ private key từ JSON (từ `-----BEGIN PRIVATE KEY-----` đến `-----END PRIVATE KEY-----\n`)

**Ví dụ đầy đủ:**

Nếu trong JSON file bạn có:
```json
{
  "project_id": "what-eat-app-12345",
  "client_email": "firebase-adminsdk-abcde@what-eat-app-12345.iam.gserviceaccount.com",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...\n-----END PRIVATE KEY-----\n"
}
```

Thì trong `.env` bạn viết:
```env
FIREBASE_PROJECT_ID=what-eat-app-12345
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-abcde@what-eat-app-12345.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...\n-----END PRIVATE KEY-----\n"
```

### Khuyến Nghị

**Nên dùng Cách 1** (Service Account JSON file) vì:
- ✅ Dễ setup hơn (chỉ cần 1 dòng trong `.env`)
- ✅ Ít lỗi hơn (không cần copy/paste private key)
- ✅ An toàn hơn (file JSON có thể được bảo vệ tốt hơn)

## Sử Dụng

### Cú Pháp Cơ Bản

```bash
node import-to-firestore.js [options]
```

### Ví Dụ

#### Import với file mặc định (`foods (1).json`):

```bash
node import-to-firestore.js
```

#### Import với file tùy chỉnh:

```bash
node import-to-firestore.js --file custom-foods.json
```

#### Dry run (preview, không upload thật):

```bash
node import-to-firestore.js --dry-run
```

#### Xem hướng dẫn:

```bash
node import-to-firestore.js --help
```

## Format JSON File

File JSON phải là array của các food objects:

```json
[
  {
    "id": "chao-yen-mach-ca-hoi",
    "name": "Cháo Yến Mạch Cá Hồi",
    "description": "Cháo mềm, giàu omega-3 tốt cho tim mạch",
    "images": ["https://placeholder.com/chaoyenmach.jpg"],
    "price_segment": 2,
    "cuisine_id": "vn",
    "meal_type_id": "soup",
    "flavor_profile": ["light"],
    "available_times": ["morning"],
    "is_active": true,
    "context_scores": { "elderly": 2.0, "hypertension": 2.0 },
    "map_query": "Cháo yến mạch cá hồi",
    "search_keywords": ["cháo yến mạch"]  // optional
  }
]
```

### Required Fields:
- `id` - Document ID (unique)
- `name` - Tên món ăn
- `cuisine_id` - ID của cuisine
- `meal_type_id` - ID của meal type
- `price_segment` - 1-4 (1: Cheap, 2: Mid, 3: High, 4: Premium)

### Optional Fields:
- `search_keywords` - Array of strings (default: [])
- `description` - Mô tả (default: '')
- `images` - Array of image URLs (default: [])
- `allergen_tags` - Array of allergen tags (default: [])
- `avg_calories` - Số calories (default: null)
- `context_scores` - Object với context scores (default: {})

## Cách Hoạt Động

1. **Đọc và validate** JSON file
2. **Map fields** từ JSON sang Firestore format
3. **Check document existence** - tự động skip nếu đã tồn tại
4. **Upload** documents mới vào collection `foods`
5. **Hiển thị summary** (success, skipped, failed)

## Output

Script sẽ hiển thị:
- Số lượng món ăn được đọc
- Tiến trình upload (với progress bar)
- Kết quả chi tiết:
  - ✅ Thành công: Documents đã upload
  - ⏭️ Đã bỏ qua: Documents đã tồn tại (auto-skip)
  - ❌ Thất bại: Documents có lỗi

### Ví Dụ Output:

```
🚀 Bắt đầu import dữ liệu vào Firestore...

✅ Firebase initialized from service account file
✅ Đọc thành công 2078 món ăn từ file: foods (1).json
📊 Tổng số món ăn: 2078
📂 Collection: foods
🔄 Mode: LIVE (will upload)

⏳ Đang validate và map dữ liệu...

✅ 2078 món ăn hợp lệ

⏳ Đang upload...

[1/2078] chao-yen-mach-ca-hoi... ✅
[2/2078] canh-rau-den-tom... ✅
[3/2078] ca-hap-sa... ⏭️  (skipped)
...

============================================================
📊 Kết quả:

✅ Thành công: 2050
⏭️  Đã bỏ qua (đã tồn tại): 28
❌ Thất bại: 0

✅ Documents đã upload thành công:
  - chao-yen-mach-ca-hoi
  - canh-rau-den-tom
  ... và 2048 documents khác

⏭️  Documents đã bỏ qua (đã tồn tại):
  - ca-hap-sa
  ... và 27 documents khác

============================================================

✨ Hoàn thành!
```

## Troubleshooting

### Lỗi: "Firebase credentials not found"

→ Kiểm tra đã set environment variables trong `.env` hoặc service account file chưa

### Lỗi: "File không tồn tại"

→ Kiểm tra đường dẫn file JSON có đúng không

### Lỗi: "Missing required fields"

→ Kiểm tra JSON file có đầy đủ các required fields (id, name, cuisine_id, meal_type_id, price_segment)

### Lỗi: "Invalid price_segment"

→ `price_segment` phải là số từ 1-4

## Notes

- Script tự động **skip documents đã tồn tại** (check by document ID)
- Sử dụng **batch writes** để tối ưu performance
- **Validation** được thực hiện trước khi upload
- **Error handling** cho từng document - nếu một document fail, các document khác vẫn tiếp tục

