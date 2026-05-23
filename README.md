# PMG Grade — Hệ thống chấm điểm Project Management

App desktop Flutter để giảng viên chấm điểm môn Project Management tại FPT University.

## Cấu trúc project

```
pmg-grade/
├── lib/
│   ├── main.dart                          # Entry point
│   ├── core/
│   │   ├── models/app_models.dart         # Data models + Mock data
│   │   ├── providers/app_state_provider.dart  # State management
│   │   └── theme/app_theme.dart           # VSCode dark theme
│   ├── screens/
│   │   ├── main_shell.dart                # Root shell + animated router
│   │   ├── setup/setup_screen.dart        # Màn hình 1: Setup
│   │   └── grading/
│   │       ├── grading_screen.dart        # Màn hình 2: Chấm điểm (3 cột)
│   │       └── panels/
│   │           ├── student_list_panel.dart  # Cột trái
│   │           ├── submission_panel.dart    # Cột giữa
│   │           └── scoring_panel.dart       # Cột phải
│   └── widgets/
│       ├── title_bar.dart                 # Custom title bar
│       ├── grading_top_bar.dart           # Top navigation bar
│       └── file_drop_card.dart            # File picker card
├── pubspec.yaml
└── windows/CMakeLists.txt
```

## Cài đặt và chạy

### Yêu cầu
- Flutter SDK >= 3.0.0 (với Windows desktop support)
- Visual Studio 2022 với C++ workload

### Cài đặt Flutter (nếu chưa có)
```powershell
# Tải Flutter SDK từ flutter.dev
# Thêm vào PATH: C:\flutter\bin

flutter doctor
flutter config --enable-windows-desktop
```

### Chạy app
```powershell
cd d:\pmg-grade
flutter pub get
flutter run -d windows
```

### Build production
```powershell
flutter build windows --release
# Output: build\windows\x64\runner\Release\pmg_grade.exe
```

## Tính năng UI

### Màn hình 1: Setup
- Import đề thi (.docx)
- Import barem chấm điểm (.docx) → tự động parse criteria
- Import danh sách sinh viên (.csv)
- Chọn thư mục bài thi (tự động quét .txt)
- Preview danh sách sinh viên với trạng thái

### Màn hình 2: Chấm điểm (3 cột có thể resize)
**Cột trái — Danh sách sinh viên:**
- Search + filter (Tất cả / Chưa chấm / Đang chấm / Đã chấm)
- Progress bar tiến độ chấm
- Navigate prev/next student

**Cột giữa — Bài làm + Nhận xét:**
- Hiển thị nội dung file .txt (selectable text)
- Tổng điểm realtime
- Nhận xét công khai (sinh viên thấy)
- Ghi chú riêng tư (chỉ GV thấy)
- Nút xác nhận điểm cuối

**Cột phải — Barem điểm:**
- Từng criteria (Q1, Q2...) có thể expand/collapse
- Progress bar từng câu
- Gợi ý AI (màu tím) với lý do chi tiết
- Input điểm GV chấm với max score hint
- Quick buttons: Full / 75% / 50% / 0
- Bắt buộc nhập lý do trừ điểm
- Export CSV dialog

## Ghi chú thiết kế
- Lấy cảm hứng từ VSCode dark theme (theo yêu cầu)
- Font: Inter (Google Fonts)
- Color palette: GitHub dark + accent blue/purple
- Resizable panels (kéo divider)
- AI suggestions chỉ là tham khảo — GV chấm điểm cuối cùng
