
import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/features/transaction/data/transaction_model.dart';

class TransactionModel {
  final int? id;
  final String? notionId;
  final String? title;
  final TransactionType type;
  final int amount;
  final String categoryId;
  final DateTime date;
  final DateTime createdAt;
  final String? note;

  const TransactionModel({
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
