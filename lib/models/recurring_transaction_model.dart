import 'transaction_type.dart';

enum Frequency {
  daily,
  weekly,
  monthly,
  yearly;

  String get label {
    switch (this) {
      case Frequency.daily:
        return 'Daily';
      case Frequency.weekly:
        return 'Weekly';
      case Frequency.monthly:
        return 'Monthly';
      case Frequency.yearly:
        return 'Yearly';
    }
  }

  String toJson() => name;
  static Frequency fromJson(String json) => values.byName(json);
}

class RecurringTransaction {
  final int? id;
  final String title;
  final int amount;
  final TransactionType type;
  final String categoryId;
  final Frequency frequency;
  final DateTime nextDueDate;
  final DateTime? lastGeneratedDate;
  final bool isEnabled;
  final String? note;
  final DateTime createdAt;

  RecurringTransaction({
    this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.frequency,
    required this.nextDueDate,
    this.lastGeneratedDate,
    this.isEnabled = true,
    this.note,
    required this.createdAt,
  });

  RecurringTransaction copyWith({
    int? id,
    String? title,
    int? amount,
    TransactionType? type,
    String? categoryId,
    Frequency? frequency,
    DateTime? nextDueDate,
    DateTime? lastGeneratedDate,
    bool? isEnabled,
    String? note,
    DateTime? createdAt,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      frequency: frequency ?? this.frequency,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      lastGeneratedDate: lastGeneratedDate ?? this.lastGeneratedDate,
      isEnabled: isEnabled ?? this.isEnabled,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.toJson(),
      'categoryId': categoryId,
      'frequency': frequency.toJson(),
      'nextDueDate': nextDueDate.toIso8601String(),
      'lastGeneratedDate': lastGeneratedDate?.toIso8601String(),
      'isEnabled': isEnabled ? 1 : 0,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory RecurringTransaction.fromMap(Map<String, dynamic> map) {
    return RecurringTransaction(
      id: map['id']?.toInt(),
      title: map['title'] ?? '',
      amount: map['amount']?.toInt() ?? 0,
      type: TransactionType.fromJson(map['type']),
      categoryId: map['categoryId'] ?? '',
      frequency: Frequency.fromJson(map['frequency']),
      nextDueDate: DateTime.parse(map['nextDueDate']),
      lastGeneratedDate: map['lastGeneratedDate'] != null
          ? DateTime.parse(map['lastGeneratedDate'])
          : null,
      isEnabled: (map['isEnabled'] as int) == 1,
      note: map['note'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
