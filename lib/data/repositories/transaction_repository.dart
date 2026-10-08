import '../models/transaction_model.dart';
import '../../domain/entities/category.dart';
import 'transaction_repository_factory.dart';

/// Abstract repository interface for transaction CRUD operations and aggregate queries.
abstract class TransactionRepository {
  /// Factory constructor that returns either SQLite or In-Memory implementation.
  factory TransactionRepository() => buildDefaultTransactionRepository();

  /// Insert a new transaction.
  Future<void> create(TransactionModel transaction);

  /// Read a single transaction by ID.
  Future<TransactionModel?> read(String id);

  /// Update an existing transaction.
  Future<int> update(TransactionModel transaction);

  /// Delete a transaction by ID.
  Future<int> delete(String id);

  /// List all transactions, optionally filtered and ordered by date desc.
  Future<List<TransactionModel>> list({
    DateTime? startDate,
    DateTime? endDate,
    Category? category,
    int? limit,
    int? offset,
  });

  /// Get the total number of transactions.
  Future<int> count();

  /// Sum of amounts by category (for pie/donut chart).
  Future<Map<Category, int>> sumByCategory({
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Sum of amounts per day for a given date range (for bar chart).
  Future<Map<DateTime, int>> sumByDay({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Total amount spent (all time or filtered).
  Future<int> totalAmount({
    DateTime? startDate,
    DateTime? endDate,
  });
}
