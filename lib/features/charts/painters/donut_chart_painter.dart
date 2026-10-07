import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Data for a single donut chart segment.
class DonutSegment {
  final String label;
  final double value;
  final Color color;

  const DonutSegment({
    required this.label,
    required this.value,
    required this.color,
  });
}

/// Custom painter for an animated donut/pie chart.
///
/// Supports:
/// - Sweep animation on load
/// - Highlighted segment on tap
/// - Center label showing total
class DonutChartPainter extends CustomPainter {
  final List<DonutSegment> segments;
  final double animationValue; // 0.0 → 1.0
  final int? highlightedIndex;
  final double strokeWidth;

  DonutChartPainter({
    required this.segments,
    required this.animationValue,
    this.highlightedIndex,
    this.strokeWidth = 32.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - strokeWidth / 2 - 8;

    final total = segments.fold<double>(0, (sum, s) => sum + s.value);
    if (total <= 0) return;

    double startAngle = -math.pi / 2; // Start from top
    final maxSweep = 2 * math.pi * animationValue;

    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final sweepAngle = (segment.value / total) * 2 * math.pi;

      // Clamp to animation progress
      final animatedSweep = math.min(
          sweepAngle, math.max(0.0, maxSweep - (startAngle + math.pi / 2)));
      if (animatedSweep <= 0) break;

      final isHighlighted = i == highlightedIndex;
      final actualStroke = isHighlighted ? strokeWidth + 8 : strokeWidth;
      final actualRadius = isHighlighted ? radius + 4 : radius;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = actualStroke
        ..strokeCap = StrokeCap.butt
        ..color = isHighlighted ? segment.color : segment.color.withAlpha(220);

      // Draw shadow for highlighted segment
      if (isHighlighted) {
        final shadowPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = actualStroke + 4
          ..strokeCap = StrokeCap.butt
          ..color = segment.color.withAlpha(60)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: actualRadius),
          startAngle,
          animatedSweep,
          false,
          shadowPaint,
        );
      }

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: actualRadius),
        startAngle,
        animatedSweep,
        false,
        paint,
      );

      // Draw gap between segments
      if (segments.length > 1) {
        final gapPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = Colors.white.withAlpha(40);
        
        final gapAngle = startAngle;
        final innerR = actualRadius - actualStroke / 2;
        final outerR = actualRadius + actualStroke / 2;
        canvas.drawLine(
          Offset(center.dx + innerR * math.cos(gapAngle),
              center.dy + innerR * math.sin(gapAngle)),
          Offset(center.dx + outerR * math.cos(gapAngle),
              center.dy + outerR * math.sin(gapAngle)),
          gapPaint,
        );
      }

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.highlightedIndex != highlightedIndex ||
        oldDelegate.segments != segments;
  }

  /// Hit test: which segment index is at the given position?
  static int? findSegmentAtPosition(
    Offset position,
    Size size,
    List<DonutSegment> segments,
    double strokeWidth,
  ) {
    if (segments.isEmpty) return null;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - strokeWidth / 2 - 8;
    final dx = position.dx - center.dx;
    final dy = position.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    // Check if within the donut ring
    if (distance < radius - strokeWidth / 2 ||
        distance > radius + strokeWidth / 2) {
      return null;
    }

    // Calculate angle
    double angle = math.atan2(dy, dx);
    if (angle < -math.pi / 2) angle += 2 * math.pi;
    angle += math.pi / 2; // Adjust for starting from top
    if (angle > 2 * math.pi) angle -= 2 * math.pi;

    final total = segments.fold<double>(0, (sum, s) => sum + s.value);
    double cumAngle = 0;
    for (int i = 0; i < segments.length; i++) {
      cumAngle += (segments[i].value / total) * 2 * math.pi;
      if (angle <= cumAngle) return i;
    }
    return null;
  }
}
