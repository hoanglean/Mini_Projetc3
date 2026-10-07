import 'package:flutter/material.dart';

/// Camera overlay with dimmed borders, crop guide rectangle, and hint text.
class CameraOverlay extends StatelessWidget {
  const CameraOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        // Crop area: centered, with padding
        final cropWidth = width - 48;
        final cropHeight = cropWidth / 0.65; // ~receipt aspect ratio
        final cropLeft = (width - cropWidth) / 2;
        final cropTop = (height - cropHeight) / 2 - 20;

        return Stack(
          children: [
            // Dimmed overlay outside crop area
            CustomPaint(
              size: Size(width, height),
              painter: _OverlayPainter(
                cropRect: Rect.fromLTWH(
                    cropLeft, cropTop, cropWidth, cropHeight),
              ),
            ),

            // Corner guides
            ..._buildCornerGuides(
                cropLeft, cropTop, cropWidth, cropHeight),

            // Hint text
            Positioned(
              left: cropLeft,
              right: width - cropLeft - cropWidth,
              top: cropTop + cropHeight + 16,
              child: Text(
                'Align receipt inside the frame',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withAlpha(200),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildCornerGuides(
      double left, double top, double width, double height) {
    const lineLength = 28.0;
    const lineWidth = 3.0;
    const color = Colors.white;

    return [
      // Top-left
      Positioned(
        left: left - 1,
        top: top - 1,
        child: const _CornerGuide(
          lineLength: lineLength,
          lineWidth: lineWidth,
          color: color,
          corner: _Corner.topLeft,
        ),
      ),
      // Top-right
      Positioned(
        left: left + width - lineLength + 1,
        top: top - 1,
        child: const _CornerGuide(
          lineLength: lineLength,
          lineWidth: lineWidth,
          color: color,
          corner: _Corner.topRight,
        ),
      ),
      // Bottom-left
      Positioned(
        left: left - 1,
        top: top + height - lineLength + 1,
        child: const _CornerGuide(
          lineLength: lineLength,
          lineWidth: lineWidth,
          color: color,
          corner: _Corner.bottomLeft,
        ),
      ),
      // Bottom-right
      Positioned(
        left: left + width - lineLength + 1,
        top: top + height - lineLength + 1,
        child: const _CornerGuide(
          lineLength: lineLength,
          lineWidth: lineWidth,
          color: color,
          corner: _Corner.bottomRight,
        ),
      ),
    ];
  }
}

enum _Corner { topLeft, topRight, bottomLeft, bottomRight }

class _CornerGuide extends StatelessWidget {
  final double lineLength;
  final double lineWidth;
  final Color color;
  final _Corner corner;

  const _CornerGuide({
    required this.lineLength,
    required this.lineWidth,
    required this.color,
    required this.corner,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: lineLength,
      height: lineLength,
      child: CustomPaint(
        painter: _CornerPainter(
          lineWidth: lineWidth,
          color: color,
          corner: corner,
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final double lineWidth;
  final Color color;
  final _Corner corner;

  _CornerPainter({
    required this.lineWidth,
    required this.color,
    required this.corner,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    switch (corner) {
      case _Corner.topLeft:
        canvas.drawLine(Offset(0, 0), Offset(size.width, 0), paint);
        canvas.drawLine(Offset(0, 0), Offset(0, size.height), paint);
        break;
      case _Corner.topRight:
        canvas.drawLine(Offset(0, 0), Offset(size.width, 0), paint);
        canvas.drawLine(
            Offset(size.width, 0), Offset(size.width, size.height), paint);
        break;
      case _Corner.bottomLeft:
        canvas.drawLine(
            Offset(0, size.height), Offset(size.width, size.height), paint);
        canvas.drawLine(Offset(0, 0), Offset(0, size.height), paint);
        break;
      case _Corner.bottomRight:
        canvas.drawLine(
            Offset(0, size.height), Offset(size.width, size.height), paint);
        canvas.drawLine(
            Offset(size.width, 0), Offset(size.width, size.height), paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) => false;
}

class _OverlayPainter extends CustomPainter {
  final Rect cropRect;

  _OverlayPainter({required this.cropRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withAlpha(150);

    // Draw dimmed regions
    // Top
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, cropRect.top),
      paint,
    );
    // Bottom
    canvas.drawRect(
      Rect.fromLTWH(
          0, cropRect.bottom, size.width, size.height - cropRect.bottom),
      paint,
    );
    // Left
    canvas.drawRect(
      Rect.fromLTWH(
          0, cropRect.top, cropRect.left, cropRect.height),
      paint,
    );
    // Right
    canvas.drawRect(
      Rect.fromLTWH(cropRect.right, cropRect.top,
          size.width - cropRect.right, cropRect.height),
      paint,
    );

    // Border
    final borderPaint = Paint()
      ..color = Colors.white.withAlpha(80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(cropRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter oldDelegate) {
    return oldDelegate.cropRect != cropRect;
  }
}

/// Helper to get the crop rect from the overlay layout.
class CameraOverlayHelper {
  /// Calculate crop rectangle given the screen size.
  static Rect getCropRect(Size screenSize) {
    final width = screenSize.width - 48;
    final height = width / 0.65;
    final left = (screenSize.width - width) / 2;
    final top = (screenSize.height - height) / 2 - 20;
    return Rect.fromLTWH(left, top, width, height);
  }
}
