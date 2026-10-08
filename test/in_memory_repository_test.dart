import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_expense_tracker/data/repositories/transaction_repository_memory.dart';
import 'package:ocr_expense_tracker/data/models/transaction_model.dart';
import 'package:ocr_expense_tracker/domain/entities/category.dart';

void main() {
  group('InMemoryTransactionRepository Tests', () {
    test('Initializes with seeded sample transactions across all categories', () async {
      final samples = getInitialWebSampleTransactions();
      final repo = InMemoryTransactionRepository(initialItems: samples);

      expect(await repo.count(), samples.length);
      final categories = samples.map((s) => s.category).toSet();
      expect(categories.length, equals(Category.values.length)); // All categories covered
    });

    test('CRUD operations work in memory', () async {
      final repo = InMemoryTransactionRepository();
      final now = DateTime.now();
      final tx = TransactionModel(
        id: 'tx-1',
        amount: 150000,
        merchant: 'WinMart',
        date: now,
        category: Category.food,
        note: 'Milk & snacks',
        createdAt: now,
        updatedAt: now,
      );

      // Create
      await repo.create(tx);
      expect(await repo.count(), 1);

      // Read
      final read = await repo.read('tx-1');
      expect(read?.merchant, 'WinMart');
      expect(read?.amount, 150000);

      // Update
      final updatedTx = tx.copyWith(amount: 180000);
      final updateCount = await repo.update(updatedTx);
      expect(updateCount, 1);
      final readUpdated = await repo.read('tx-1');
      expect(readUpdated?.amount, 180000);

      // Delete
      final deleteCount = await repo.delete('tx-1');
      expect(deleteCount, 1);
      expect(await repo.count(), 0);
    });

    test('Aggregate sumByCategory and sumByDay work properly', () async {
      final samples = getInitialWebSampleTransactions();
      final repo = InMemoryTransactionRepository(initialItems: samples);

      final byCategory = await repo.sumByCategory();
      expect(byCategory.isNotEmpty, isTrue);
      expect(byCategory[Category.food], isNotNull);
      expect(byCategory[Category.food]! > 0, isTrue);

      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final startOfWeek = DateTime(monday.year, monday.month, monday.day);
      final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

      final byDay = await repo.sumByDay(startDate: startOfWeek, endDate: endOfWeek);
      expect(byDay.isNotEmpty, isTrue);

      final total = await repo.totalAmount();
      expect(total > 0, isTrue);
    });
  });
}
