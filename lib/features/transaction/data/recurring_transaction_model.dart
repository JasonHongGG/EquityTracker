import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/core/enums/frequency.dart';

class RecurringTransactionModel {
  final int? id;
  final String title;
  final TransactionType type;
  final int amount;
  final String categoryId;
  final Frequency frequency;
  final DateTime nextDueDate;
  final DateTime? lastGeneratedDate;
  final bool isEnabled;
  final DateTime createdAt;
  final String note;

  const RecurringTransactionModel({
    this.id,
    required this.title,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.frequency,
    required this.nextDueDate,
    this.lastGeneratedDate,
    this.isEnabled = true,
    required this.createdAt,
    this.note = '',
  });

  RecurringTransactionModel copyWith({
    int? id,
    String? title,
    TransactionType? type,
    int? amount,
    String? categoryId,
    Frequency? frequency,
    DateTime? nextDueDate,
    DateTime? lastGeneratedDate,
    bool? isEnabled,
    DateTime? createdAt,
    String? note,
  }) {
    return RecurringTransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      frequency: frequency ?? this.frequency,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      lastGeneratedDate: lastGeneratedDate ?? this.lastGeneratedDate,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
    );
  }

  factory RecurringTransactionModel.fromMap(Map<String, dynamic> map) {
    return RecurringTransactionModel(
      id: map['id'],
      title: map['title'],
      type: TransactionType.values.byName(map['type']),
      amount: map['amount'],
      categoryId: map['categoryId'],
      frequency: Frequency.values.byName(map['frequency']),
      nextDueDate: DateTime.parse(map['nextDueDate']),
      lastGeneratedDate: map['lastGeneratedDate'] != null ? DateTime.parse(map['lastGeneratedDate']) : null,
      isEnabled: map['isEnabled'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
      note: map['note'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'amount': amount,
      'categoryId': categoryId,
      'frequency': frequency.name,
      'nextDueDate': nextDueDate.toIso8601String(),
      'lastGeneratedDate': lastGeneratedDate?.toIso8601String(),
      'isEnabled': isEnabled ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'note': note,
    };
  }
}
