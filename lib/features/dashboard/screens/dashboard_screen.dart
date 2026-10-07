import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/vnd_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/error_widget.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../../transactions/screens/transaction_list_screen.dart';
import '../../capture/screens/camera_screen.dart';
import '../../charts/screens/charts_screen.dart';
import '../widgets/summary_card.dart';

/// Dashboard home screen with spending summary and recent transactions.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dashboardAsync = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChartsScreen()),
            ),
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Charts',
          ),
        ],
      ),
      body: dashboardAsync.when(
        data: (summary) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardProvider);
            ref.invalidate(transactionListProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary cards
              Row(
                children: [
                  Expanded(
                    child: SummaryCard(
                      title: 'This Month',
                      value: VndFormatter.format(summary.totalSpent),
                      icon: Icons.account_balance_wallet,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SummaryCard(
                      title: 'Transactions',
                      value: summary.transactionCount.toString(),
                      icon: Icons.receipt_long,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick actions
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.camera_alt,
                      label: 'Scan Receipt',
                      color: theme.colorScheme.primary,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CameraScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.list_alt,
                      label: 'All Transactions',
                      color: theme.colorScheme.tertiary,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const TransactionListScreen()),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Spending breakdown mini-chart
              if (summary.spendingByCategory.isNotEmpty) ...[
                Text(
                  'Spending Breakdown',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...summary.spendingByCategory.entries.map((entry) {
                  final total = summary.totalSpent > 0
                      ? entry.value / summary.totalSpent
                      : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _CategoryBar(
                      label: entry.key.label,
                      amount: VndFormatter.format(entry.value),
                      percentage: total,
                      color: entry.key.color,
                      icon: entry.key.icon,
                    ),
                  );
                }),
                const SizedBox(height: 24),
              ],

              // Recent transactions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Transactions',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const TransactionListScreen()),
                    ),
                    child: const Text('See All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (summary.recentTransactions.isEmpty)
                const EmptyStateWidget(
                  title: 'No transactions yet',
                  subtitle:
                      'Tap "Scan Receipt" to add your first expense',
                  icon: Icons.receipt_long_outlined,
                )
              else
                ...summary.recentTransactions.map((tx) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              tx.category.color.withAlpha(40),
                          child: Icon(tx.category.icon,
                              color: tx.category.color, size: 20),
                        ),
                        title: Text(
                          tx.merchant,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          AppDateUtils.formatRelative(tx.date),
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: Text(
                          VndFormatter.format(tx.amount),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )),
            ],
          ),
        ),
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(
          message: 'Failed to load dashboard: $e',
          onRetry: () => ref.invalidate(dashboardProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CameraScreen()),
        ),
        icon: const Icon(Icons.camera_alt),
        label: const Text('Scan'),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final String label;
  final String amount;
  final double percentage;
  final Color color;
  final IconData icon;

  const _CategoryBar({
    required this.label,
    required this.amount,
    required this.percentage,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(label, style: theme.textTheme.bodySmall),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: color.withAlpha(30),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(amount, style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
        )),
      ],
    );
  }
}
