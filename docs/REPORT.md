# Project Technical Report
## Mini-Project 3: OCR Expense Tracker & Receipt Parser (Flutter & Dart)

**Course**: Multi-Platform Application Development (Phát Triển Ứng Dụng Đa Nền Tảng)  
**Author / Team**: Senior Mobile Engineering Team  
**Date**: October 2026  
**Platform**: Flutter 3.47+ / Dart 3.13+ (Android & iOS)

---

## 1. Executive Summary & Problem Statement

Manual expense tracking is notorious for high user friction. Students, gig workers, and student club treasurers frequently collect paper receipts from convenience stores (Circle K, GS25, 7-Eleven) and supermarkets (WinMart, Bách Hóa Xanh, Co.opmart). Transcribing these receipts manually into spreadsheets or budget apps is tedious, leading to abandoned financial records.

Meanwhile, cloud-based receipt scanning solutions present severe privacy concerns, require reliable internet connectivity, incur costly API subscription fees (e.g., Azure Form Recognizer, Google Cloud Vision), and often struggle with Vietnamese diacritics and local invoice printing conventions.

**Mini-Project 3** delivers a **100% offline, on-device mobile application** built with Flutter & Dart. The application captures physical receipts via a custom camera viewfinder, recognizes raw text using Google ML Kit on-device Latin models, extracts key financial entities (Total Amount, Merchant, Date) using a domain-specific Vietnamese heuristic parser, provides an intuitive verification/editing interface, stores records in a local SQLite database, and visualizes financial health through custom Flutter `CustomPainter` charts without any third-party graphing libraries.

---

## 2. Requirements & Specification Compliance

| Requirement | Implementation Details | Status |
|---|---|---|
| **Flutter 3.x & Dart 3** | Null-safe Dart 3, records, pattern matching, custom enums with metadata | ✅ Completed |
| **On-Device OCR** | `google_mlkit_text_recognition`, zero network calls, completely offline | ✅ Completed |
| **Custom Camera Viewfinder** | `camera` package, live viewfinder, receipt alignment guide, tap-to-focus ring, torch toggle, image cropping to bounding box | ✅ Completed |
| **Local Persistence** | `sqflite` with robust schema, migrations, indexed queries, and image thumbnail caching | ✅ Completed |
| **State Management** | `flutter_riverpod` (AsyncNotifier, StateProvider, Provider) with Clean Architecture separation | ✅ Completed |
| **Custom Canvas Charts** | Pure `CustomPainter`: Donut Chart (sweep animation, touch hit-test) and Bar Chart (vertical growth, nice Y-axis ticks, tooltips) | ✅ Completed |
| **Zero 3rd-Party Chart Libs** | Strictly zero dependencies like fl_chart or syncfusion | ✅ Completed |
| **Unit Testing & Linting** | 24 automated unit tests (`receipt_parser_test.dart`, `vnd_formatter_test.dart`, `widget_test.dart`), 0 `flutter analyze` warnings | ✅ Completed |
| **Documentation Deliverables** | `README.md`, `docs/REPORT.md`, `docs/DEMO_SCRIPT.md`, `LICENSE` | ✅ Completed |

---

## 3. Architecture & System Design

The application adheres strictly to Clean Architecture principles, ensuring modularity, testability, and separation of concerns.

```
┌────────────────────────────────────────────────────────┐
│                        UI LAYER                        │
│  CameraScreen  ReviewScreen  Dashboard  Transactions  Charts  │
└───────────────────────────┬────────────────────────────┘
                            │ (watches / dispatches)
┌───────────────────────────▼────────────────────────────┐
│                   STATE MANAGEMENT                     │
│  TransactionListNotifier   DashboardSummaryProvider    │
│  ThemeModeProvider         (flutter_riverpod)          │
└──────────────┬────────────────────────────┬────────────┘
               │                            │
┌──────────────▼─────────────┐ ┌────────────▼────────────┐
│        DOMAIN LAYER        │ │       DATA LAYER        │
│  ReceiptParser (Pure Dart) │ │  TransactionRepository  │
│  ParsedReceipt Entity      │ │  DatabaseHelper (SQLite)│
│  Category Enum             │ │  ImageStorageService    │
└────────────────────────────┘ └─────────────────────────┘
```

