import 'package:intl/intl.dart';

/// Date formatting utilities for the app.
typedef DateUtilsFormat = AppDateUtils;

class AppDateUtils {
  static final _displayFormat = DateFormat('dd/MM/yyyy');
  static final _displayWithTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final _dayOfWeekFormat = DateFormat('EEE');
  static final _monthDayFormat = DateFormat('dd/MM');
  static final _isoFormat = DateFormat('yyyy-MM-dd');

  /// Format for display: "07/10/2026"
  static String formatDisplay(DateTime date) => _displayFormat.format(date);

  /// Format with time: "07/10/2026 19:30"
  static String formatWithTime(DateTime date) =>
      _displayWithTimeFormat.format(date);

  /// Short weekday: "Mon", "Tue", etc.
  static String formatDayOfWeek(DateTime date) =>
      _dayOfWeekFormat.format(date);

  /// Day/month: "07/10"
  static String formatMonthDay(DateTime date) =>
      _monthDayFormat.format(date);

  /// ISO format for database: "2026-10-07"
  static String formatIso(DateTime date) => _isoFormat.format(date);

  /// Parse ISO date string.
  static DateTime parseIso(String date) => _isoFormat.parse(date);

  /// Get the start of the week (Monday) for a given date.
  static DateTime startOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - daysFromMonday);
  }

  /// Get all 7 days of the week starting from Monday.
  static List<DateTime> weekDays(DateTime anyDayInWeek) {
    final monday = startOfWeek(anyDayInWeek);
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  /// Format a relative date label: "Today", "Yesterday", or "DD/MM/YYYY"
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    return formatDisplay(date);
  }
}
