import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:equity_tracker/features/ai/infrastructure/logger/i_logger.dart';

abstract class BaseFileLogger<T> implements ILogger<T> {
  final String subDirectory;
  late final Future<Directory> logDirFuture;

  BaseFileLogger(this.subDirectory) {
    logDirFuture = _initLogDir();
  }

  Future<Directory> _initLogDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/.runtime/log/$subDirectory');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String getLocalISOString(DateTime date) {
    return date.toIso8601String();
  }

  Map<String, String> getTimestampParts([DateTime? now]) {
    final dt = now ?? DateTime.now();
    final year = dt.year.toString();
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hours = dt.hour.toString().padLeft(2, '0');
    final minutes = dt.minute.toString().padLeft(2, '0');
    final seconds = dt.second.toString().padLeft(2, '0');

    return {
      'yyyymmdd': '$year$month$day',
      'hhmmss': '$hours$minutes$seconds',
    };
  }

  String getFileName();

  @override
  void log(T data) async {
    final fileName = getFileName();
    try {
      final logDir = await logDirFuture;
      final file = File('${logDir.path}/$fileName');
      await file.writeAsString(jsonEncode(data), mode: FileMode.write);
      
      // 自動觸發留存策略，防止無限堆積
      await enforceRetentionPolicy();
    } catch (e) {
      print('[Logger] Failed to write log file $fileName: $e');
    }
  }

  @override
  Future<List<FileSystemEntity>> getLogs() async {
    try {
      final logDir = await logDirFuture;
      if (!await logDir.exists()) return [];
      
      final files = await logDir.list().toList();
      files.sort((a, b) => b.path.compareTo(a.path)); // 最新的排前面
      return files;
    } catch (e) {
      print('[Logger] Failed to get logs: $e');
      return [];
    }
  }

  @override
  Future<void> clearLogs() async {
    try {
      final logDir = await logDirFuture;
      if (await logDir.exists()) {
        final files = await logDir.list().toList();
        for (final file in files) {
          await file.delete();
        }
      }
    } catch (e) {
      print('[Logger] Failed to clear logs: $e');
    }
  }

  @override
  Future<void> enforceRetentionPolicy({int maxFiles = 50}) async {
    try {
      final logDir = await logDirFuture;
      if (!await logDir.exists()) return;

      final files = await logDir.list().toList();
      if (files.length <= maxFiles) return;

      // 依建立時間排序，把舊的刪除
      files.sort((a, b) => b.path.compareTo(a.path));
      
      // files 是從新到舊排序的。保留前 maxFiles 個，刪除後面的。
      final filesToDelete = files.sublist(maxFiles);
      for (final file in filesToDelete) {
        await file.delete();
      }
    } catch (e) {
      print('[Logger] Failed to enforce retention policy: $e');
    }
  }
}
