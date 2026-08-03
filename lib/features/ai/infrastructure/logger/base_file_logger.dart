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
    } catch (e) {
      print('[Logger] Failed to write log file $fileName: $e');
    }
  }
}
