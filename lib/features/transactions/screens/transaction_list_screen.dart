import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/category.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../providers/transaction_provider.dart';
import '../widgets/transaction_tile.dart';
import 'transaction_detail_screen.dart';
import '../../capture/screens/camera_screen.dart';

/// Screen displaying the full transaction history with search, category filtering,
/// and swipe-to-delete with undo.
class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() =>
      _TransactionListScreenState();
}

class _TransactionListScreenState
    extends ConsumerState<TransactionListScreen> {
  Category? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transactionsAsync = ref.watch(transactionListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Transactions'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CameraScreen()),
        ),
        icon: const Icon(Icons.document_scanner),
        label: const Text('Scan Receipt'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search merchant...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),

          // Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: const Text('All'),
                    selected: _selectedCategory == null,
                    onSelected: (_) =>
                        setState(() => _selectedCategory = null),
                  ),
                ),
                ...Category.values.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      avatar: Icon(
                        cat.icon,
                        size: 16,
                        color: isSelected
                            ? theme.colorScheme.onPrimaryContainer
                            : cat.color,
                      ),
                      label: Text(cat.displayName),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = selected ? cat : null;
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const Divider(height: 1),

          // Transaction list with swipe to delete
          Expanded(
            child: transactionsAsync.when(
              loading: () => const LoadingWidget(message: 'Loading expenses...'),
              error: (err, stack) => AppErrorWidget(
                message: err.toString(),
                onRetry: () =>
                    ref.read(transactionListProvider.notifier).refresh(),
              ),
              data: (transactions) {
                // Filter by category and search query
                var filtered = transactions;
                if (_selectedCategory != null) {
                  filtered = filtered
                      .where((t) => t.category == _selectedCategory)
                      .toList();
                }
                if (_searchQuery.isNotEmpty) {
                  filtered = filtered
                      .where((t) => t.merchant
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()))
                      .toList();
                }

                if (filtered.isEmpty) {
                  return EmptyStateWidget(
                    title: _searchQuery.isNotEmpty || _selectedCategory != null
                        ? 'No matching expenses'
                        : 'No expenses saved yet',
                    subtitle: _searchQuery.isNotEmpty || _selectedCategory != null
                        ? 'Try adjusting your search or category filter'
                        : 'Scan a receipt or bill to automatically track your expenses',
                    icon: Icons.receipt_long_outlined,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final tx = filtered[index];
                    return Dismissible(
                      key: Key('tx_${tx.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: theme.colorScheme.error,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(Icons.delete, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Delete',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        return true;
                      },
                      onDismissed: (direction) async {
                        final deletedTx = tx;
                        await ref
                            .read(transactionListProvider.notifier)
                            .deleteTransaction(tx.id);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Deleted expense from ${deletedTx.merchant}'),
                              behavior: SnackBarBehavior.floating,
                              action: SnackBarAction(
                                label: 'Undo',
                                onPressed: () {
                                  ref
                                      .read(transactionListProvider.notifier)
                                      .addTransaction(deletedTx);
                                },
                              ),
                            ),
                          );
                        }
                      },
                      child: TransactionTile(
                        transaction: tx,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                TransactionDetailScreen(transaction: tx),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
