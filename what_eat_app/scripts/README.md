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

