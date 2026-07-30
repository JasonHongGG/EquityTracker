import '../../domain/entities/transaction_entity.dart';
import '../../core/enums/transaction_type.dart';

class TransactionModel extends TransactionEntity {
  const TransactionModel({
    super.id,
    super.notionId,
    super.title,
    required super.type,
    required super.amount,
    required super.categoryId,
    required super.date,
    required super.createdAt,
    super.note,
  });

  factory TransactionModel.fromEntity(TransactionEntity entity) {
    return TransactionModel(
      id: entity.id,
      notionId: entity.notionId,
      title: entity.title,
      type: entity.type,
      amount: entity.amount,
      categoryId: entity.categoryId,
      date: entity.date,
      createdAt: entity.createdAt,
      note: entity.note,
    );
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      notionId: map['notionId'],
      title: map['title'],
      type: TransactionType.values.byName(map['type']),
      amount: map['amount'],
      categoryId: map['categoryId'],
      date: DateTime.parse(map['date']),
      createdAt: DateTime.parse(map['createdAt']),
      note: map['note'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'notionId': notionId,
      'title': title,
      'type': type.name,
      'amount': amount,
      'categoryId': categoryId,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'note': note,
    };
  }
}
