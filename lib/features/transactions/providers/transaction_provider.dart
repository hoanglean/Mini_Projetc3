import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../data/services/image_storage_service.dart';
import '../../../domain/entities/category.dart';

// ─── Repository & Service Providers ─────────────────────────────────

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

final imageStorageServiceProvider = Provider<ImageStorageService>((ref) {
  return ImageStorageService();
});

// ─── Transaction List State ─────────────────────────────────────────

final transactionListProvider =
    AsyncNotifierProvider<TransactionListNotifier, List<TransactionModel>>(
  TransactionListNotifier.new,
);

class TransactionListNotifier
    extends AsyncNotifier<List<TransactionModel>> {
  @override
  Future<List<TransactionModel>> build() async {
    return _fetchTransactions();
  }

  Future<List<TransactionModel>> _fetchTransactions() async {
    final repo = ref.read(transactionRepositoryProvider);
    return await repo.list();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchTransactions());
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    final repo = ref.read(transactionRepositoryProvider);
    await repo.create(transaction);
    await refresh();
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    final repo = ref.read(transactionRepositoryProvider);
    await repo.update(transaction);
    await refresh();
  }

  Future<void> deleteTransaction(String id, {String? imagePath, String? thumbnailPath}) async {
    final repo = ref.read(transactionRepositoryProvider);
    final imageService = ref.read(imageStorageServiceProvider);

    await repo.delete(id);
    await imageService.deleteImages(imagePath, thumbnailPath);
    await refresh();
  }
}

// ─── Dashboard Summary State ────────────────────────────────────────

class DashboardSummary {
  final int totalSpent;
  final int transactionCount;
  final Map<Category, int> spendingByCategory;
  final List<TransactionModel> recentTransactions;

  const DashboardSummary({
    this.totalSpent = 0,
    this.transactionCount = 0,
    this.spendingByCategory = const {},
    this.recentTransactions = const [],
  });
}

final dashboardProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardSummary>(
  DashboardNotifier.new,
);

class DashboardNotifier extends AsyncNotifier<DashboardSummary> {
  @override
  Future<DashboardSummary> build() async {
    // Re-compute whenever the transaction list changes
    ref.watch(transactionListProvider);
    return _computeSummary();
  }

  Future<DashboardSummary> _computeSummary() async {
    final repo = ref.read(transactionRepositoryProvider);

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final total = await repo.totalAmount(
        startDate: startOfMonth, endDate: endOfMonth);
    final count = await repo.count();
    final byCategory = await repo.sumByCategory(
        startDate: startOfMonth, endDate: endOfMonth);
    final recent = await repo.list(limit: 5);

    return DashboardSummary(
      totalSpent: total,
      transactionCount: count,
      spendingByCategory: byCategory,
      recentTransactions: recent,
    );
  }
}

// ─── Chart Data Providers ───────────────────────────────────────────

final selectedWeekProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

final weeklyChartDataProvider =
    FutureProvider<Map<DateTime, int>>((ref) async {
  ref.watch(transactionListProvider);
  final selectedDate = ref.watch(selectedWeekProvider);
  final repo = ref.read(transactionRepositoryProvider);

  // Get Monday of the selected week
  final weekday = selectedDate.weekday;
  final monday = selectedDate.subtract(Duration(days: weekday - 1));
  final startOfWeek = DateTime(monday.year, monday.month, monday.day);
  final endOfWeek = startOfWeek
      .add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

  return await repo.sumByDay(startDate: startOfWeek, endDate: endOfWeek);
});

final categoryChartDataProvider =
    FutureProvider<Map<Category, int>>((ref) async {
  ref.watch(transactionListProvider);
  final repo = ref.read(transactionRepositoryProvider);
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  return await repo.sumByCategory(
      startDate: startOfMonth, endDate: endOfMonth);
});

