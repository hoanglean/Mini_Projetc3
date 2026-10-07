import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_expense_tracker/domain/parser/receipt_parser.dart';

void main() {
  late ReceiptParser parser;

  setUp(() {
    parser = ReceiptParser();
  });

  group('ReceiptParser Tests', () {
    test('1. Empty lines returns nulls and zero confidence', () {
      final result = parser.parse([]);
      expect(result.totalAmount, isNull);
      expect(result.merchantName, isNull);
      expect(result.date, isNull);
      expect(result.confidence, 0.0);
    });

    test('2. WinMart receipt with dots as thousand separators and Vietnamese diacritics', () {
      final lines = [
        'SIÊU THỊ WINMART+',
        'Địa chỉ: 123 Cầu Giấy, Hà Nội',
        'SĐT: 02473081368',
        'Ngày: 15/05/2024 14:30',
        'Mì Hảo Hảo x 5       45.000',
        'Sữa tươi Vinamilk     32.000',
        'TỔNG TIỀN:           77.000 đ',
        'TIỀN MẶT:           100.000',
        'TIỀN THỐI:           23.000',
      ];

      final result = parser.parse(lines);
      expect(result.merchantName, 'WINMART');
      expect(result.totalAmount, 77000.0);
      expect(result.date, DateTime(2024, 5, 15, 14, 30));
      expect(result.confidence, 1.0);
    });

    test('3. Bách Hóa Xanh receipt with TỔNG CỘNG and DD/MM/YYYY date', () {
      final lines = [
        'BÁCH HÓA XANH',
        'HÓA ĐƠN BÁN HÀNG',
        'Ngày mua: 02/09/2024',
        'Thịt bò phi lê       120.000',
        'Rau cải xanh          15.000',
        'TỔNG CỘNG            135.000 VND',
        'CẢM ƠN QUÝ KHÁCH',
      ];

      final result = parser.parse(lines);
      expect(result.merchantName, 'BÁCH HÓA XANH');
      expect(result.totalAmount, 135000.0);
      expect(result.date, DateTime(2024, 9, 2));
      expect(result.confidence, 1.0);
    });

    test('4. Circle K receipt with THANH TOAN on same line', () {
      final lines = [
        'CIRCLE K VIETNAM',
        'CỬA HÀNG 24H',
        'Ngày: 20/11/2024 22:15:00',
        'Bánh mì kẹp          25.000',
        'Nước tăng lực Redbull 18.000',
        'THANH TOÁN: 43.000đ',
      ];

      final result = parser.parse(lines);
      expect(result.merchantName, 'CIRCLE K');
      expect(result.totalAmount, 43000.0);
      expect(result.date, DateTime(2024, 11, 20, 22, 15));
      expect(result.confidence, 1.0);
    });

    test('5. Amount split on next line after keyword', () {
      final lines = [
        'HIGHLANDS COFFEE',
        'Hóa đơn số: 99482',
        'Ngày: 10/06/2024',
        'Phin Sữa Đá L',
        'TỔNG TIỀN',
        '55.000',
      ];

      final result = parser.parse(lines);
      expect(result.merchantName, 'HIGHLANDS COFFEE');
      expect(result.totalAmount, 55000.0);
      expect(result.date, DateTime(2024, 6, 10));
    });

    test('6. English receipt with TOTAL and commas as thousand separators', () {
      final lines = [
        'STARBUCKS COFFEE',
        'Store #1042',
        'Date: 12-08-2024 09:45',
        'Caramel Macchiato    95,000',
        'Croissant            45,000',
        'TOTAL: 140,000 VND',
      ];

      final result = parser.parse(lines);
      expect(result.totalAmount, 140000.0);
      expect(result.date, DateTime(2024, 8, 12, 9, 45));
    });

    test('7. Fallback largest amount when no total keyword present', () {
      final lines = [
        'TIỆM TẠP HÓA CÔ BA',
        'Ngày 01/04/2024',
        'Gạo ST25 5kg',
        'Dầu ăn Neptune 1L',
        '45.000',
        '185.000',
      ];

      final result = parser.parse(lines);
      expect(result.totalAmount, 185000.0);
      expect(result.merchantName, 'TIỆM TẠP HÓA CÔ BA');
    });

    test('8. Known chains recognition: Phúc Long, GS25, Lotte Mart', () {
      expect(parser.parse(['PHÚC LONG TEA & COFFEE', 'TỔNG: 65.000']).merchantName, 'PHÚC LONG');
      expect(parser.parse(['GS25 CONVENIENCE', 'TỔNG: 30.000']).merchantName, 'GS25');
      expect(parser.parse(['LOTTE MART SOUTH SAIGON', 'TỔNG: 500.000']).merchantName, 'LOTTE MART');
    });

    test('9. Skip phone number, tax code (MST), and address for merchant', () {
      final lines = [
        'MST: 0312345678',
        'Hotline: 1900 1234',
        'QUÁN CƠM TẤM SÀI GÒN',
        'Đ/C: 45 Lê Lợi, Q.1',
        'Ngày: 05/07/2024',
        'TỔNG CỘNG: 65.000',
      ];

      final result = parser.parse(lines);
      expect(result.merchantName, 'QUÁN CƠM TẤM SÀI GÒN');
      expect(result.totalAmount, 65000.0);
    });

    test('10. Two-digit year parsing (e.g. 25/12/24 -> 2024)', () {
      final lines = [
        'MINISTOP',
        '25/12/24',
        'TOTAL: 35.000',
      ];

      final result = parser.parse(lines);
      expect(result.date?.year, 2024);
      expect(result.date?.month, 12);
      expect(result.date?.day, 25);
    });

    test('11. Date with dot separators (e.g. 18.03.2024)', () {
      final lines = [
        'FAMILY MART',
        '18.03.2024',
        'THANH TOAN: 50.000',
      ];

      final result = parser.parse(lines);
      expect(result.date, DateTime(2024, 3, 18));
    });

    test('12. Large transaction amount with multiple dots', () {
      final lines = [
        'NGUYEN KIM ELECTRONICS',
        'Ngày: 10/10/2024',
        'Tivi Samsung 55 inch',
        'TỔNG TIỀN: 14.500.000 VND',
      ];

      final result = parser.parse(lines);
      expect(result.totalAmount, 14500000.0);
    });

    test('13. Confidence score calculation: partial vs full extraction', () {
      // Full extraction (all 3 found: 0.5 + 0.25 + 0.25 = 1.0)
      final fullResult = parser.parse([
        'WINMART',
        '15/01/2024',
        'TOTAL: 100.000',
      ]);
      expect(fullResult.confidence, 1.0);

      // Only amount found: 0.5
      final onlyAmountResult = parser.parse([
        '0912345678',
        'MST: 0300123456',
        'TOTAL: 100.000',
      ]);
      expect(onlyAmountResult.totalAmount, 100000.0);
      expect(onlyAmountResult.confidence, 0.5);
    });

    test('14. Noise resilience: OCR symbols and stray characters', () {
      final lines = [
        '---***---',
        'CO.OPMART CONG HOA',
        '===> HD: 00192 <===',
        'Ngay : 14/02/2024',
        'Dau an Simply 1L: 52.000',
        'THÀNH TIỀN: 52.000 đ',
        '===== CAM ON QUY KHACH =====',
      ];

      final result = parser.parse(lines);
      expect(result.merchantName, 'CO.OPMART');
      expect(result.totalAmount, 52000.0);
      expect(result.date, DateTime(2024, 2, 14));
      expect(result.confidence, 1.0);
    });

    test('15. Avoid extracting phone numbers or tax codes as amounts', () {
      final lines = [
        'CỬA HÀNG TIỆN LỢI',
        'SĐT: 0987654321',
        'MST: 0109988776',
        'Ngày: 01/01/2024',
        'Bánh ngọt',
        'TỔNG CỘNG: 28.000 đ',
      ];

      final result = parser.parse(lines);
      expect(result.totalAmount, 28000.0);
    });

    test('16. Unaccented Vietnamese text without diacritics', () {
      final lines = [
        'BACH HOA XANH',
        'Ngay: 20/05/2024',
        'TONG CONG: 89.000 VND',
      ];

      final result = parser.parse(lines);
      expect(result.merchantName, 'BÁCH HÓA XANH');
      expect(result.totalAmount, 89000.0);
      expect(result.confidence, 1.0);
    });
  });
}
