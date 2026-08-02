import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/core/enums/sync_status.dart';

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
  final SyncStatus syncStatus;

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
    this.syncStatus = SyncStatus.synced,
  });

  TransactionModel copyWith({
    int? id,
    String? notionId,
    String? title,
    TransactionType? type,
    int? amount,
    String? categoryId,
    DateTime? date,
    DateTime? createdAt,
    String? note,
    SyncStatus? syncStatus,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      notionId: notionId ?? this.notionId,
      title: title ?? this.title,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
      syncStatus: syncStatus ?? this.syncStatus,
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
      syncStatus: map['syncStatus'] != null 
          ? SyncStatus.values.byName(map['syncStatus']) 
          : SyncStatus.synced,
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
      'syncStatus': syncStatus.name,
    };
  }
}
