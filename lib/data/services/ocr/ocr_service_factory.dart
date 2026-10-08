import 'package:flutter/foundation.dart';
import 'ocr_service.dart';
import 'ocr_service_web.dart' as web_impl;
import 'ocr_service_native.dart'
    if (dart.library.js_interop) 'ocr_service_web.dart'
    if (dart.library.html) 'ocr_service_web.dart' as impl;

/// Factory function to supply the appropriate [ReceiptOcrService] based on platform.
ReceiptOcrService buildDefaultOcrService() {
  if (kIsWeb) {
    return const web_impl.MockWebOcrService();
  }
  return impl.createOcrService();
}
