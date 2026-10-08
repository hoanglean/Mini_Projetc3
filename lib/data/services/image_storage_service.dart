import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;
import '../../core/constants/app_constants.dart';

/// Service for storing and managing receipt images and thumbnails.
class ImageStorageService {
  /// Save a receipt image and generate a thumbnail.
  ///
  /// Returns a record of (imagePath, thumbnailPath).
  Future<({String imagePath, String thumbnailPath})> saveReceiptImage(
    File imageFile,
    String transactionId,
  ) async {
    // On web, skip local file persistence & thumbnail generation
    if (kIsWeb) {
      return (imagePath: '', thumbnailPath: '');
    }

    final appDir = await getApplicationDocumentsDirectory();

    // Create directories
    final imageDir =
        Directory(p.join(appDir.path, AppConstants.imageDir));
    final thumbDir =
        Directory(p.join(appDir.path, AppConstants.thumbnailDir));
    if (!await imageDir.exists()) await imageDir.create(recursive: true);
    if (!await thumbDir.exists()) await thumbDir.create(recursive: true);

    // Copy the original image
    final ext = p.extension(imageFile.path);
    final imagePath = p.join(imageDir.path, '$transactionId$ext');
    await imageFile.copy(imagePath);

    // Generate thumbnail (max 300px width)
    final thumbPath = p.join(thumbDir.path, '${transactionId}_thumb.jpg');
    await _generateThumbnail(imageFile.path, thumbPath);

    return (imagePath: imagePath, thumbnailPath: thumbPath);
  }

  /// Generate a downscaled thumbnail.
  Future<void> _generateThumbnail(
      String sourcePath, String destPath) async {
    try {
      final bytes = await File(sourcePath).readAsBytes();
      final original = img.decodeImage(bytes);
      if (original == null) return;

      final thumbnail = img.copyResize(
        original,
        width: AppConstants.thumbnailMaxWidth,
      );

      final jpegBytes = img.encodeJpg(thumbnail, quality: 80);
      await File(destPath).writeAsBytes(jpegBytes);
    } catch (e) {
      // Silently fail — thumbnails are optional
      // ignore: avoid_print
      print('Thumbnail generation failed: $e');
    }
  }

  /// Delete image and thumbnail files for a transaction.
  Future<void> deleteImages(String? imagePath, String? thumbnailPath) async {
    if (kIsWeb) return;
    if (imagePath != null) {
      final file = File(imagePath);
      if (await file.exists()) await file.delete();
    }
    if (thumbnailPath != null) {
      final file = File(thumbnailPath);
      if (await file.exists()) await file.delete();
    }
  }

  /// Load a thumbnail, returning null if the file doesn't exist.
  Future<Uint8List?> loadThumbnail(String? thumbnailPath) async {
    if (kIsWeb || thumbnailPath == null) return null;
    final file = File(thumbnailPath);
    if (!await file.exists()) return null;
    return await file.readAsBytes();
  }

  /// Crop an image to the specified rectangle (in image coordinates).
  Future<File> cropImage(
    File sourceFile, {
    required int x,
    required int y,
    required int width,
    required int height,
  }) async {
    if (kIsWeb) return sourceFile;
    final bytes = await sourceFile.readAsBytes();
    final original = img.decodeImage(bytes);
    if (original == null) return sourceFile;

    // Clamp bounds
    final cx = x.clamp(0, original.width - 1);
    final cy = y.clamp(0, original.height - 1);
    final cw = width.clamp(1, original.width - cx);
    final ch = height.clamp(1, original.height - cy);

    final cropped = img.copyCrop(
      original,
      x: cx,
      y: cy,
      width: cw,
      height: ch,
    );

    final tempDir = await getTemporaryDirectory();
    final croppedPath =
        p.join(tempDir.path, 'cropped_${DateTime.now().millisecondsSinceEpoch}.jpg');
    final jpegBytes = img.encodeJpg(cropped, quality: 90);
    final croppedFile = File(croppedPath);
    await croppedFile.writeAsBytes(jpegBytes);
    return croppedFile;
  }
}
