import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:equity_tracker/core/theme/app_colors.dart';

class AgentLogDetailScreen extends StatelessWidget {
  final Map<String, dynamic> logData;
  final String fileName;

  const AgentLogDetailScreen({super.key, required this.logData, required this.fileName});

  Widget _buildJsonBlock(String title, dynamic data, BuildContext context, bool isDark) {
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8, top: 16),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 1.2,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              jsonStr,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: isDark ? Colors.greenAccent : Colors.indigo,
              ),
            ),
          ),
        ),
      ],
    );
  }

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
            
            _buildJsonBlock('Request', logData['request'], context, isDark),
            _buildJsonBlock('Response', logData['response'], context, isDark),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
