import 'package:equity_tracker/features/ai/domain/enums/record_status.dart';
import 'package:equity_tracker/features/ai/domain/models/record_data.dart';

class TransactionRecord {
  RecordData _data;
  RecordStatus _status;
  String? _validationQuestion;
  bool _isStoreLookupCompleted = false;

  TransactionRecord(RecordData initialData)
      : _data = initialData.copyWith(),
        _status = RecordStatus.extracted;

  RecordData get data => _data.copyWith();
  RecordStatus get status => _status;
  String? get validationQuestion => _validationQuestion;
  bool get isStoreLookupCompleted => _isStoreLookupCompleted;

  void markExtracted() {
    _status = RecordStatus.extracted;
  }

  void markNeedsStoreResolution() {
    _status = RecordStatus.needsStoreResolution;
  }

  void markValidating() {
    _status = RecordStatus.validating;
    _validationQuestion = null;
  }

  void markNeedsHumanCorrection(String question) {
    _status = RecordStatus.needsHumanCorrection;
    _validationQuestion = question;
  }

  void markResolved() {
    _status = RecordStatus.resolved;
  }

  void markStoreLookupCompleted() {
    _isStoreLookupCompleted = true;
  }

  void updateStore(String storeName) {
    if (_data.store != storeName) {
      _isStoreLookupCompleted = false;
    }
    _data = _data.copyWith(store: storeName);
  }

  void updateData(RecordData newData) {
    if (_data.store != newData.store || _data.locationClue != newData.locationClue) {
      _isStoreLookupCompleted = false;
    }
    
    // 安全合併：保留 categoryId 與 date
    _data = newData.copyWith(
      categoryId: newData.categoryId ?? _data.categoryId,
      date: newData.date ?? _data.date,
    );
  }

  bool requiresStoreLookup() {
    return (_data.store != null && _data.store!.isNotEmpty) || 
           (_data.locationClue != null && _data.locationClue!.isNotEmpty);
  }
}
