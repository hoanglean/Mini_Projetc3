import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../painters/donut_chart_painter.dart';
import '../painters/bar_chart_painter.dart';
import '../widgets/donut_chart.dart';
import '../widgets/bar_chart.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../../../core/utils/date_utils.dart';

/// Full charts screen with donut (spending by category) and
/// weekly bar chart.
class ChartsScreen extends ConsumerWidget {
  const ChartsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spending Charts')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(categoryChartDataProvider);
          ref.invalidate(weeklyChartDataProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              _CategoryDonutSection(),
              SizedBox(height: 32),
              _WeeklyBarSection(),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryDonutSection extends ConsumerWidget {
  const _CategoryDonutSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categoryData = ref.watch(categoryChartDataProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spending by Category',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'This month',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            categoryData.when(
              data: (data) {
                final segments = data.entries
                    .where((e) => e.value > 0)
                    .map((e) => DonutSegment(
                          label: e.key.label,
                          value: e.value.toDouble(),
                          color: e.key.color,
                        ))
                    .toList();
                return Center(child: DonutChart(segments: segments));
              },
              loading: () => const SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SizedBox(
                height: 220,
                child: Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyBarSection extends ConsumerWidget {
  const _WeeklyBarSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final weeklyData = ref.watch(weeklyChartDataProvider);
    final selectedDate = ref.watch(selectedWeekProvider);

    // Compute the Monday of the selected week
    final weekday = selectedDate.weekday;
    final monday = selectedDate.subtract(Duration(days: weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final weekLabel =
        '${AppDateUtils.formatMonthDay(monday)} - ${AppDateUtils.formatMonthDay(sunday)}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Spending',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            weeklyData.when(
              data: (data) {
                final days = AppDateUtils.weekDays(selectedDate);
                final bars = days.map((day) {
                  final dayStart = DateTime(day.year, day.month, day.day);
                  final amount = data[dayStart] ?? 0;
                  return BarData(
                    label: AppDateUtils.formatDayOfWeek(day),
                    value: amount.toDouble(),
                    date: day,
                  );
                }).toList();

                return WeeklyBarChart(
                  bars: bars,
                  weekLabel: weekLabel,
                  onPreviousWeek: () {
                    ref.read(selectedWeekProvider.notifier).state =
                        selectedDate.subtract(const Duration(days: 7));
                  },
                  onNextWeek: () {
                    final next =
                        selectedDate.add(const Duration(days: 7));
                    if (next.isBefore(
                        DateTime.now().add(const Duration(days: 1)))) {
                      ref.read(selectedWeekProvider.notifier).state = next;
                    }
                  },
                );
              },
              loading: () => const SizedBox(
                height: 280,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SizedBox(
                height: 280,
                child: Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
