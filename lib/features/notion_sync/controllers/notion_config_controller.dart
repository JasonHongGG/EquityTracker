import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:equity_tracker/core/providers/repository_providers.dart';
import 'package:equity_tracker/features/transaction/data/transaction_model.dart';
import 'package:equity_tracker/features/transaction/providers/transaction_notifier.dart';
import 'package:equity_tracker/features/category/data/category_model.dart';

class NotionConfigState {
  final String token;
  final String dbId;
  final bool isEnabled;
  final bool isLoading;
  final bool isVerifying;
  final String? message;
  final bool isError;
  final bool connectionSuccess;

  NotionConfigState({
    this.token = '',
    this.dbId = '',
    this.isEnabled = false,
    this.isLoading = false,
    this.isVerifying = false,
    this.message,
    this.isError = false,
    this.connectionSuccess = false,
  });

  NotionConfigState copyWith({
    String? token,
    String? dbId,
    bool? isEnabled,
    bool? isLoading,
    bool? isVerifying,
    String? message,
    bool? isError,
    bool? connectionSuccess,
  }) {
    return NotionConfigState(
      token: token ?? this.token,
      dbId: dbId ?? this.dbId,
      isEnabled: isEnabled ?? this.isEnabled,
      isLoading: isLoading ?? this.isLoading,
      isVerifying: isVerifying ?? this.isVerifying,
      message: message, // Allow nulling
      isError: isError ?? this.isError,
      connectionSuccess: connectionSuccess ?? this.connectionSuccess,
    );
  }
}

class NotionConfigController extends Notifier<NotionConfigState> {
  @override
  NotionConfigState build() {
    _loadConfig();
    return NotionConfigState();
  }

  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('notion_token') ?? '';
    final dbId = prefs.getString('notion_database_id') ?? '';
    final isEnabled = prefs.getBool('notion_enabled') ?? false;
    state = state.copyWith(token: token, dbId: dbId, isEnabled: isEnabled);
  }

  void updateToken(String token) {
    state = state.copyWith(token: token);
  }

  void updateDbId(String dbId) {
    state = state.copyWith(dbId: dbId);
  }

  void toggleEnabled(bool enabled) {
    state = state.copyWith(isEnabled: enabled);
  }

  void clearMessage() {
    state = state.copyWith(message: null, isError: false, connectionSuccess: false);
  }

  Future<void> syncFromNotion() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(isLoading: true, message: 'Syncing from Notion... ⏳', isError: false);

    try {
      final lastSyncStr = prefs.getString('notion_last_sync_time');
      final DateTime? lastSync = lastSyncStr != null ? DateTime.parse(lastSyncStr) : null;

      final categories = List<CategoryModel>.from(await ref.read(categoryRepositoryProvider).getCategories());
      final transactions = await ref.read(notionApiClientProvider).fetchTransactions(
        state.token.trim(),
        state.dbId.trim(),
        categories,
        since: lastSync,
      );

      if (transactions.isEmpty) {
        state = state.copyWith(isLoading: false, message: 'No new transactions found.', isError: false);
        return;
      }

      final currentTx = ref.read(transactionNotifierProvider).value ?? [];
      final List<TransactionModel> toInsert = [];

      for (final tx in transactions) {
        final exists = currentTx.any(
          (existing) =>
              existing.amount == tx.amount &&
              existing.title == tx.title &&
              DateUtils.isSameDay(existing.date, tx.date) &&
              existing.type == tx.type,
        );

        if (!exists) {
          toInsert.add(tx);
        }
      }

      if (toInsert.isEmpty) {
        state = state.copyWith(isLoading: false, message: 'All items were duplicates. Skipped.', isError: false);
        return;
      }

      final List<int> insertedIds = [];
      for (final tx in toInsert) {
        final id = await ref.read(transactionRepositoryProvider).insertTransaction(tx);
        insertedIds.add(id);
      }

      // ignore: unused_result
      ref.refresh(transactionNotifierProvider);

      await prefs.setStringList(
        'notion_last_pull_ids',
        insertedIds.map((e) => e.toString()).toList(),
      );
      if (lastSyncStr != null) {
        await prefs.setString('notion_prev_sync_time', lastSyncStr);
      } else {
        await prefs.remove('notion_prev_sync_time');
      }

      await prefs.setString(
        'notion_last_sync_time',
        DateTime.now().toIso8601String(),
      );

      state = state.copyWith(isLoading: false, message: 'Synced \${insertedIds.length} items from Notion! 🎉', isError: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, message: 'Sync Error: \$e', isError: true);
    }
  }

  Future<void> undoNotionSync() async {
    final prefs = await SharedPreferences.getInstance();
    final idsStr = prefs.getStringList('notion_last_pull_ids');
    if (idsStr == null || idsStr.isEmpty) return;

    try {
      final ids = idsStr.map((e) => int.parse(e)).toList();

      for (final id in ids) {
        await ref.read(transactionRepositoryProvider).deleteTransaction(id);
      }

      final prevTime = prefs.getString('notion_prev_sync_time');
      if (prevTime != null) {
        await prefs.setString('notion_last_sync_time', prevTime);
      } else {
        await prefs.remove('notion_last_sync_time');
      }

      await prefs.remove('notion_last_pull_ids');
      await prefs.remove('notion_prev_sync_time');

      // ignore: unused_result
      ref.refresh(transactionNotifierProvider);

      state = state.copyWith(message: 'Last Notion Sync Reverted ↩️', isError: false);
    } catch (e) {
      state = state.copyWith(message: 'Undo Failed: \$e', isError: true);
    }
  }

  Future<void> saveAndVerify(String token, String dbId) async {
    state = state.copyWith(isVerifying: true, token: token, dbId: dbId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notion_token', token.trim());
    await prefs.setString('notion_database_id', dbId.trim());
    await prefs.setBool('notion_enabled', state.isEnabled);

    if (state.isEnabled) {
      final success = await ref.read(notionApiClientProvider).testConnection(token.trim(), dbId.trim());
      if (success) {
        state = state.copyWith(isVerifying: false, message: 'Connected Successfully! ✅', isError: false, connectionSuccess: true);
      } else {
        state = state.copyWith(isVerifying: false, message: 'Connection Failed ❌\\nCheck Token/ID', isError: true, connectionSuccess: false);
      }
    } else {
      state = state.copyWith(isVerifying: false, message: 'Notion Sync Disabled', isError: false, connectionSuccess: true);
    }
  }
}

final notionConfigControllerProvider = NotifierProvider<NotionConfigController, NotionConfigState>(
  NotionConfigController.new,
);
