import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Data for a single bar in the weekly bar chart.
class BarData {
  final String label; // Day label (Mon, Tue, ...)
  final double value;
  final DateTime date;

  const BarData({
    required this.label,
    required this.value,
    required this.date,
  });
}

/// Custom painter for an animated weekly spending bar chart.
///
/// Features:
/// - Bars grow with animation
/// - Rounded top corners
/// - Y-axis grid lines and labels
/// - X-axis weekday labels
/// - Highlighted bar on tap with value tooltip
class BarChartPainter extends CustomPainter {
  final List<BarData> bars;
  final double animationValue; // 0.0 → 1.0
  final int? highlightedIndex;
  final Color barColor;
  final Color highlightColor;
  final Color gridColor;
  final Color textColor;

  BarChartPainter({
    required this.bars,
    required this.animationValue,
    this.highlightedIndex,
    this.barColor = const Color(0xFF6C63FF),
    this.highlightColor = const Color(0xFF00D4AA),
    this.gridColor = const Color(0x33888888),
    this.textColor = const Color(0xFF888888),
  });

  static const double _bottomPadding = 32;
  static const double _topPadding = 24;
  static const double _leftPadding = 56;
  static const double _rightPadding = 16;

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;

    final chartWidth = size.width - _leftPadding - _rightPadding;
    final chartHeight = size.height - _bottomPadding - _topPadding;

    final maxValue = bars.fold<double>(
        0, (max, b) => b.value > max ? b.value : max);
    final double yMax = maxValue > 0 ? _roundUpToNice(maxValue) : 100000.0;

    // Draw grid lines and Y-axis labels
    _drawGrid(canvas, size, chartHeight, yMax);

    // Draw bars
    final barCount = bars.length;
    final barWidth = (chartWidth / barCount) * 0.55;
    final barSpacing = chartWidth / barCount;

    for (int i = 0; i < barCount; i++) {
      final bar = bars[i];
      final isHighlighted = i == highlightedIndex;

      final barHeight =
          (bar.value / yMax) * chartHeight * animationValue;
      final x = _leftPadding + i * barSpacing + (barSpacing - barWidth) / 2;
      final y = _topPadding + chartHeight - barHeight;

      // Bar gradient
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      );

      // Shadow for highlighted bar
      if (isHighlighted && barHeight > 0) {
        final shadowPaint = Paint()
          ..color = highlightColor.withAlpha(50)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(x - 2, y - 2, barWidth + 4, barHeight + 4),
            topLeft: const Radius.circular(8),
            topRight: const Radius.circular(8),
          ),
          shadowPaint,
        );
      }

      final barPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isHighlighted
              ? [highlightColor, highlightColor.withAlpha(180)]
              : [barColor, barColor.withAlpha(160)],
        ).createShader(Rect.fromLTWH(x, y, barWidth, barHeight));

      if (barHeight > 0) {
        canvas.drawRRect(rect, barPaint);
      }

      // X-axis label
      final labelPainter = TextPainter(
        text: TextSpan(
          text: bar.label,
          style: TextStyle(
            color: isHighlighted ? highlightColor : textColor,
            fontSize: 11,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      labelPainter.paint(
        canvas,
        Offset(
          x + barWidth / 2 - labelPainter.width / 2,
          _topPadding + chartHeight + 8,
        ),
      );

      // Tooltip for highlighted bar
      if (isHighlighted && barHeight > 0) {
        _drawTooltip(canvas, bar.value, x + barWidth / 2, y - 8);
      }
    }
  }

  void _drawGrid(
      Canvas canvas, Size size, double chartHeight, double yMax) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    const gridLines = 4;
    for (int i = 0; i <= gridLines; i++) {
      final y =
          _topPadding + chartHeight - (i / gridLines) * chartHeight;

      // Grid line
      canvas.drawLine(
        Offset(_leftPadding, y),
        Offset(size.width - _rightPadding, y),
        gridPaint,
      );

      // Y-axis label
      final value = (yMax * i / gridLines).round();
      final label = _formatCompact(value);
      final labelPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(color: textColor, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      labelPainter.paint(
        canvas,
        Offset(_leftPadding - labelPainter.width - 8, y - labelPainter.height / 2),
      );
    }
  }

  void _drawTooltip(Canvas canvas, double value, double x, double y) {
    final text = _formatCompact(value.round());
    final painter = TextPainter(
      text: TextSpan(
        text: '$text ₫',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final bgRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(x, y - 12),
        width: painter.width + 16,
        height: painter.height + 8,
      ),
      const Radius.circular(6),
    );

    canvas.drawRRect(bgRect, Paint()..color = const Color(0xCC333333));
    painter.paint(canvas, Offset(x - painter.width / 2, y - 12 - painter.height / 2));

    // Arrow
    final arrowPath = Path()
      ..moveTo(x - 4, y - 4)
      ..lineTo(x + 4, y - 4)
      ..lineTo(x, y + 2)
      ..close();
    canvas.drawPath(arrowPath, Paint()..color = const Color(0xCC333333));
  }

  String _formatCompact(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toString();
  }

  double _roundUpToNice(double value) {
    if (value <= 0) return 100000;
    final magnitude = math.pow(10, (math.log(value) / math.ln10).floor());
    final normalized = value / magnitude;
    double nice;
    if (normalized <= 1) {
      nice = 1;
    } else if (normalized <= 2) {
      nice = 2;
    } else if (normalized <= 5) {
      nice = 5;
    } else {
      nice = 10;
    }
    return (nice * magnitude).toDouble();
  }

  @override
  bool shouldRepaint(covariant BarChartPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.highlightedIndex != highlightedIndex ||
        oldDelegate.bars != bars;
  }

  /// Hit test: which bar index is at the given position?
  static int? findBarAtPosition(
    Offset position,
    Size size,
    List<BarData> bars,
  ) {
    if (bars.isEmpty) return null;

    final chartWidth = size.width - _leftPadding - _rightPadding;
    final barSpacing = chartWidth / bars.length;

    final relativeX = position.dx - _leftPadding;
    if (relativeX < 0 || relativeX > chartWidth) return null;

    final index = (relativeX / barSpacing).floor();
    if (index >= 0 && index < bars.length) return index;
    return null;
  }
}
