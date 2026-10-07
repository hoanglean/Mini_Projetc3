import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_expense_tracker/core/utils/vnd_formatter.dart';

void main() {
  group('VndFormatter Tests', () {
    test('Formats 0 VND correctly', () {
      expect(VndFormatter.format(0), '0 ₫');
    });

    test('Formats thousands with dot separator', () {
      expect(VndFormatter.format(50000), '50.000 ₫');
    });

    test('Formats millions with dot separators', () {
      expect(VndFormatter.format(1250000), '1.250.000 ₫');
    });

    test('Formats double values by rounding', () {
      expect(VndFormatter.format(49999.6), '50.000 ₫');
      expect(VndFormatter.formatDouble(12000.4), '12.000 ₫');
    });

    test('Compact format for below 1000', () {
      expect(VndFormatter.formatCompact(500), '500 ₫');
    });

    test('Compact format for thousands (K)', () {
      expect(VndFormatter.formatCompact(50000), '50K ₫');
      expect(VndFormatter.formatCompact(75500), '75.5K ₫');
    });

    test('Compact format for millions (M)', () {
      expect(VndFormatter.formatCompact(2000000), '2M ₫');
      expect(VndFormatter.formatCompact(1500000), '1.5M ₫');
    });
  });
}
