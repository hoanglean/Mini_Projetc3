import 'ocr_service_factory.dart';

/// Abstract service for optical character recognition on receipts.
abstract class ReceiptOcrService {
  factory ReceiptOcrService() => buildDefaultOcrService();

  /// Extract text lines from an image or data source.
  Future<List<String>> recognizeTextFromImage(dynamic image);
}
