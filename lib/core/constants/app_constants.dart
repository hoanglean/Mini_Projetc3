/// App-wide constants.
class AppConstants {
  AppConstants._();

  static const String appName = 'OCR Expense Tracker';
  static const String appVersion = '1.0.0';

  // Database
  static const String dbName = 'expense_tracker.db';
  static const int dbVersion = 1;

  // Image storage
  static const String imageDir = 'receipts';
  static const String thumbnailDir = 'thumbnails';
  static const int thumbnailMaxWidth = 300;

  // Camera overlay
  static const double overlayAspectRatio = 0.65; // width/height
  static const double overlayHorizontalPadding = 24.0;

  // Animation durations
  static const Duration chartAnimationDuration = Duration(milliseconds: 800);
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
}
