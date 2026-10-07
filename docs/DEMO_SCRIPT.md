# Mini-Project 3: Live Demo & Presentation Script 🎬

**App Name**: OCR Expense Tracker & Receipt Parser  
**Target Duration**: 3 – 5 minutes  
**Audience**: Course Instructors, Evaluators & Peers  

---

## 🎯 Demo Preparation Checklist
- [ ] Install application APK on test device or launch on Android/iOS simulator.
- [ ] Prepare 2 sample physical or digital receipts:
  - **Receipt A**: WinMart or Bách Hóa Xanh grocery receipt (Vietnamese format, dot separators `77.000 đ`).
  - **Receipt B**: Circle K or Highlands Coffee bill (split line amount or unaccented text).
- [ ] Ensure device camera permissions are granted.
- [ ] Set device display to show clean navigation.

---

## 📋 Step-by-Step Presentation Flow

### 0:00 – 0:45 | Scene 1: Introduction & Dashboard Overview
**Speaker Script:**
> *"Xin chào thầy cô và các bạn. Hôm nay nhóm xin giới thiệu Mini-Project 3: **OCR Expense Tracker & Receipt Parser** – ứng dụng quản lý chi tiêu cá nhân thông minh bằng nhận diện hóa đơn hoàn toàn Offline trên thiết bị di động bằng Flutter & Dart."*
>
> *"Mục tiêu của ứng dụng là giải quyết sự bất tiện khi nhập liệu chi tiêu thủ công của sinh viên và thủ quỹ câu lạc bộ. Mọi thao tác từ chụp ảnh, quét chữ, phân tích số tiền, đến lưu trữ và vẽ biểu đồ đều được thực hiện 100% on-device, không cần internet, bảo mật tuyệt đối dữ liệu người dùng."*

**Action on Screen:**
1. Open the app to the **Dashboard Screen**.
2. Point out:
   - **Total Spending Card** (highlighting formatted VND currency `1.250.000 ₫`).
   - **Monthly Budget Metric** and quick action buttons (*Scan Receipt*, *All Transactions*).
   - **Recent Transactions list** showing category badges, dates, and amounts.

---

### 0:45 – 1:45 | Scene 2: Live Camera Viewfinder & On-Device OCR
**Speaker Script:**
> *"Bây giờ nhóm sẽ thực hiện quét một hóa đơn mua sắm thực tế. Khi bấm nút 'Scan Receipt', ứng dụng mở màn hình camera chuyên dụng."*
>
> *"Ở đây, chúng ta có khung định vị hóa đơn (viewfinder overlay) với viền mờ xung quanh và 4 góc căn chỉnh. Người dùng có thể chạm vào màn hình để lấy nét (tap-to-focus) với hiệu ứng vòng tròn hoạt họa, bật đèn flash khi chụp trong điều kiện thiếu sáng, hoặc chọn ảnh từ thư viện."*

**Action on Screen:**
1. Tap the **Scan Receipt** floating button.
2. Frame Receipt A (e.g., WinMart receipt) inside the guide rectangle.
3. Tap on the screen to show the **animated focus ring**.
4. Toggle the **torch icon** on and off.
5. Tap the **Capture Button**.
6. The app automatically crops the image to the bounding box and initiates **Google ML Kit Text Recognition**.

---

### 1:45 – 2:45 | Scene 3: Heuristic Parsing & Review Screen
**Speaker Script:**
> *"Chỉ trong vòng chưa đầy 1 giây, bộ xử lý ngôn ngữ và heuristic chuyên biệt cho hóa đơn Việt Nam đã tự động bóc tách thành công:*
> - *Tên đơn vị: **WinMart***
> - *Số tiền thanh toán: **77.000 ₫***
> - *Ngày mua: **15/05/2024***
>
> *"Hệ thống cũng đánh giá mức độ tin cậy (Confidence Score: 100%) với huy hiệu màu xanh. Bên cạnh đó, người dùng có thể chạm vào ảnh hóa đơn đã cắt để zoom và đối chiếu trực tiếp từng dòng. Mọi trường thông tin đều có thể chỉnh sửa lại dễ dàng, và ta chọn danh mục tương ứng (Food, Study, Gear,...). Bấm 'Save Expense' để lưu vào cơ sở dữ liệu SQLite."*

