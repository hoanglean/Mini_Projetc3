import 'package:flutter/material.dart';
import '../painters/bar_chart_painter.dart';

/// Animated bar chart widget with week navigation and tap-to-highlight.
class WeeklyBarChart extends StatefulWidget {
  final List<BarData> bars;
  final VoidCallback? onPreviousWeek;
  final VoidCallback? onNextWeek;
  final String weekLabel;

  const WeeklyBarChart({
    super.key,
    required this.bars,
    this.onPreviousWeek,
    this.onNextWeek,
    this.weekLabel = '',
  });

  @override
  State<WeeklyBarChart> createState() => _WeeklyBarChartState();
}

class _WeeklyBarChartState extends State<WeeklyBarChart>
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
  void didUpdateWidget(covariant WeeklyBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bars != widget.bars) {
      _highlightedIndex = null;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Week navigation
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: widget.onPreviousWeek,
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Previous week',
            ),
            Text(
              widget.weekLabel,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              onPressed: widget.onNextWeek,
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Next week',
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Chart
        SizedBox(
          height: 220,
          child: widget.bars.isEmpty ||
                  widget.bars.every((b) => b.value == 0)
              ? Center(
                  child: Text(
                    'No spending this week',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : GestureDetector(
                  onTapDown: (details) => _onTap(details.localPosition),
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _animation,
                      builder: (context, _) {
                        return CustomPaint(
                          size: const Size(double.infinity, 220),
                          painter: BarChartPainter(
                            bars: widget.bars,
                            animationValue: _animation.value,
                            highlightedIndex: _highlightedIndex,
                            barColor: theme.colorScheme.primary,
                            highlightColor: theme.colorScheme.secondary,
                            gridColor:
                                theme.colorScheme.outlineVariant.withAlpha(80),
                            textColor: theme.colorScheme.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  void _onTap(Offset position) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final index = BarChartPainter.findBarAtPosition(
      position,
      Size(renderBox.size.width, 220),
      widget.bars,
    );
    setState(() {
      _highlightedIndex = _highlightedIndex == index ? null : index;
    });
  }
}
