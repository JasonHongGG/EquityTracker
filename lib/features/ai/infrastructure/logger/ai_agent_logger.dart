import 'dart:math';
import 'package:equity_tracker/features/ai/infrastructure/logger/base_file_logger.dart';

class AIAgentLogger extends BaseFileLogger<Map<String, dynamic>> {
  final String agentName;

  AIAgentLogger(this.agentName) : super('agent');

  @override
  String getFileName() {
    final parts = getTimestampParts();
    final yyyymmdd = parts['yyyymmdd'];
    final hhmmss = parts['hhmmss'];
    final random = Random().nextInt(999999).toString().padLeft(6, '0');
    return '${yyyymmdd}_${hhmmss}_${agentName}_$random.json';
  }

  void logInteraction(dynamic request, dynamic response, int startTime) {
    final endTime = DateTime.now().millisecondsSinceEpoch;
    final durationMs = endTime - startTime;

    final logData = {
      'timestamp': getLocalISOString(DateTime.now()),
      'agentName': agentName,
      'durationMs': durationMs,
      'request': request,
      'response': response,
    };

    this.log(logData);
  }
}
