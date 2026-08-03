import 'package:flutter/material.dart';
import 'package:equity_tracker/core/theme/app_colors.dart';
import 'package:equity_tracker/core/widgets/json_tree_viewer.dart';

class AgentLogDetailScreen extends StatelessWidget {
  final Map<String, dynamic> logData;
  final String fileName;

  const AgentLogDetailScreen({super.key, required this.logData, required this.fileName});



  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final agentName = logData['agentName'] ?? 'Unknown Agent';
    final duration = logData['durationMs'] != null ? '${logData['durationMs']} ms' : 'N/A';
    final timestamp = logData['timestamp'] ?? '';

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(agentName, style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timer_rounded, size: 16, color: isDark ? Colors.white54 : Colors.black54),
                const SizedBox(width: 8),
                Text('Duration: $duration', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 16, color: isDark ? Colors.white54 : Colors.black54),
                const SizedBox(width: 8),
                Text('Time: $timestamp', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
              ],
            ),
            const SizedBox(height: 24),
            
            if (logData['request'] != null) ...[
              JsonTreeViewer(data: logData['request'], isDark: isDark, rootName: 'request'),
              const SizedBox(height: 8),
            ],
            
            if (logData['response'] != null) ...[
              JsonTreeViewer(data: logData['response'], isDark: isDark, rootName: 'response'),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