**Action on Screen:**
1. Show the **Review Screen** with parsed fields pre-filled.
2. Tap the cropped receipt thumbnail to open the **Pinch-to-Zoom dialog** and close it.
3. Demonstrate editing a note or choosing category `Food`.
4. Tap **Save Expense**.

---

### 2:45 – 3:30 | Scene 4: Transaction Management & Local SQLite Persistence
**Speaker Script:**
> *"Giao dịch vừa lưu ngay lập tức được cập nhật vào màn hình 'All Transactions'. Dữ liệu được lưu trữ an toàn trong SQLite cục bộ với các tính năng chuyên nghiệp:*
> - *Bộ lọc danh mục dạng Filter Chips (All, Food, Study, Travel, Gear, Entertainment).*
> - *Thanh tìm kiếm theo tên cửa hàng trong thời gian thực.*
> - *Tính năng vuốt để xóa (Swipe-to-delete) có thông báo Undo khôi phục nhanh chóng."*

**Action on Screen:**
1. Switch to the **Expenses** tab.
2. Search "WinMart" in the search bar.
3. Tap category chips to show instant filtering.
4. Swipe a sample transaction to delete it, then tap **Undo** on the SnackBar to restore it immediately.
5. Tap on the transaction to open the **Expense Details Screen** and show full details and the saved receipt photo.

---

### 3:30 – 4:30 | Scene 5: Custom Canvas Analytics (Zero 3rd-Party Libraries)
**Speaker Script:**
> *"Điểm nổi bật về mặt kỹ thuật của dự án là toàn bộ biểu đồ chi tiêu đều được nhóm tự tay lập trình bằng Flutter `CustomPainter` trên Canvas, hoàn toàn không phụ thuộc vào bất kỳ thư viện bên thứ ba nào như fl_chart."*
>
> *"Gồm 2 biểu đồ chính:*
> 1. *Biểu đồ Donut: Hiển thị tỷ trọng chi tiêu theo từng danh mục. Có hoạt ảnh quét (sweep animation), các lát cắt có khoảng cách tinh tế và bóng đổ glow. Người dùng có thể chạm vào từng cung tròn (hit testing) để xem tỷ lệ và số tiền.*
> 2. *Biểu đồ Cột tuần: Hiển thị biến động chi tiêu 7 ngày với thuật toán làm tròn trục Y thông minh (Nice Number algorithm), thanh cột mọc dần từ dưới lên, và chạm vào cột để hiện Tooltip chi tiết."*

**Action on Screen:**
1. Switch to the **Analytics** tab.
2. Point out the animated **Donut Chart**. Tap on different slices to show interactive touch selection.
3. Scroll down to the **Weekly Bar Chart**. Tap on the highest bar to display the interactive floating tooltip.

---

### 4:30 – 5:00 | Scene 6: Offline Verification & Summary
**Speaker Script:**
> *"Để chứng minh tính độc lập và bảo mật, nhóm bật chế độ Máy bay (Airplane Mode). Ứng dụng vẫn hoạt động trơn tru 100%: từ chụp, OCR, đọc hóa đơn đến lưu trữ và vẽ biểu đồ.*
>
> *Dự án đạt chuẩn kỹ thuật cao: `flutter analyze` 0 cảnh báo, 24/24 unit test vượt qua kiểm thử tự động, kiến trúc Clean Architecture kết hợp Riverpod rõ ràng, dễ bảo trì và mở rộng. Cảm ơn thầy cô và các bạn đã theo dõi!"*

**Action on Screen:**
1. Toggle Airplane Mode on device settings (if demonstrating live).
2. Conclude presentation.
