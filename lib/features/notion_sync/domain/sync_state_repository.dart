abstract class ISyncStateRepository {
  Future<String> getToken();
  Future<void> setToken(String token);
  
  Future<String> getDatabaseId();
  Future<void> setDatabaseId(String dbId);
  
  Future<bool> getIsEnabled();
  Future<void> setIsEnabled(bool isEnabled);
  
  Future<String?> getLastSyncTime();
  Future<void> setLastSyncTime(String isoTime);
  
  Future<String?> getPrevSyncTime();
  Future<void> setPrevSyncTime(String isoTime);
  
  Future<List<String>?> getLastPullIds();
  Future<void> setLastPullIds(List<String> ids);
  
  /// Wipes all sync state cursors, effectively unlinking the local DB from Notion's timeline.
  Future<void> resetCursors();
  
  /// Gets a complete map of the current sync configuration, useful for backups.
  Future<Map<String, dynamic>> exportState();
  
  /// Restores the entire sync configuration from a map, useful for restoring backups.
  Future<void> importState(Map<String, dynamic> state);
}
