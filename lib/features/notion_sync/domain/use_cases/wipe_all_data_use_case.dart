import 'package:equity_tracker/features/notion_sync/domain/sync_state_repository.dart';
import 'package:equity_tracker/features/transaction/data/transaction_repository.dart';

class WipeAllDataUseCase {
  final ISyncStateRepository _syncStateRepository;
  final TransactionRepository _transactionRepository;

  WipeAllDataUseCase(
    this._syncStateRepository,
    this._transactionRepository,
  );

  /// Wipes all local transactions and unlinks Notion sync state atomically.
  Future<void> execute() async {
    // 1. Unlink Notion and wipe cursors to prevent split-brain state
    await _syncStateRepository.resetCursors();
    
    // 2. Wipe all local data
    await _transactionRepository.clearAllTransactions();
    await _transactionRepository.clearAllRecurringTransactions();
  }
}
