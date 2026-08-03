import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:equity_tracker/features/ai/infrastructure/logger/ai_agent_logger.dart';
import 'package:equity_tracker/features/ai/infrastructure/logger/map_search_logger.dart';

class SystemLogManager {
  Future<void> clearAllLogs() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final logDir = Directory('${appDir.path}/.runtime/log');
      
      if (await logDir.exists()) {
        await logDir.delete(recursive: true);
      }
    } catch (e) {
      print('[SystemLogManager] Failed to clear all logs: $e');
    }
  }
}

final systemLogManagerProvider = Provider<SystemLogManager>((ref) {
  return SystemLogManager();
});

final agentLoggerProvider = Provider<AIAgentLogger>((ref) {
  return AIAgentLogger('SystemViewer');
});

final mapLoggerProvider = Provider<MapSearchLogger>((ref) {
  return MapSearchLogger();
});

final agentLogListProvider = FutureProvider.autoDispose<List<FileSystemEntity>>((ref) async {
  final logger = ref.watch(agentLoggerProvider);
  return await logger.getLogs();
});

final mapLogListProvider = FutureProvider.autoDispose<List<FileSystemEntity>>((ref) async {
  final logger = ref.watch(mapLoggerProvider);
  return await logger.getLogs();
});
