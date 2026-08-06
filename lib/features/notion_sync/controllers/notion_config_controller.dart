import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/providers/repository_providers.dart';
import 'package:equity_tracker/core/providers/usecase_providers.dart';
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
    final syncRepo = ref.read(syncStateRepositoryProvider);
    final token = await syncRepo.getToken();
    final dbId = await syncRepo.getDatabaseId();
    final isEnabled = await syncRepo.getIsEnabled();
    final connectionSuccess = isEnabled && token.isNotEmpty && dbId.isNotEmpty;
    
    state = state.copyWith(
      token: token, 
      dbId: dbId, 
      isEnabled: isEnabled, 
      connectionSuccess: connectionSuccess
    );

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

  Future<void> reloadConfig() async {
    await _loadConfig();
  }

  Future<void> disableSync() async {
    state = state.copyWith(isEnabled: false);
    await ref.read(syncStateRepositoryProvider).setIsEnabled(false);
  }

  Future<void> resetSyncState() async {
    state = state.copyWith(isEnabled: false);
    await ref.read(syncStateRepositoryProvider).resetCursors();
  }

  Future<void> saveAndVerify(String token, String dbId) async {
    state = state.copyWith(isVerifying: true, token: token, dbId: dbId);

    try {
      // Delegate to domain use case
      await ref.read(connectNotionUseCaseProvider).execute(token, dbId);
      
      state = state.copyWith(
        isVerifying: false, 
        message: 'Connected Successfully.', 
        isError: false, 
        connectionSuccess: true,
        isEnabled: true // Force UI to reflect domain state
      );
    } catch (e) {
      state = state.copyWith(
        isVerifying: false, 
        message: e.toString().replaceAll('Exception: ', ''), 
        isError: true, 
        connectionSuccess: false
      );
    }
  }
}

final notionConfigControllerProvider = NotifierProvider<NotionConfigController, NotionConfigState>(
  NotionConfigController.new,
);
