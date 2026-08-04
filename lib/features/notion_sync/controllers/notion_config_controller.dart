import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:equity_tracker/core/providers/repository_providers.dart';
import 'package:equity_tracker/features/transaction/data/transaction_model.dart';
import 'package:equity_tracker/features/transaction/providers/transaction_notifier.dart';
import 'package:equity_tracker/features/category/data/category_model.dart';
import 'package:equity_tracker/core/enums/sync_status.dart';
import 'package:equity_tracker/features/notion_sync/services/notion_sync_service.dart';

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
    final connectionSuccess = isEnabled && token.isNotEmpty && dbId.isNotEmpty;
    state = state.copyWith(token: token, dbId: dbId, isEnabled: isEnabled, connectionSuccess: connectionSuccess);

    if (connectionSuccess) {
      // Auto-sync on startup via service
      Future.microtask(() => ref.read(notionSyncServiceProvider).syncFromNotion(silent: true));
    }
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



  Future<void> saveAndVerify(String token, String dbId) async {
    state = state.copyWith(isVerifying: true, token: token, dbId: dbId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notion_token', token.trim());
    await prefs.setString('notion_database_id', dbId.trim());
    await prefs.setBool('notion_enabled', state.isEnabled);

    if (state.isEnabled) {
      final success = await ref.read(notionApiClientProvider).testConnection(token.trim(), dbId.trim());
      if (success) {
        // Initial bulk mark: find all local transactions without notionId and mark them to push
        final repo = ref.read(transactionRepositoryProvider);
        final unsynced = await repo.getTransactionsWithoutNotionId();
        for (var tx in unsynced) {
          if (tx.syncStatus == SyncStatus.synced) {
            await repo.updateTransaction(tx.copyWith(syncStatus: SyncStatus.pendingCreate));
          }
        }
        
        state = state.copyWith(isVerifying: false, message: 'Connected Successfully.', isError: false, connectionSuccess: true);
        
        // After verifying successfully, automatically push any pending changes silently
        Future.microtask(() => ref.read(notionSyncServiceProvider).pushPendingChanges(silent: true));
      } else {
        state = state.copyWith(isVerifying: false, message: 'Connection Failed.', isError: true, connectionSuccess: false);
      }
    } else {
      state = state.copyWith(isVerifying: false, message: 'Notion Sync Disabled.', isError: false, connectionSuccess: true);
    }
  }
}

final notionConfigControllerProvider = NotifierProvider<NotionConfigController, NotionConfigState>(
  NotionConfigController.new,
);
