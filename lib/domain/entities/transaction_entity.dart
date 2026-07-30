import 'package:equity_tracker/core/enums/transaction_type.dart';

class TransactionEntity {
  final int? id;
  final String? notionId;
  final String? title;
  final TransactionType type;
  final int amount;
  final String categoryId;
  final DateTime date;
  final DateTime createdAt;
  final String? note;

  const TransactionEntity({
    this.id,
    this.notionId,
    this.title,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.date,
    required this.createdAt,
    this.note,
  });

  TransactionEntity copyWith({
    int? id,
    String? notionId,
    String? title,
    TransactionType? type,
    int? amount,
    String? categoryId,
    DateTime? date,
    DateTime? createdAt,
    String? note,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      notionId: notionId ?? this.notionId,
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
