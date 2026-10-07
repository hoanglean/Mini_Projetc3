import '../../domain/entities/category.dart';

/// Data model representing a transaction stored in SQLite.
class TransactionModel {
  final String id;
  final int amount; // Amount in VND (integer)
  final String merchant;
  final DateTime date;
  final Category category;
  final String note;
  final String? imagePath;
  final String? thumbnailPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TransactionModel({
    required this.id,
    required this.amount,
    required this.merchant,
    required this.date,
    required this.category,
    this.note = '',
    this.imagePath,
    this.thumbnailPath,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from a SQLite row map.
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      amount: map['amount'] as int,
      merchant: map['merchant'] as String,
      date: DateTime.parse(map['date'] as String),
      category: Category.fromString(map['category'] as String),
      note: (map['note'] as String?) ?? '',
      imagePath: map['image_path'] as String?,
      thumbnailPath: map['thumbnail_path'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Convert to a SQLite row map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'merchant': merchant,
      'date': date.toIso8601String(),
      'category': category.name,
      'note': note,
      'image_path': imagePath,
      'thumbnail_path': thumbnailPath,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  TransactionModel copyWith({
    String? id,
    int? amount,
    String? merchant,
    DateTime? date,
    Category? category,
    String? note,
    String? imagePath,
    String? thumbnailPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      merchant: merchant ?? this.merchant,
      date: date ?? this.date,
      category: category ?? this.category,
      note: note ?? this.note,
      imagePath: imagePath ?? this.imagePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'Transaction($id, $merchant, $amount VND, ${date.toIso8601String()})';
}
