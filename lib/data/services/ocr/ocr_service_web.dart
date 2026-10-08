import 'ocr_service.dart';
import 'sample_receipts.dart';

/// Mock OCR service for Flutter Web demo without ML Kit.
class MockWebOcrService implements ReceiptOcrService {
  final String? customText;

  const MockWebOcrService({this.customText});

  @override
  Future<List<String>> recognizeTextFromImage(dynamic image) async {
    // If custom text is set, use it; otherwise fallback to WinMart sample
    final text = (customText != null && customText!.trim().isNotEmpty)
        ? customText!
        : SampleReceipts.winMart;

    return text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }
}

ReceiptOcrService createOcrService() => const MockWebOcrService();
