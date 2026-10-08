import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/transaction_model.dart';
import '../../domain/entities/category.dart';
import 'transaction_repository.dart';

/// SQLite implementation of [TransactionRepository].
class SqliteTransactionRepository implements TransactionRepository {
  final DatabaseHelper _dbHelper;

  SqliteTransactionRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  static const _table = 'transactions';

  // ─── CRUD ──────────────────────────────────────────────────────────

  @override
  Future<void> create(TransactionModel transaction) async {
    final db = await _dbHelper.database;
    await db.insert(
      _table,
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<TransactionModel?> read(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(_table, where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return TransactionModel.fromMap(maps.first);
  }

  @override
  Future<int> update(TransactionModel transaction) async {
    final db = await _dbHelper.database;
    return await db.update(
      _table,
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  @override
  Future<int> delete(String id) async {
    final db = await _dbHelper.database;
    return await db.delete(_table, where: 'id = ?', whereArgs: [id]);
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
    final db = await _dbHelper.database;

    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (startDate != null) {
      whereClauses.add('date >= ?');
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      whereClauses.add('date <= ?');
      whereArgs.add(endDate.toIso8601String());
    }
    if (category != null) {
      whereClauses.add('category = ?');
      whereArgs.add(category.name);
    }

    final maps = await db.query(
      _table,
      where: whereClauses.isEmpty ? null : whereClauses.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'date DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  @override
  Future<int> count() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM $_table');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<Map<Category, int>> sumByCategory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _dbHelper.database;

    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (startDate != null) {
      whereClauses.add('date >= ?');
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      whereClauses.add('date <= ?');
      whereArgs.add(endDate.toIso8601String());
    }

    final whereStr =
        whereClauses.isEmpty ? '' : 'WHERE ${whereClauses.join(' AND ')}';

    final result = await db.rawQuery(
      'SELECT category, SUM(amount) as total FROM $_table $whereStr GROUP BY category',
      whereArgs.isEmpty ? null : whereArgs,
    );

    final map = <Category, int>{};
    for (final row in result) {
      final cat = Category.fromString(row['category'] as String);
      final total = (row['total'] as num?)?.toInt() ?? 0;
      map[cat] = total;
    }
    return map;
  }

  @override
  Future<Map<DateTime, int>> sumByDay({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT date(date) as day, SUM(amount) as total
      FROM $_table
      WHERE date >= ? AND date <= ?
      GROUP BY date(date)
      ORDER BY day
      ''',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );

    final map = <DateTime, int>{};
    for (final row in result) {
      final dayStr = row['day'] as String;
      final total = (row['total'] as num?)?.toInt() ?? 0;
      map[DateTime.parse(dayStr)] = total;
    }
    return map;
  }

  @override
  Future<int> totalAmount({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _dbHelper.database;

    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (startDate != null) {
      whereClauses.add('date >= ?');
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      whereClauses.add('date <= ?');
      whereArgs.add(endDate.toIso8601String());
    }

    final whereStr =
        whereClauses.isEmpty ? '' : 'WHERE ${whereClauses.join(' AND ')}';

    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM $_table $whereStr',
      whereArgs.isEmpty ? null : whereArgs,
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }
}

TransactionRepository createRepository() => SqliteTransactionRepository();
