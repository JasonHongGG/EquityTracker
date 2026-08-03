import 'dart:io';

abstract class ILogger<T> {
  void log(T data);
  Future<List<FileSystemEntity>> getLogs();
  Future<void> clearLogs();
  Future<void> enforceRetentionPolicy({int maxFiles = 50});
}