### 3.1. Domain Layer (Pure Dart)
- Independent of Flutter UI frameworks and third-party plugins.
- `ReceiptParser`: Stateless engine receiving `List<String>` of raw OCR text lines and outputting a `ParsedReceipt`.
- `Category`: Sealed enum representing categorized expenditures (`food`, `study`, `travel`, `gear`, `entertainment`, `other`) complete with associated icons and color palettes.

### 3.2. Data Layer
- **SQLite Database (`DatabaseHelper`)**: Handles database creation, version migrations, indexing on `date` and `category`, and transactional safety.
- **Model Mapping (`TransactionModel`)**: Handles conversion between SQLite records and domain entities, serializing amounts as integer VND amounts (e.g., `150000`).
- **File Storage (`ImageStorageService`)**: Manages the local device filesystem for storing cropped receipt images and thumbnails under the application document directory.

### 3.3. Presentation Layer & State Management
- Riverpod `AsyncNotifier` manages asynchronous CRUD operations. All state transitions (loading, error, data) are handled declaratively.
- `DashboardSummaryProvider` dynamically aggregates monthly spending, category breakdowns, daily trends, and top expense categories without blocking the UI thread.

---

## 4. On-Device OCR & Heuristic Parsing Engine

Physical retail receipts exhibit extreme optical variability: low-contrast thermal paper, thermal fade, creases, skewed text, and cluttered tax/hotline data. The parsing engine uses a multi-tier heuristic pipeline:

### 4.1. Text Normalization & Diacritic Handling
Vietnamese thermal printouts often mix unaccented Latin characters with accented Vietnamese (`TỔNG CỘNG` vs `TONG CONG`). The parser incorporates `_removeDiacritics()`, which maps all 134 Vietnamese vowel-accent permutations to unaccented ASCII equivalents before keyword comparison.

### 4.2. Amount Extraction Engine
1. **Keyword-Anchored Search**: The parser scans for known total keywords (`TỔNG TIỀN`, `TỔNG CỘNG`, `THANH TOÁN`, `THÀNH TIỀN`, `TOTAL`, `AMOUNT DUE`).
2. **Two-Line Window**: Because OCR engines frequently split headers and amounts across adjacent lines (e.g., line $i$ = "TỔNG TIỀN", line $i+1$ = "150.000"), the parser evaluates both the matching line and the subsequent line.
3. **Thousand Separator Resolver**: Handles Vietnamese dot separators (`150.000`) and standard comma separators (`150,000`), filtering out dates, phone numbers, and decimals.
4. **Fallback Heuristic**: In damaged receipts lacking explicit headers, the parser examines the lower 50% of the receipt lines and identifies the maximum plausible currency value within the reasonable range ($1,000 \le \text{amount} \le 100,000,000$ VND).

### 4.3. Merchant Extraction & Retail Chain Boosting
1. **Chain Dictionary Lookup**: Contains known retail brands (`WinMart`, `Bách Hóa Xanh`, `Circle K`, `Highlands Coffee`, `Phúc Long`, `Co.opmart`, `GS25`, `Lotte Mart`, etc.). Longest string matches take precedence (e.g., `HIGHLANDS COFFEE` precedes `HIGHLANDS`).
2. **Header Heuristic Scoring**: If the receipt is from an independent store, the parser analyzes the first 7 lines, scoring candidates based on:
   - Top-line bias: Earlier lines receive higher weights.
   - Capitalization ratio: All-caps store titles are favored.
   - Length optimization: Lines between 5 and 30 characters receive bonus points.
   - Exclusion filters: Immediate disqualification for lines containing phone numbers (`09xx`, `+84`), tax identifiers (`MST`), website domains (`.vn`, `.com`), or addresses (`Đ/C:`, `Địa chỉ`).

### 4.4. Date Parsing
Regex matching captures variations of `DD/MM/YYYY`, `DD-MM-YYYY`, `DD.MM.YYYY`, and `DD/MM/YY` with optional timestamps (`HH:mm:ss`), automatically adjusting 2-digit years (`24` $\rightarrow$ `2024`) and rejecting invalid calendar dates.

---

## 5. Custom Canvas Charting Implementation

