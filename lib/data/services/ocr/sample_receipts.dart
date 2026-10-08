/// Model for sample receipt presets used in web OCR demo.
class SampleReceiptPreset {
  final String title;
  final String storeName;
  final String rawText;

  const SampleReceiptPreset({
    required this.title,
    required this.storeName,
    required this.rawText,
  });
}

/// Collection of realistic Vietnamese retail receipts for OCR demonstration.
class SampleReceipts {
  SampleReceipts._();

  static const winMart = '''
SIÊU THỊ WINMART+
Đ/C: 158 Nguyễn Đình Chiểu, P.6, Quận 3, TP.HCM
MST: 0104918404
HÓA ĐƠN BÁN HÀNG
NGÀY: 08/10/2026 10:35
--------------------------------
1. SỮA TƯƠI TIỆT TRÙNG TH TRUE MILK 1L    38.000
2. BÁNH MÌ SANDWICH KINH ĐÔ               25.000
3. TRỨNG GÀ BA HUÂN HỘP 10 QUẢ            32.000
4. NƯỚC KHOÁNG LAVIE 1.5L                 10.000
5. TÁO ENVY NHẬP KHẨU NEW ZEALAND         80.000
--------------------------------
TỔNG CỘNG TIỀN HÀNG:                     185.000
TỔNG TIỀN THANH TOÁN:                    185.000
TIỀN KHÁCH ĐƯA:                          200.000
TIỀN THỐI LẠI:                            15.000
CẢM ƠN QUÝ KHÁCH VÀ HẸN GẶP LẠI!
''';

  static const circleK = '''
CIRCLE K VIETNAM
CỬA HÀNG: LÊ LAI - BẾN THÀNH - Q.1
HOTLINE: 1900 636 009
NGÀY GIAO DỊCH: 07/10/2026 21:15
SỐ HÓA ĐƠN: #CK-98214
--------------------------------
MÌ LY OMACHI XỐT BÒ HẦM                  18.000
XÚC XÍCH ĐỨC PONT 50G                    15.000
COCA COLA LON 330ML                      12.000
--------------------------------
THANH TOÁN:                              45.000
PHƯƠNG THỨC: VÍ ĐIỆN TỬ MOMO
XIN CẢM ƠN QUÝ KHÁCH!
''';

  static const highlands = '''
HIGHLANDS COFFEE
CHI NHÁNH: 45 LÊ DUẨN, QUẬN 1, TP.HCM
SỐ ĐIỆN THOẠI: (028) 3827 2828
NGÀY: 08/10/2026 08:45
PHIẾU THANH TOÁN
--------------------------------
1  PHIN SỮA ĐÁ (L)                       45.000
1  BÁNH MÌ GÀ XÉ NƯỚNG                   20.000
--------------------------------
TỔNG CỘNG:                               65.000 VND
CẢM ƠN QUÝ KHÁCH!
''';

  static const bachHoaXanh = '''
BÁCH HÓA XANH
ĐỊA CHỈ: 240 NGUYỄN OANH, GÒ VẤP
HÓA ĐƠN BÁN LẺ
NGÀY BÁN: 06/10/2026 17:30
--------------------------------
THỊT HEO XAY MEATDELI 300G               58.000
RAU MUỐNG VIETGAP 500G                   12.000
CÀ CHUA ĐÀ LẠT 500G                      18.000
DẦU ĂN TƯỜNG AN 1L                       40.000
--------------------------------
TỔNG CỘNG:                              128.000
TIỀN MẶT:                               128.000
BÁCH HÓA XANH XIN CẢM ƠN!
''';

  static const phucLong = '''
PHÚC LONG COFFEE & TEA
ĐC: 325 LÝ TỰ TRỌNG, BẾN THÀNH, QUẬN 1
HÓA ĐƠN THANH TOÁN
NGÀY: 05/10/2026 15:20
--------------------------------
1 TRÀ SỮA PHÚC LONG (L)                  55.000
1 THÊM TRÂN CHÂU TRẮNG                   15.000
--------------------------------
THÀNH TIỀN:                              70.000
ĐÃ THANH TOÁN QUA THẺ
XIN CẢM ƠN QUÝ KHÁCH!
''';

  static List<SampleReceiptPreset> get presets => const [
        SampleReceiptPreset(
          title: 'WinMart Supermarket',
          storeName: 'WinMart',
          rawText: winMart,
        ),
        SampleReceiptPreset(
          title: 'Circle K Convenience',
          storeName: 'Circle K',
          rawText: circleK,
        ),
        SampleReceiptPreset(
          title: 'Highlands Coffee',
          storeName: 'Highlands Coffee',
          rawText: highlands,
        ),
        SampleReceiptPreset(
          title: 'Bách Hóa Xanh',
          storeName: 'Bách Hóa Xanh',
          rawText: bachHoaXanh,
        ),
        SampleReceiptPreset(
          title: 'Phúc Long Tea & Coffee',
          storeName: 'Phúc Long',
          rawText: phucLong,
        ),
      ];
}
