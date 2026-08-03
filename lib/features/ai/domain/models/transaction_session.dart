import 'package:equity_tracker/features/ai/domain/enums/session_status.dart';
import 'package:equity_tracker/features/ai/domain/models/transaction_record.dart';

class TransactionSession {
  final String originalText;
  SessionStatus _status;
  List<TransactionRecord> _records = [];

  TransactionSession(this.originalText) : _status = SessionStatus.extracting;

  String get text => originalText;
  SessionStatus get status => _status;
  List<TransactionRecord> get records => _records;

  void setRecords(List<TransactionRecord> newRecords) {
    _records = newRecords;
  }

  void markProcessingRecords() {
    _status = SessionStatus.processingRecords;
  }

  void markCompleted() {
    _status = SessionStatus.completed;
  }

  void markFailed() {
    _status = SessionStatus.failed;
  }
}
