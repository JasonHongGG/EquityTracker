import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/core/enums/frequency.dart';

class RecurringTransactionEntity {
  final int? id;
  final String title;
  final TransactionType type;
  final int amount;
  final String categoryId;
  final String? note;
  final Frequency frequency;
  final DateTime nextDueDate;
  final DateTime? lastGeneratedDate;
  final bool isEnabled;
  final DateTime createdAt;

  const RecurringTransactionEntity({
    this.id,
    required this.title,
    required this.type,
    required this.amount,
    required this.categoryId,
    this.note,
    required this.frequency,
    required this.nextDueDate,
    this.lastGeneratedDate,
    this.isEnabled = true,
    required this.createdAt,
  });

  RecurringTransactionEntity copyWith({
    int? id,
    String? title,
    TransactionType? type,
    int? amount,
    String? categoryId,
    String? note,
    Frequency? frequency,
    DateTime? nextDueDate,
    DateTime? lastGeneratedDate,
    bool? isEnabled,
    DateTime? createdAt,
  }) {
    return RecurringTransactionEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
      frequency: frequency ?? this.frequency,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      lastGeneratedDate: lastGeneratedDate ?? this.lastGeneratedDate,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
