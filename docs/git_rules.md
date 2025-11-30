Đây là file `rules_git.md` đầy đủ, bao gồm cả bước khôi phục nhánh main và quy trình làm việc hàng ngày. Bạn hãy tạo file này trong thư mục gốc dự án để cả 2 cùng đọc nhé.

````markdown
# 🐙 QUY TRÌNH LÀM VIỆC VỚI GIT (Team 2 Người)

Tài liệu này quy định cách quản lý source code cho dự án, đảm bảo Hiếu và Minh không bị ghi đè code của nhau và luôn có một phiên bản ổn định.

---

## 🚨 PHẦN 1: KHÔI PHỤC NHÁNH MAIN (Chỉ làm 1 lần đầu)

Do hiện tại nhánh `main` bị mất hoặc bị đổi tên, cần thực hiện lệnh sau trên máy của người đang giữ code mới nhất (Hiếu hoặc Minh) để tạo lại.

Mở Terminal tại thư mục dự án:

```bash
# 1. Chuyển sang nhánh đang có code đầy đủ (ví dụ hiupham)
git checkout hiupham

# 2. Tạo nhánh main từ nhánh này
git checkout -b main

# 3. Đẩy nhánh main lên GitHub
git push -u origin main
````

**⚠️ Cài đặt trên GitHub:**

1.  Vào Repo trên Web -\> **Settings** -\> **General**.
2.  Mục **Default branch** -\> Đổi thành **`main`**.
3.  Bấm **Update**.

-----

## 🌲 PHẦN 2: CẤU TRÚC NHÁNH (BRANCHING MODEL)

Chúng ta có 3 nhánh chính:

| Tên nhánh | Nhiệm vụ | Ai được sửa? |
| :--- | :--- | :--- |
| **`main`** | Chứa code CHÍNH THỨC, chạy ổn định. | 🚫 **KHÔNG** push trực tiếp. Chỉ được Merge vào. |
| **`hiupham`** | Nhánh làm việc riêng của Hiếu. | ✅ Hiếu code và push thoải mái. |
| **`duyminh`** | Nhánh làm việc riêng của Minh. | ✅ Minh code và push thoải mái. |

-----

## 🛠 PHẦN 3: QUY TRÌNH CODE HÀNG NGÀY

### Bước 1: Bắt đầu ngày làm việc (Cập nhật code mới)

Trước khi viết bất kỳ dòng code nào, phải đảm bảo nhánh của mình đã có code mới nhất của người kia (đang nằm ở `main`).

```bash
# 1. Về nhánh của mình (Ví dụ Minh)
git checkout duyminh

# 2. Kéo code mới nhất từ MAIN về nhánh của mình
git pull origin main
```

*Nếu có Conflict (Xung đột):* Mở VS Code, chọn "Accept Current" hoặc "Accept Incoming" để sửa, sau đó `git add .` và `git commit`.

### Bước 2: Code và Commit

Sau khi code xong một tính năng (ví dụ: Login, UI Dashboard...):

```bash
# 1. Kiểm tra file thay đổi
git status

# 2. Lưu thay đổi
git add .
git commit -m "Mô tả ngắn gọn chức năng vừa làm"
```

### Bước 3: Đẩy code lên GitHub

Đẩy code lên nhánh riêng của mình (tuyệt đối không push thẳng vào main).

```bash
git push origin duyminh
# Hoặc: git push origin hiupham
```

-----

## 🔀 PHẦN 4: MERGE CODE VÀO MAIN (GỘP CODE)

Khi đã hoàn thành tính năng và test chạy ngon lành trên nhánh riêng.

1.  Truy cập trang GitHub của dự án.
2.  Vào tab **Pull requests** -\> Bấm **New pull request**.
3.  Chọn hướng merge:
      * **Base:** `main` ⬅️ **Compare:** `duyminh` (hoặc `hiupham`).
4.  Viết tiêu đề: "Merge tính năng Login vào Main".
5.  Bấm **Create pull request**.
6.  Nhắn người kia vào review (nếu cần), hoặc tự bấm **Merge pull request** -\> **Confirm merge**.

-----

## 📝 CHEAT SHEET (CÁC LỆNH HAY DÙNG)

| Hành động | Lệnh Git |
| :--- | :--- |
| Kiểm tra đang ở nhánh nào | `git branch` |
| Chuyển nhánh | `git checkout <ten_nhanh>` |
| Tạo nhánh mới | `git checkout -b <ten_nhanh_moi>` |
| Xem trạng thái file | `git status` |
| Hủy các file đã sửa (khi chưa commit) | `git checkout .` |
| Xem lịch sử commit | `git log` |

-----

**🔥 QUY TẮC VÀNG:**

1.  Code ai người nấy lo trên nhánh riêng.
2.  Muốn gộp code -\> Tạo **Pull Request**.
3.  Trước khi code -\> Luôn **`git pull origin main`**.

<!-- end list -->

```
```