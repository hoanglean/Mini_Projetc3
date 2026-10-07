import 'package:intl/intl.dart';

/// Format VND currency values for display.
class VndFormatter {
  static final _formatter = NumberFormat('#,###', 'vi_VN');

  /// Format a numeric VND amount (int or double), e.g. 150000 → "150.000 ₫"
  static String format(num amount) {
    final rounded = amount.round();
    final formatted = _formatter.format(rounded).replaceAll(',', '.');
    return '$formatted ₫';
  }

  /// Format a double amount (rounds to nearest integer first).
  static String formatDouble(double amount) {
    return format(amount);
  }

  /// Compact format for chart labels, e.g. 1500000 → "1.5M ₫"
  static String formatCompact(num amount) {
    final val = amount.round();
    if (val >= 1000000) {
      final millions = val / 1000000;
      return '${millions.toStringAsFixed(millions.truncateToDouble() == millions ? 0 : 1)}M ₫';
    }
    if (val >= 1000) {
      final thousands = val / 1000;
      return '${thousands.toStringAsFixed(thousands.truncateToDouble() == thousands ? 0 : 1)}K ₫';
    }
    return '$val ₫';
  }
}
