import 'package:equity_tracker/features/ai/domain/models/record_data.dart';

class TransactionRecord {
  RecordData _data;
  String? _validationQuestion;
  bool isResolved = false;
  
  // Blackboard metadata for workers to store their state
  final Map<String, dynamic> metadata = {};

  TransactionRecord(RecordData initialData)
      : _data = initialData.copyWith();

  RecordData get data => _data.copyWith();
  String? get validationQuestion => _validationQuestion;

  void setValidationQuestion(String? question) {
    _validationQuestion = question;
  }

  void markResolved() {
    isResolved = true;
  }

  void updateStore(String storeName) {
    _data = _data.copyWith(store: storeName);
  }

  void updateData(RecordData newData) {
    // 安全合併：保留 categoryId 與 date
    _data = newData.copyWith(
      categoryId: newData.categoryId ?? _data.categoryId,
      date: newData.date ?? _data.date,
    );
  }
}
