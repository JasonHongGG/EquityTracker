import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Removed shared_preferences import
import 'package:equity_tracker/core/providers/repository_providers.dart';
import 'package:equity_tracker/core/enums/sync_status.dart';
import 'package:equity_tracker/features/notion_sync/controllers/notion_config_controller.dart';
import 'package:equity_tracker/features/notion_sync/controllers/sync_progress_controller.dart';
import 'package:equity_tracker/features/category/data/category_model.dart';
import 'package:equity_tracker/features/transaction/providers/transaction_notifier.dart';

class NotionSyncService {
  final Ref _ref;

  NotionSyncService(this._ref);

  Future<void> syncFromNotion({bool silent = false}) async {
    final syncRepo = _ref.read(syncStateRepositoryProvider);
    final config = _ref.read(notionConfigControllerProvider);
    if (!config.isEnabled || config.token.isEmpty || config.dbId.isEmpty) return;

    final progressController = _ref.read(syncProgressProvider.notifier);
    if (!silent) progressController.startSync('Pushing local changes...');

    // First push local changes
    await pushPendingChanges(silent: true);

    try {
      if (!silent) progressController.updateProgress('Fetching transactions from Notion...', 0.2);
      
      final lastSyncStr = await syncRepo.getLastSyncTime();
      final DateTime? lastSync = lastSyncStr != null ? DateTime.parse(lastSyncStr) : null;

      final categories = List<CategoryModel>.from(await _ref.read(categoryRepositoryProvider).getCategories());
      final transactions = await _ref.read(notionApiClientProvider).fetchTransactions(
        config.token.trim(),
        config.dbId.trim(),
        categories,
        since: lastSync,
        onProgress: (fetchedCount) {
          if (!silent) {
            // Cap network progress at 50%, assuming a max of 2000 transactions for progress estimation
            final double networkProgress = 0.2 + (0.3 * (fetchedCount / 2000).clamp(0.0, 1.0));
            progressController.updateProgress('Downloading data... ($fetchedCount items)', networkProgress);
          }
        }
      );

      if (transactions.isEmpty) {
        if (!silent) progressController.stopSync(finalStatus: 'Sync Complete');
        return;
      }

      if (!silent) progressController.updateProgress('Writing data to local database...', 0.6);

      final repo = _ref.read(transactionRepositoryProvider);
      final List<int> insertedIds = await repo.batchUpsertTransactions(transactions);

      if (!silent) progressController.updateProgress('Finalizing sync...', 0.9);

      await syncRepo.setLastPullIds(insertedIds.map((e) => e.toString()).toList());
      if (lastSyncStr != null) {
        await syncRepo.setPrevSyncTime(lastSyncStr);
      }
      await syncRepo.setLastSyncTime(DateTime.now().toIso8601String());

      // Silent reload instead of destructive refresh
      await _ref.read(transactionNotifierProvider.notifier).refresh();

      if (!silent) progressController.stopSync(finalStatus: 'Sync Complete');
    } catch (e) {
      if (!silent) progressController.stopSync(finalStatus: 'Sync Failed');
      // Background sync errors can be logged or ignored silently
      debugPrint('Sync Error: $e');
    }
  }

  Future<void> undoNotionSync() async {
    final syncRepo = _ref.read(syncStateRepositoryProvider);
    final idsStr = await syncRepo.getLastPullIds();
    if (idsStr == null || idsStr.isEmpty) return;

    try {
      final ids = idsStr.map((e) => int.parse(e)).toList();

      for (final id in ids) {
        await _ref.read(transactionRepositoryProvider).deleteTransaction(id);
      }

      final prevTime = await syncRepo.getPrevSyncTime();
      if (prevTime != null) {
        await syncRepo.setLastSyncTime(prevTime);
      }

      // We just call reset on these specific fields manually or via a new method.
      // Since ISyncStateRepository doesn't expose remove() directly except through resetCursors,
      // we can just pass an empty list/string to overwrite.
      await syncRepo.setLastPullIds([]);
      await syncRepo.setPrevSyncTime('');

      await _ref.read(transactionNotifierProvider.notifier).refresh();
    } catch (e) {
      debugPrint('Undo Failed: \$e');
    }
  }

  Future<void> pushPendingChanges({bool silent = false}) async {
    final config = _ref.read(notionConfigControllerProvider);
    if (!config.isEnabled || config.token.isEmpty || config.dbId.isEmpty) return;

    final pending = await _ref.read(transactionRepositoryProvider).getPendingTransactions();
    if (pending.isEmpty) return;

    try {
      final categories = await _ref.read(categoryRepositoryProvider).getCategories();
      final apiClient = _ref.read(notionApiClientProvider);
      final repo = _ref.read(transactionRepositoryProvider);
      bool dataChanged = false;

      for (var tx in pending) {
        final category = categories.firstWhere(
          (c) => c.id == tx.categoryId,
          orElse: () => categories.first,
        );

        if (tx.syncStatus == SyncStatus.pendingCreate) {
          final newId = await apiClient.createTransaction(
            config.token,
            config.dbId,
            tx,
            category.name,
          );
          if (newId != null) {
            final updatedTx = tx.copyWith(notionId: newId, syncStatus: SyncStatus.synced);
            await repo.updateTransaction(updatedTx);
            dataChanged = true;
          }
        } else if (tx.syncStatus == SyncStatus.pendingUpdate) {
          if (tx.notionId == null || tx.notionId!.isEmpty) {
            final newId = await apiClient.createTransaction(
              config.token,
              config.dbId,
              tx,
              category.name,
            );
            if (newId != null) {
              final updatedTx = tx.copyWith(notionId: newId, syncStatus: SyncStatus.synced);
              await repo.updateTransaction(updatedTx);
              dataChanged = true;
            }
          } else {
            final success = await apiClient.updateTransaction(
              config.token,
              tx.notionId!,
              tx,
              category.name,
            );
            if (success) {
              final updatedTx = tx.copyWith(syncStatus: SyncStatus.synced);
              await repo.updateTransaction(updatedTx);
              dataChanged = true;
            }
          }
        } else if (tx.syncStatus == SyncStatus.pendingDelete) {
          if (tx.notionId != null && tx.notionId!.isNotEmpty) {
            final success = await apiClient.deleteTransaction(config.token, tx.notionId!);
            if (success && tx.id != null) {
              await repo.deleteTransaction(tx.id!);
              dataChanged = true;
            }
          } else if (tx.id != null) {
            await repo.deleteTransaction(tx.id!);
            dataChanged = true;
          }
        }
      }
      
      if (dataChanged) {
        await _ref.read(transactionNotifierProvider.notifier).refresh();
      }

    } catch (e) {
      debugPrint('Push Error: \$e');
    }
  }
}

final notionSyncServiceProvider = Provider<NotionSyncService>((ref) {
  return NotionSyncService(ref);
});
