# ONVIF Flutter UI Example

Một Flutter app với UI/UX đẹp để demo ONVIF Flutter library.

## 🎨 Features

- **Modern Material Design 3 UI**
- **Connection Management** - Kết nối/ngắt kết nối với ONVIF device
- **Device Information** - Hiển thị thông tin thiết bị
- **Media Profiles** - Danh sách và chi tiết media profiles
- **Recordings** - Danh sách và chi tiết recordings
- **Responsive Design** - Hỗ trợ light/dark theme
- **Error Handling** - Xử lý lỗi với SnackBar notifications

## 🚀 How to Run

### **Flutter UI Examples:**

1. **Install dependencies:**
   ```bash
   flutter pub get
   ```

2. **Run Flutter UI app:**
   ```bash
   flutter run onvif_ui_example.dart
   ```

### **Command Line Examples:**

1. **Simple UI Example:**
   ```bash
   dart simple_ui_example.dart
   ```

2. **Basic Example:**
   ```bash
   dart onvif_example.dart
   ```

3. **User Management Example:**
   ```bash
   dart user_management_example.dart
   ```

### **Test & Debug Scripts:**

Tất cả test và debug scripts được tổ chức trong thư mục `scripts/`:

```bash
# Debug scripts
dart scripts/debug_example.dart
dart scripts/debug_get_recordings.dart

# Test scripts  
dart scripts/test_recording_segments.dart
dart scripts/test_tracks_parsing.dart

# Discovery scripts
dart scripts/discover_onvif.dart
dart scripts/port_scan_example.dart
```

Xem `scripts/README.md` để biết thêm chi tiết về các scripts.

## 📱 Screenshots

### Connection Screen
- Form nhập thông tin kết nối (Host, Port, Username, Password)
- Buttons kết nối/ngắt kết nối
- Status indicator

### Device Information
- Manufacturer, Model, Firmware Version
- Serial Number, Hardware ID

### Media Profiles
- Danh sách profiles với icons
- Tap để xem chi tiết
- Video/Audio source information

### Recordings
- Danh sách recordings với tracks
- Tap để xem chi tiết tracks
- Track types (Audio/Video)

## 📁 File Structure

```
example/
├── README.md                    # This file
├── pubspec.yaml                 # Flutter dependencies
├── onvif_ui_example.dart        # Flutter UI example
├── simple_ui_example.dart       # Command line UI example
├── onvif_example.dart           # Basic ONVIF example
├── user_management_example.dart # User management example
└── scripts/                     # Test & debug scripts
    ├── README.md               # Scripts documentation
    ├── debug_*.dart            # Debug scripts
    ├── test_*.dart             # Test scripts
    ├── discover_*.dart         # Discovery scripts
    └── explore_*.dart          # Analysis scripts
```

## 🎯 UI Components

### Cards
- **Connection Card** - Form kết nối với validation
- **Device Info Card** - Thông tin thiết bị
- **Media Profiles Card** - Danh sách profiles
- **Recordings Card** - Danh sách recordings

### Interactive Elements
- **Form Fields** - Host, Port, Username, Password
- **Buttons** - Connect/Disconnect với loading states
- **List Tiles** - Profiles và Recordings với tap actions
- **Dialogs** - Chi tiết Profile và Recording

### Status Indicators
- **Connection Status** - Visual feedback cho connection state
- **Loading Indicators** - Progress khi đang kết nối
- **SnackBar Notifications** - Success/Error messages

## 🎨 Design Features

- **Material Design 3** - Modern UI components
- **Color Scheme** - Consistent color palette
- **Typography** - Proper text hierarchy
- **Spacing** - Consistent padding và margins
- **Icons** - Meaningful icons cho mỗi section
- **Animations** - Smooth transitions

## 📋 Usage

1. **Enter Device Details:**
   - Host: `fb000033.ddns.net`
   - Port: `8080`
   - Username: `admin`
   - Password: `FB000033`

2. **Connect:**
   - Tap "Kết nối" button
   - Wait for connection status
   - View device information

3. **Explore:**
   - Tap on Media Profiles để xem chi tiết
   - Tap on Recordings để xem tracks
   - Use "Ngắt kết nối" để disconnect

## 🔧 Customization

Bạn có thể customize UI bằng cách:

- Thay đổi colors trong `ThemeData`
- Modify card layouts
- Add new sections
- Customize animations
- Add more interactive features

## 📱 Platform Support

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Desktop (Windows, macOS, Linux)

## 🎊 Enjoy!

UI example này showcase tất cả features của ONVIF Flutter library với modern, beautiful interface!
