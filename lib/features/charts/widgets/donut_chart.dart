import 'package:flutter/material.dart';
import '../painters/donut_chart_painter.dart';
import '../../../core/utils/vnd_formatter.dart';

/// Animated donut chart widget with tap-to-highlight segments and legend.
class DonutChart extends StatefulWidget {
  final List<DonutSegment> segments;
  final double size;

  const DonutChart({
    super.key,
    required this.segments,
    this.size = 220,
  });

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int? _highlightedIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant DonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.segments != widget.segments) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _total =>
      widget.segments.fold<double>(0, (sum, s) => sum + s.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.segments.isEmpty) {
      return SizedBox(
        height: widget.size,
        child: Center(
          child: Text(
            'No spending data',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Chart
        GestureDetector(
          onTapDown: (details) => _onTap(details.localPosition),
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, _) {
                return SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: Size(widget.size, widget.size),
                        painter: DonutChartPainter(
                          segments: widget.segments,
                          animationValue: _animation.value,
                          highlightedIndex: _highlightedIndex,
                        ),
                      ),
                      // Center label
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Total',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            VndFormatter.formatCompact(_total.round()),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_highlightedIndex != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.segments[_highlightedIndex!].label,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: widget
                                    .segments[_highlightedIndex!].color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: widget.segments.map((seg) {
            final pct = (_total > 0)
                ? (seg.value / _total * 100).toStringAsFixed(1)
                : '0.0';
            return GestureDetector(
              onTap: () {
                final idx = widget.segments.indexOf(seg);
                setState(() {
                  _highlightedIndex =
                      _highlightedIndex == idx ? null : idx;
                });
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: seg.color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${seg.label} ($pct%)',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _onTap(Offset position) {
    final index = DonutChartPainter.findSegmentAtPosition(
      position,
      Size(widget.size, widget.size),
      widget.segments,
      32.0,
    );
    setState(() {
      _highlightedIndex = _highlightedIndex == index ? null : index;
    });
  }
}
