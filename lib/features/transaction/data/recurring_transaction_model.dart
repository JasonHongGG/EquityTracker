import 'package:equity_tracker/features/transaction/domain/recurring_transaction_entity.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/core/enums/frequency.dart';

class RecurringTransactionModel extends RecurringTransactionEntity {
  const RecurringTransactionModel({
    super.id,
    required super.title,
    required super.type,
    required super.amount,
    required super.categoryId,
    super.note,
    required super.frequency,
    required super.nextDueDate,
    super.lastGeneratedDate,
    super.isEnabled = true,
    required super.createdAt,
  });

  factory RecurringTransactionModel.fromEntity(RecurringTransactionEntity entity) {
    return RecurringTransactionModel(
      id: entity.id,
      title: entity.title,
      type: entity.type,
      amount: entity.amount,
      categoryId: entity.categoryId,
      note: entity.note,
      frequency: entity.frequency,
      nextDueDate: entity.nextDueDate,
      lastGeneratedDate: entity.lastGeneratedDate,
      isEnabled: entity.isEnabled,
      createdAt: entity.createdAt,
    );
  }

  factory RecurringTransactionModel.fromMap(Map<String, dynamic> map) {
    return RecurringTransactionModel(
      id: map['id'],
      title: map['title'],
      type: TransactionType.values.byName(map['type']),
      amount: map['amount'],
      categoryId: map['categoryId'],
      note: map['note'],
      frequency: Frequency.values.byName(map['frequency']),
      nextDueDate: DateTime.parse(map['nextDueDate']),
      lastGeneratedDate: map['lastGeneratedDate'] != null ? DateTime.parse(map['lastGeneratedDate']) : null,
      isEnabled: map['isEnabled'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'amount': amount,
      'categoryId': categoryId,
      'note': note,
      'frequency': frequency.name,
      'nextDueDate': nextDueDate.toIso8601String(),
      'lastGeneratedDate': lastGeneratedDate?.toIso8601String(),
      'isEnabled': isEnabled ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
