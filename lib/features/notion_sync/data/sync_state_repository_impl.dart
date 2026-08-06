import 'package:shared_preferences/shared_preferences.dart';
import 'package:equity_tracker/features/notion_sync/domain/sync_state_repository.dart';

class SyncStateRepositoryImpl implements ISyncStateRepository {
  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<String> getToken() async => (await _prefs).getString('notion_token') ?? '';

  @override
  Future<void> setToken(String token) async => (await _prefs).setString('notion_token', token);

  @override
  Future<String> getDatabaseId() async => (await _prefs).getString('notion_database_id') ?? '';

  @override
  Future<void> setDatabaseId(String dbId) async => (await _prefs).setString('notion_database_id', dbId);

  @override
  Future<bool> getIsEnabled() async => (await _prefs).getBool('notion_enabled') ?? false;

  @override
  Future<void> setIsEnabled(bool isEnabled) async => (await _prefs).setBool('notion_enabled', isEnabled);

  @override
  Future<String?> getLastSyncTime() async => (await _prefs).getString('notion_last_sync_time');

  @override
  Future<void> setLastSyncTime(String isoTime) async => (await _prefs).setString('notion_last_sync_time', isoTime);

  @override
  Future<String?> getPrevSyncTime() async => (await _prefs).getString('notion_prev_sync_time');

  @override
  Future<void> setPrevSyncTime(String isoTime) async => (await _prefs).setString('notion_prev_sync_time', isoTime);

  @override
  Future<List<String>?> getLastPullIds() async => (await _prefs).getStringList('notion_last_pull_ids');

  @override
  Future<void> setLastPullIds(List<String> ids) async => (await _prefs).setStringList('notion_last_pull_ids', ids);

  @override
  Future<void> resetCursors() async {
    await setIsEnabled(false);
    final p = await _prefs;
    await p.remove('notion_last_sync_time');
    await p.remove('notion_prev_sync_time');
    await p.remove('notion_last_pull_ids');
  }

  @override
  Future<Map<String, dynamic>> exportState() async {
    return {
      'token': await getToken(),
      'database_id': await getDatabaseId(),
      'enabled': await getIsEnabled(),
      'last_sync_time': await getLastSyncTime(),
      'prev_sync_time': await getPrevSyncTime(),
      'last_pull_ids': await getLastPullIds(),
    };
  }

  @override
  Future<void> importState(Map<String, dynamic> state) async {
    final p = await _prefs;
    if (state['token'] != null) {
      await setToken(state['token']);
    } else {
      await p.remove('notion_token');
    }
    
    if (state['database_id'] != null) {
      await setDatabaseId(state['database_id']);
    } else {
      await p.remove('notion_database_id');
    }
    
    if (state['enabled'] != null) {
      await setIsEnabled(state['enabled']);
    } else {
      await p.remove('notion_enabled');
    }
    
    if (state['last_sync_time'] != null) {
      await setLastSyncTime(state['last_sync_time']);
    } else {
      await p.remove('notion_last_sync_time');
    }
    
    if (state['prev_sync_time'] != null) {
      await setPrevSyncTime(state['prev_sync_time']);
    } else {
      await p.remove('notion_prev_sync_time');
    }
    
    if (state['last_pull_ids'] != null) {
      final pullIds = (state['last_pull_ids'] as List).map((e) => e.toString()).toList();
      await setLastPullIds(pullIds);
    } else {
      await p.remove('notion_last_pull_ids');
    }
  }
}
