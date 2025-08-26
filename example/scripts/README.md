# ONVIF Flutter Library - Test & Debug Scripts

Thư mục này chứa tất cả các file test và debug scripts để kiểm tra và troubleshoot ONVIF Flutter library.

## 📁 File Organization

### 🔍 **Debug Scripts**
Các script để debug và troubleshoot các vấn đề cụ thể:

- **`debug_example.dart`** - Basic debug script
- **`debug_parsing.dart`** - Debug XML parsing issues
- **`debug_get_recordings.dart`** - Debug GetRecordings response
- **`debug_get_tracks.dart`** - Debug GetTracks functionality
- **`debug_recording.dart`** - Debug recording-related issues
- **`debug_search_recordings.dart`** - Debug recording search
- **`debug_soap_fault.dart`** - Debug SOAP fault responses
- **`debug_user_management.dart`** - Debug user management features
- **`raw_debug_example.dart`** - Raw SOAP request/response debugging

### 🧪 **Test Scripts**
Các script để test các tính năng cụ thể:

- **`test_working_endpoint.dart`** - Test endpoint discovery
- **`test_fallback_search.dart`** - Test fallback search mechanism
- **`test_recording_segments.dart`** - Test recording segments
- **`test_virtual_segments.dart`** - Test virtual segmentation
- **`test_time_specific_uris.dart`** - Test time-specific URI generation
- **`test_tracks_parsing.dart`** - Test track parsing (ONVIF 5.25.12/5.25.13)
- **`test_get_tracks_response_item.dart`** - Test GetTracksResponseItem structure

### 🔬 **Deep Dive Scripts**
Các script để khám phá sâu các tính năng:

- **`discover_onvif.dart`** - ONVIF device discovery
- **`port_scan_example.dart`** - Port scanning for ONVIF services
- **`explore_recording_segments.dart`** - Deep dive into recording segments
- **`deep_dive_recording_jobs.dart`** - Advanced recording job analysis

### ✅ **Final Test Scripts**
Các script để kiểm tra cuối cùng:

- **`final_test.dart`** - Final comprehensive test

## 🚀 How to Run

### **Run từ thư mục example:**
```bash
cd example
dart scripts/debug_example.dart
dart scripts/test_recording_segments.dart
```

### **Run từ thư mục scripts:**
```bash
cd example/scripts
dart debug_example.dart
dart test_recording_segments.dart
```

## 📋 Script Categories

### **🔧 Troubleshooting Scripts**
- `debug_*.dart` - Các script để debug issues
- `raw_debug_example.dart` - Raw SOAP debugging
- `debug_soap_fault.dart` - SOAP fault analysis

### **🎯 Feature Testing Scripts**
- `test_*.dart` - Các script để test features
- `test_tracks_parsing.dart` - Track parsing validation
- `test_get_tracks_response_item.dart` - ONVIF compliance testing

### **🔍 Discovery Scripts**
- `discover_onvif.dart` - Device discovery
- `port_scan_example.dart` - Service discovery
- `test_working_endpoint.dart` - Endpoint testing

### **📊 Analysis Scripts**
- `explore_recording_segments.dart` - Recording analysis
- `deep_dive_recording_jobs.dart` - Advanced analysis
- `final_test.dart` - Comprehensive testing

## 🎯 Common Use Cases

### **Debug Connection Issues:**
```bash
dart scripts/debug_example.dart
dart scripts/raw_debug_example.dart
```

### **Test Recording Features:**
```bash
dart scripts/test_recording_segments.dart
dart scripts/test_virtual_segments.dart
dart scripts/test_time_specific_uris.dart
```

### **Validate ONVIF Compliance:**
```bash
dart scripts/test_tracks_parsing.dart
dart scripts/test_get_tracks_response_item.dart
```

### **Discover Device Services:**
```bash
dart scripts/discover_onvif.dart
dart scripts/port_scan_example.dart
```

## 📝 Notes

- Tất cả scripts sử dụng device: `fb000033.ddns.net:8080`
- Credentials: `admin` / `FB000033`
- Scripts được thiết kế để chạy độc lập
- Mỗi script có error handling riêng
- Output được format để dễ đọc và debug

## 🔄 Maintenance

Khi thêm tính năng mới vào library:
1. Tạo test script tương ứng trong thư mục này
2. Update README này với thông tin mới
3. Đảm bảo script có error handling tốt
4. Test script với real device

## 🎊 Happy Testing!

Các scripts này giúp đảm bảo ONVIF Flutter library hoạt động ổn định và đúng chuẩn ONVIF!
