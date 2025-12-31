import 'transaction_type.dart';

class TransactionModel {
  final int? id; // Nullable for new records (auto-increment)
  final String? title; // New field for specific expense name
  final TransactionType type;
  final int amount; // Integer > 0
  final String categoryId;
  final DateTime date; // DateTime precise to day
  final DateTime createdAt;
  final String? note;

  TransactionModel({
    this.id,
    this.title,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.date,
    required this.createdAt,
    this.note,
  }) {
    if (amount <= 0) {
      throw ArgumentError('Amount must be greater than 0');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type.toJson(),
      'amount': amount,
      'categoryId': categoryId,
      'date': date.toIso8601String().split(
        'T',
      )[0], // Store as YYYY-MM-DD for simpler querying
      'createdAt': createdAt.toIso8601String(),
      'note': note,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      title: map['title'] as String?,
      type: TransactionType.fromJson(map['type'] as String),
      amount: map['amount'] as int,
      categoryId: map['categoryId'] as String,
      date: DateTime.parse(map['date'] as String), // or just parse YYYY-MM-DD
      createdAt: DateTime.parse(map['createdAt'] as String),
      note: map['note'] as String?,
    );
  }

  TransactionModel copyWith({
    int? id,
    String? title,
    TransactionType? type,
    int? amount,
    String? categoryId,
    DateTime? date,
    DateTime? createdAt,
    String? note,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
    );
  }
}
