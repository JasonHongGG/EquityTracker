import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:equity_tracker/core/theme/app_colors.dart';
import 'package:intl/intl.dart';

class AiLogViewerScreen extends StatefulWidget {
  const AiLogViewerScreen({super.key});

  @override
  State<AiLogViewerScreen> createState() => _AiLogViewerScreenState();
}

class _AiLogViewerScreenState extends State<AiLogViewerScreen> {
  List<FileSystemEntity> _logFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogFiles();
  }

  Future<void> _loadLogFiles() async {
    setState(() => _isLoading = true);
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${appDir.path}/.runtime/log/agent');
      if (await dir.exists()) {
        final files = await dir.list().toList();
        files.sort((a, b) => b.path.compareTo(a.path)); // Sort newest first
        setState(() {
          _logFiles = files;
        });
      }
    } catch (e) {
      print('Failed to load logs: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _openLogDetail(FileSystemEntity file, bool isDark) async {
    try {
      final content = await File(file.path).readAsString();
      final json = jsonDecode(content);
      
      if (!mounted) return;
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AiLogDetailScreen(logData: json, fileName: file.path.split(Platform.pathSeparator).last),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to read log: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('AI Agent Logs', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogFiles,
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _logFiles.isEmpty
          ? const Center(child: Text('No logs found.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _logFiles.length,
              itemBuilder: (context, index) {
                final file = _logFiles[index];
                final fileName = file.path.split(Platform.pathSeparator).last;
                // Parse filename: 20260803_151910_extractionAgent_123456.json
                final parts = fileName.split('_');
                String title = fileName;
                String subtitle = '';
                
                if (parts.length >= 4) {
                  try {
                    final dateStr = parts[0];
                    final timeStr = parts[1];
                    final agent = parts[2];
                    
                    final year = int.parse(dateStr.substring(0, 4));
                    final month = int.parse(dateStr.substring(4, 6));
                    final day = int.parse(dateStr.substring(6, 8));
                    final hour = int.parse(timeStr.substring(0, 2));
                    final min = int.parse(timeStr.substring(2, 4));
                    final sec = int.parse(timeStr.substring(4, 6));
                    
                    final dt = DateTime(year, month, day, hour, min, sec);
                    title = agent;
                    subtitle = DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
                  } catch (_) {}
                }

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: isDark ? Colors.white12 : Colors.black12, width: 1),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.bug_report_rounded, color: theme.primaryColor),
                    ),
                    title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
                    subtitle: Text(subtitle),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _openLogDetail(file, isDark),
                  ),
                );
              },
            ),
    );
  }
}

class AiLogDetailScreen extends StatelessWidget {
  final Map<String, dynamic> logData;
  final String fileName;

  const AiLogDetailScreen({super.key, required this.logData, required this.fileName});

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
