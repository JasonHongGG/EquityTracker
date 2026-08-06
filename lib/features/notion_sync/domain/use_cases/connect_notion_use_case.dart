import 'package:equity_tracker/features/notion_sync/domain/sync_state_repository.dart';
import 'package:equity_tracker/features/notion_sync/data/notion_api_client.dart';
import 'package:equity_tracker/features/notion_sync/services/notion_sync_service.dart';
import 'package:equity_tracker/features/transaction/data/transaction_repository.dart';
import 'package:equity_tracker/core/enums/sync_status.dart';

class ConnectNotionUseCase {
  final ISyncStateRepository _syncStateRepository;
  final NotionApiClient _notionApiClient;
  final NotionSyncService _notionSyncService;
  final TransactionRepository _transactionRepository;

  ConnectNotionUseCase(
    this._syncStateRepository,
    this._notionApiClient,
    this._notionSyncService,
    this._transactionRepository,
  );

  /// Validates the token and dbId, explicitly enables sync state, and triggers an initial sync.
  /// Throws an exception if connection fails.
  Future<void> execute(String token, String dbId) async {
    final cleanToken = token.trim();
    final cleanDbId = dbId.trim();
    
    // 1. Verify credentials with API
    final isValid = await _notionApiClient.testConnection(cleanToken, cleanDbId);
    if (!isValid) {
      throw Exception('Failed to connect to Notion. Please check your Token and Database ID.');
    }

    // 2. Persist configuration and FORCE enable sync state
    await _syncStateRepository.setToken(cleanToken);
    await _syncStateRepository.setDatabaseId(cleanDbId);
    await _syncStateRepository.setIsEnabled(true);

    // 3. Mark existing local transactions for sync if they don't have a Notion ID
    final unsynced = await _transactionRepository.getTransactionsWithoutNotionId();
    for (var tx in unsynced) {
      if (tx.syncStatus == SyncStatus.synced) {
        await _transactionRepository.updateTransaction(
          tx.copyWith(syncStatus: SyncStatus.pendingCreate),
        );
      }
    }

    // 4. Trigger background bidirectional sync asynchronously so it doesn't block verification
    // Passing silent: false so the UI shows the progress bar for the initial massive sync.
    Future.microtask(() => _notionSyncService.syncFromNotion(silent: false));
  }
}
