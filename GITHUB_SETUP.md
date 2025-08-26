# 🚀 Hướng dẫn Push Code lên GitHub

## 📋 **Các bước thực hiện:**

### **1. Tạo Repository trên GitHub**

1. **Truy cập**: [github.com](https://github.com)
2. **Đăng nhập** vào tài khoản GitHub
3. **Tạo repository mới**:
   - Click **"New"** hoặc **"+"** → **"New repository"**
   - **Repository name**: `onvif-flutter`
   - **Description**: `A comprehensive Flutter library for ONVIF camera integration with streaming, PTZ control, recording, and user management`
   - **Visibility**: Public hoặc Private (tùy bạn)
   - **KHÔNG** check "Add a README file"
   - **KHÔNG** check "Add .gitignore"
   - Click **"Create repository"**

### **2. Push Code lên GitHub**

Sau khi tạo repository, chạy lệnh sau trong terminal:

```bash
# Thay thế <your-github-username> bằng username GitHub của bạn
./push_to_github.sh <your-github-username>
```

**Ví dụ:**
```bash
./push_to_github.sh nghinguyen
```

### **3. Cấu hình Repository (Sau khi push)**

1. **Thêm Topics**: Vào repository → Settings → General → Topics
   - `flutter`
   - `dart`
   - `onvif`
   - `camera`
   - `streaming`
   - `ptz`
   - `surveillance`
   - `ip-camera`
   - `rtsp`
   - `soap`

2. **Thêm Description chi tiết**:
   ```
   🎥 ONVIF Flutter Library
   
   A comprehensive Flutter library for ONVIF camera integration with:
   • Live streaming and playback
   • PTZ camera control
   • Recording search and management
   • User/Group management
   • Multi-channel DVR support
   • Time-based playback
   • Complete Flutter UI example
   
   Built with Dio HTTP client, SOAP/XML communication, and WS-Security authentication.
   ```

3. **Tạo Release** (tùy chọn):
   - Vào **Releases** → **"Create a new release"**
   - **Tag version**: `v1.0.0`
   - **Release title**: `🎉 Initial Release - ONVIF Flutter Library`
   - **Description**: Copy nội dung từ commit message

### **4. Cấu hình GitHub Pages (Tùy chọn)**

Nếu muốn tạo documentation site:
1. Vào **Settings** → **Pages**
2. **Source**: Deploy from a branch
3. **Branch**: `main` → `/docs`
4. **Save**

### **5. Thêm Badges vào README**

Thêm các badges sau vào đầu file `README.md`:

```markdown
[![Flutter](https://img.shields.io/badge/Flutter-3.16+-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![ONVIF](https://img.shields.io/badge/ONVIF-Compliant-orange.svg)](https://www.onvif.org)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20macOS-lightgrey.svg)](https://flutter.dev/docs/deployment)

# 🎥 ONVIF Flutter Library
```

## 🔧 **Troubleshooting**

### **Lỗi Authentication**
```bash
# Nếu gặp lỗi authentication, sử dụng Personal Access Token
git remote set-url origin https://<your-token>@github.com/<username>/onvif-flutter.git
```

### **Lỗi Permission**
```bash
# Kiểm tra quyền thực thi script
chmod +x push_to_github.sh
```

### **Lỗi Remote đã tồn tại**
```bash
# Xóa remote cũ và thêm lại
git remote remove origin
git remote add origin https://github.com/<username>/onvif-flutter.git
```

## 📞 **Hỗ trợ**

Nếu gặp vấn đề, hãy:
1. Kiểm tra log lỗi trong terminal
2. Đảm bảo repository đã được tạo trên GitHub
3. Kiểm tra username GitHub chính xác
4. Đảm bảo có quyền push vào repository
