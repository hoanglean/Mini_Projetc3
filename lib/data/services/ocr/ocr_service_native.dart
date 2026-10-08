import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'ocr_service.dart';

/// Native OCR service using Google ML Kit on-device Text Recognition.
class MlKitOcrService implements ReceiptOcrService {
  @override
  Future<List<String>> recognizeTextFromImage(dynamic image) async {
    if (image is! File) {
      throw ArgumentError('MlKitOcrService expects a File image');
    }

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFile(image);
      final recognized = await recognizer.processImage(inputImage);

      final lines = <String>[];
      for (final block in recognized.blocks) {
        for (final line in block.lines) {
          lines.add(line.text);
        }
      }
      return lines;
    } finally {
      await recognizer.close();
    }
  }
}

ReceiptOcrService createOcrService() => MlKitOcrService();
