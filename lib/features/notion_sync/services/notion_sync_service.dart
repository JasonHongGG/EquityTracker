import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:equity_tracker/core/providers/repository_providers.dart';
import 'package:equity_tracker/core/enums/sync_status.dart';
import 'package:equity_tracker/features/notion_sync/controllers/notion_config_controller.dart';
import 'package:equity_tracker/features/category/data/category_model.dart';
import 'package:equity_tracker/features/transaction/providers/transaction_notifier.dart';

class NotionSyncService {
  final Ref _ref;

  NotionSyncService(this._ref);

  Future<void> syncFromNotion({bool silent = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final config = _ref.read(notionConfigControllerProvider);
    if (!config.isEnabled || config.token.isEmpty || config.dbId.isEmpty) return;

    // First push local changes
    await pushPendingChanges(silent: true);

    try {
      final lastSyncStr = prefs.getString('notion_last_sync_time');
      final DateTime? lastSync = lastSyncStr != null ? DateTime.parse(lastSyncStr) : null;

      final categories = List<CategoryModel>.from(await _ref.read(categoryRepositoryProvider).getCategories());
      final transactions = await _ref.read(notionApiClientProvider).fetchTransactions(
        config.token.trim(),
        config.dbId.trim(),
        categories,
        since: lastSync,
      );

      if (transactions.isEmpty) {
        return;
      }

      final repo = _ref.read(transactionRepositoryProvider);
      final List<int> insertedIds = [];

      for (final tx in transactions) {
        if (tx.notionId == null || tx.notionId!.isEmpty) continue;

        final existing = await repo.getTransactionByNotionId(tx.notionId!);
        if (existing != null) {
          final updated = existing.copyWith(
            title: tx.title,
            amount: tx.amount,
            date: tx.date,
            categoryId: tx.categoryId,
            type: tx.type,
            syncStatus: SyncStatus.synced,
          );
          await repo.updateTransaction(updated);
        } else {
          final id = await repo.insertTransaction(tx);
          insertedIds.add(id);
        }
      }

      await prefs.setStringList('notion_last_pull_ids', insertedIds.map((e) => e.toString()).toList());
      if (lastSyncStr != null) {
        await prefs.setString('notion_prev_sync_time', lastSyncStr);
      } else {
        await prefs.remove('notion_prev_sync_time');
      }
      await prefs.setString('notion_last_sync_time', DateTime.now().toIso8601String());

      // Silent reload instead of destructive refresh
      await _ref.read(transactionNotifierProvider.notifier).silentReload();

    } catch (e) {
      // Background sync errors can be logged or ignored silently
      debugPrint('Sync Error: \$e');
    }
  }

  Future<void> undoNotionSync() async {
    final prefs = await SharedPreferences.getInstance();
    final idsStr = prefs.getStringList('notion_last_pull_ids');
    if (idsStr == null || idsStr.isEmpty) return;

    try {
      final ids = idsStr.map((e) => int.parse(e)).toList();

      for (final id in ids) {
        await _ref.read(transactionRepositoryProvider).deleteTransaction(id);
      }

      final prevTime = prefs.getString('notion_prev_sync_time');
      if (prevTime != null) {
        await prefs.setString('notion_last_sync_time', prevTime);
      } else {
        await prefs.remove('notion_last_sync_time');
      }

      await prefs.remove('notion_last_pull_ids');
      await prefs.remove('notion_prev_sync_time');

      await _ref.read(transactionNotifierProvider.notifier).silentReload();
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
        await _ref.read(transactionNotifierProvider.notifier).silentReload();
      }

    } catch (e) {
      debugPrint('Push Error: \$e');
    }
  }
}

final notionSyncServiceProvider = Provider<NotionSyncService>((ref) {
  return NotionSyncService(ref);
});