A core constraint of the project was **zero third-party charting libraries** (no `fl_chart`, `syncfusion_flutter_charts`, etc.). Both charts are custom-engineered using Flutter's low-level `CustomPainter` API:

### 5.1. Donut Chart (`DonutChartPainter`)
- **Geometry & Math**: Iterates through category spending ratios. Each slice sweeps an angle:
  $$\theta_i = \left(\frac{\text{amount}_i}{\text{total}}\right) \times 2\pi$$
- **Arc Drawing**: Employs `canvas.drawArc()` with `PaintingStyle.stroke` and configured `strokeWidth`.
- **Gap & Shadow Rendering**: Injects dynamic radial boundary lines between segments and applies a blurred shadow glow behind active slices.
- **Interactive Hit Testing**: Maps pointer touch offsets $(x, y)$ from cartesian space to polar coordinates:
  $$r = \sqrt{(x - x_c)^2 + (y - y_c)^2}, \quad \theta = \operatorname{atan2}(y - y_c, x - x_c)$$
  Validates if the touch falls within the ring radius $[R_{\text{inner}}, R_{\text{outer}}]$ and identifies the clicked category.
- **Sweep Animation**: Driven by an `AnimationController` with `CurvedAnimation(Curves.easeOutCubic)`.

### 5.2. Bar Chart (`BarChartPainter`)
- **Nice Number Y-Axis Scaling**: Implements an algorithm that calculates friendly scale ceilings ($100\text{K}, 250\text{K}, 500\text{K}, 1\text{M}$) so Y-axis tick gridlines always display clean, rounded denominations.
- **Grid & Legend Layout**: Calculates layout widths, margins, and draws dotted horizontal reference grids with compact currency text (`VndFormatter.formatCompact`).
- **Rounded Bar Geometry**: Renders bars with `RRect.fromRectAndCorners()`, animating height upward from zero upon screen entrance.
- **Tooltip Hit-Testing**: Tracks the hovered/tapped bar column and overlays a custom tooltip displaying the full date, category, and precise amount.

---

## 6. Performance, Security & Offline Reliability

1. **Zero Data Leakage**: All computation is performed locally. Image data remains within the app's sandboxed storage (`getApplicationDocumentsDirectory()`), preventing exposure of personal spending or location data.
2. **Memory & Canvas Performance**:
   - Camera image frames are captured on-demand rather than streaming continuous OCR buffers, preventing device overheating and battery drain.
   - Cropped images are resized before generating thumbnails, preserving device RAM.
   - `CustomPainter` implementations strictly optimize `shouldRepaint()` to prevent redundant frame rebuilds, maintaining steady 60–120 FPS animations.
3. **Storage Resilience**: SQLite foreign keys and atomic transactions ensure database integrity even during sudden app termination.

---

## 7. Testing & Quality Assurance

Quality assurance was integrated across each milestone:

- **Static Analysis**: The code was audited using `flutter analyze` with strict analysis rules. The project achieves **0 errors and 0 warnings**.
- **Automated Unit Testing**:
  - `test/receipt_parser_test.dart` (16 unit tests): Validates WinMart, Bách Hóa Xanh, Circle K, Highlands, English receipts, unaccented Vietnamese, multi-line splits, fallback detection, noise rejection, and confidence scoring.
  - `test/vnd_formatter_test.dart` (7 unit tests): Validates currency formatting, thousand separators, rounding behavior, and compact notation ($50\text{K}, 1.5\text{M}$).
  - `test/widget_test.dart`: Validates navigation shell integrity and screen switching.
- **Test Results**: **24 out of 24 tests passed** ($100\%$ pass rate).

---

## 8. Conclusion & Future Roadmap

Mini-Project 3 demonstrates that an on-device, offline Flutter application can achieve enterprise-grade OCR extraction, robust state management, and bespoke visual analytics without external backend services or bloated UI libraries.

### Future Roadmap
1. **Multi-Item Line Extraction**: Extend the heuristic parser to extract individual itemized product rows with unit prices.
2. **Receipt Edge Detection & Auto-Crop**: Implement computer vision contour detection (e.g. OpenCV / ML Kit Document Scanner API) to automatically detect receipt corners in real time before shutter press.
3. **Export & Backup**: Provide encrypted CSV and JSON export functionality for integration with Excel or Google Sheets.
