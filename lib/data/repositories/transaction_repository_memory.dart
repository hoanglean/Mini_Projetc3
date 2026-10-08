import '../models/transaction_model.dart';
import '../../domain/entities/category.dart';
import 'transaction_repository.dart';

/// In-memory implementation of [TransactionRepository] for Flutter Web demo.
class InMemoryTransactionRepository implements TransactionRepository {
  final List<TransactionModel> _items = [];

  InMemoryTransactionRepository({List<TransactionModel>? initialItems}) {
    if (initialItems != null) {
      _items.addAll(initialItems);
    }
  }

  // ─── CRUD ──────────────────────────────────────────────────────────

  @override
  Future<void> create(TransactionModel transaction) async {
    final idx = _items.indexWhere((t) => t.id == transaction.id);
    if (idx >= 0) {
      _items[idx] = transaction;
    } else {
      _items.add(transaction);
    }
  }

  @override
  Future<TransactionModel?> read(String id) async {
    try {
      return _items.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<int> update(TransactionModel transaction) async {
    final idx = _items.indexWhere((t) => t.id == transaction.id);
    if (idx >= 0) {
      _items[idx] = transaction;
      return 1;
    }
    return 0;
  }

  @override
  Future<int> delete(String id) async {
    final before = _items.length;
    _items.removeWhere((t) => t.id == id);
    return before - _items.length;
  }

  // ─── QUERIES ───────────────────────────────────────────────────────

  @override
  Future<List<TransactionModel>> list({
    DateTime? startDate,
    DateTime? endDate,
    Category? category,
    int? limit,
    int? offset,
  }) async {
    var filtered = _items.where((t) {
      if (startDate != null && t.date.isBefore(startDate)) return false;
      if (endDate != null && t.date.isAfter(endDate)) return false;
      if (category != null && t.category != category) return false;
      return true;
    }).toList();

    filtered.sort((a, b) => b.date.compareTo(a.date));

    if (offset != null && offset > 0) {
      if (offset >= filtered.length) return [];
      filtered = filtered.sublist(offset);
    }
    if (limit != null && limit > 0) {
      filtered = filtered.take(limit).toList();
    }
    return filtered;
  }

  @override
  Future<int> count() async {
    return _items.length;
  }

  @override
  Future<Map<Category, int>> sumByCategory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final filtered = _items.where((t) {
      if (startDate != null && t.date.isBefore(startDate)) return false;
      if (endDate != null && t.date.isAfter(endDate)) return false;
      return true;
    });

    final map = <Category, int>{};
    for (final t in filtered) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  }

  @override
  Future<Map<DateTime, int>> sumByDay({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final filtered = _items.where((t) {
      return !t.date.isBefore(startDate) && !t.date.isAfter(endDate);
    });

    final map = <DateTime, int>{};
    for (final t in filtered) {
      final day = DateTime(t.date.year, t.date.month, t.date.day);
      map[day] = (map[day] ?? 0) + t.amount;
    }
    return map;
  }

  @override
  Future<int> totalAmount({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final filtered = _items.where((t) {
      if (startDate != null && t.date.isBefore(startDate)) return false;
      if (endDate != null && t.date.isAfter(endDate)) return false;
      return true;
    });

    return filtered.fold<int>(0, (sum, t) => sum + t.amount);
  }
}

/// Generates realistic sample transactions across ALL categories
/// seeded on first web launch so dashboard & charts are fully populated.
List<TransactionModel> getInitialWebSampleTransactions() {
  final now = DateTime.now();
  // Monday of the current week
  final monday = now.subtract(Duration(days: now.weekday - 1));

  return [
    TransactionModel(
      id: 'web-sample-food-1',
      amount: 185000,
      merchant: 'WinMart Supermarket',
      date: DateTime(monday.year, monday.month, monday.day, 10, 30),
      category: Category.food,
      note: 'TH True Milk, bánh mì sandwich, trứng gà',
      createdAt: now,
      updatedAt: now,
    ),
    TransactionModel(
      id: 'web-sample-study-1',
      amount: 250000,
      merchant: 'Fahasa Bookstore',
      date: DateTime(monday.year, monday.month, monday.day + 1, 14, 15),
      category: Category.study,
      note: 'Sách Lập trình Flutter & Dart đa nền tảng',
      createdAt: now,
      updatedAt: now,
    ),
    TransactionModel(
      id: 'web-sample-travel-1',
      amount: 65000,
      merchant: 'Grab Transport',
      date: DateTime(monday.year, monday.month, monday.day + 2, 8, 45),
      category: Category.travel,
      note: 'Chuyến xe di chuyển đến trường ĐH',
      createdAt: now,
      updatedAt: now,
    ),
    TransactionModel(
      id: 'web-sample-gear-1',
      amount: 320000,
      merchant: 'Anker Official Store',
      date: DateTime(monday.year, monday.month, monday.day + 2, 19, 0),
      category: Category.gear,
      note: 'Củ sạc nhanh Type-C 65W GaN',
      createdAt: now,
      updatedAt: now,
    ),
    TransactionModel(
      id: 'web-sample-entertainment-1',
      amount: 220000,
      merchant: 'CGV Cinemas',
      date: DateTime(monday.year, monday.month, monday.day + 3, 20, 30),
      category: Category.entertainment,
      note: 'Vé xem phim cuối tuần kèm bắp rang',
      createdAt: now,
      updatedAt: now,
    ),
    TransactionModel(
      id: 'web-sample-food-2',
      amount: 65000,
      merchant: 'Highlands Coffee',
      date: DateTime(now.year, now.month, now.day, 9, 0),
      category: Category.food,
      note: 'Phin sữa đá lớn & Bánh mì gà xé',
      createdAt: now,
      updatedAt: now,
    ),
    TransactionModel(
      id: 'web-sample-other-1',
      amount: 85000,
      merchant: 'Circle K Convenience',
      date: DateTime(monday.year, monday.month, monday.day + 1, 16, 20),
      category: Category.other,
      note: 'Đồ dùng cá nhân & nước khoáng',
      createdAt: now,
      updatedAt: now,
    ),
  ];
}

TransactionRepository createRepository() => InMemoryTransactionRepository(
      initialItems: getInitialWebSampleTransactions(),
    );
