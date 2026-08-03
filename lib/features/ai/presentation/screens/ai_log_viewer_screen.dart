import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:equity_tracker/core/theme/app_colors.dart';
import 'package:intl/intl.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/ai/infrastructure/logger/system_log_manager.dart';
import 'package:equity_tracker/features/ai/infrastructure/logger/i_logger.dart';

import 'package:equity_tracker/features/ai/presentation/screens/agent_log_detail_screen.dart';
import 'package:equity_tracker/features/ai/presentation/screens/map_log_detail_screen.dart';

class AiLogViewerScreen extends ConsumerStatefulWidget {
  const AiLogViewerScreen({super.key});

  @override
  ConsumerState<AiLogViewerScreen> createState() => _AiLogViewerScreenState();
}

class _AiLogViewerScreenState extends ConsumerState<AiLogViewerScreen> with SingleTickerProviderStateMixin {
  List<FileSystemEntity> _agentLogs = [];
  List<FileSystemEntity> _mapLogs = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllLogs();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllLogs() async {
    setState(() => _isLoading = true);
    try {
      final agentLogger = ref.read(agentLoggerProvider);
      final mapLogger = ref.read(mapLoggerProvider);
      
      final agentLogs = await agentLogger.getLogs();
      final mapLogs = await mapLogger.getLogs();
      
      setState(() {
        _agentLogs = agentLogs;
        _mapLogs = mapLogs;
      });
    } catch (e) {
      print('Failed to load logs: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _clearAllLogs() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Logs'),
        content: const Text('Are you sure you want to delete all Agent and Map logs? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      )
    );
    
    if (confirm == true) {
      setState(() => _isLoading = true);
      await ref.read(systemLogManagerProvider).clearAllLogs();
      await _loadAllLogs();
    }
  }

  void _openLogDetail(FileSystemEntity file, bool isDark, bool isMapLog) async {
    try {
      final content = await File(file.path).readAsString();
      final json = jsonDecode(content);
      
      if (!mounted) return;
      
      final fileName = file.path.split(Platform.pathSeparator).last;
      
      // Polymorphic Routing based on Log Domain
      if (isMapLog) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MapLogDetailScreen(logData: json, fileName: fileName),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AgentLogDetailScreen(logData: json, fileName: fileName),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to read log: $e')));
    }
  }
  
  Widget _buildLogList(List<FileSystemEntity> logFiles, bool isDark, ThemeData theme, bool isMapLog) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (logFiles.isEmpty) {
      return const Center(child: Text('No logs found.'));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 8),
      itemCount: logFiles.length,
      itemBuilder: (context, index) {
        final file = logFiles[index];
        final fileName = file.path.split(Platform.pathSeparator).last;
        final parts = fileName.split('_');
        String title = fileName;
        String subtitle = '';
        
        if (parts.length >= 2) {
          try {
            final dateStr = parts[0];
            final timeStr = parts[1];
            
            final year = int.parse(dateStr.substring(0, 4));
            final month = int.parse(dateStr.substring(4, 6));
            final day = int.parse(dateStr.substring(6, 8));
            final hour = int.parse(timeStr.substring(0, 2));
            final min = int.parse(timeStr.substring(2, 4));
            final sec = int.parse(timeStr.substring(4, 6));
            
            final dt = DateTime(year, month, day, hour, min, sec);
            
            if (parts.length >= 4) {
              title = parts[2]; // Agent name
            } else if (parts.length >= 3 && parts[2].startsWith('map')) {
              title = 'Map Search';
            }
            
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
              child: Icon(
                isMapLog ? Icons.map_outlined : Icons.smart_toy_outlined, 
                color: theme.primaryColor
              ),
            ),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
            subtitle: Text(subtitle),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _openLogDetail(file, isDark, isMapLog),
          ),
        );
      },
    );
  }

  Widget _buildSegmentedControl(ThemeData theme, bool isDark) {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _tabController.animateTo(0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _tabController.index == 0 ? theme.primaryColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Agent',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.bold,
                        color: _tabController.index == 0 ? Colors.white : (isDark ? Colors.white54 : Colors.black54),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => _tabController.animateTo(1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _tabController.index == 1 ? theme.primaryColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Map Search',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.bold,
                        color: _tabController.index == 1 ? Colors.white : (isDark ? Colors.white54 : Colors.black54),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('System Logs', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: 'Clear All Logs',
            onPressed: _clearAllLogs,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllLogs,
          )
        ],
      ),
      body: Column(
        children: [
          _buildSegmentedControl(theme, isDark),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLogList(_agentLogs, isDark, theme, false),
                _buildLogList(_mapLogs, isDark, theme, true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
