import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:equity_tracker/core/theme/app_colors.dart';
import 'package:intl/intl.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/ai/infrastructure/logger/system_log_manager.dart';
import 'package:equity_tracker/features/ai/presentation/screens/agent_log_detail_screen.dart';
import 'package:equity_tracker/features/ai/presentation/screens/map_log_detail_screen.dart';
import 'package:equity_tracker/core/widgets/swipe_to_obliterate_button.dart';

class AiLogViewerScreen extends ConsumerStatefulWidget {
  const AiLogViewerScreen({super.key});

  @override
  ConsumerState<AiLogViewerScreen> createState() => _AiLogViewerScreenState();
}

class _AiLogViewerScreenState extends ConsumerState<AiLogViewerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Listen to changes to rebuild the segmented control animation
    _tabController.addListener(() {
      setState(() {});
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  void _clearAllLogs() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'CLEAR AI LOGS',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ),
            const SizedBox(height: 32),
            SwipeToObliterateButton(
              title: 'SLIDE TO WIPE',
              isLoading: false,
              activeColor: Colors.redAccent,
              onConfirmed: () async {
                Navigator.pop(ctx);
                await ref.read(systemLogManagerProvider).clearAllLogs();
                ref.invalidate(agentLogListProvider);
                ref.invalidate(mapLogListProvider);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openLogDetail(FileSystemEntity file, bool isDark, bool isMapLog) async {
    try {
      final content = await File(file.path).readAsString();
      final json = jsonDecode(content);
      
      if (!mounted) return;
      
      final fileName = file.path.split(Platform.pathSeparator).last;
      
      if (isMapLog) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MapLogDetailScreen(logData: json, fileName: fileName)),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AgentLogDetailScreen(logData: json, fileName: fileName)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to read log: $e')));
    }
  }
  
  Widget _buildLogList(AsyncValue<List<FileSystemEntity>> logsAsync, bool isDark, ThemeData theme, bool isMapLog) {
    return logsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (logFiles) {
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final agentLogsAsync = ref.watch(agentLogListProvider);
    final mapLogsAsync = ref.watch(mapLogListProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('System Logs', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leadingWidth: 72,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: 'Clear All Logs',
              onPressed: _clearAllLogs,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Using the decoupled SlidingSegmentedControl widget
          SlidingSegmentedControl(
            tabController: _tabController,
            isDark: isDark,
            theme: theme,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLogList(agentLogsAsync, isDark, theme, false),
                _buildLogList(mapLogsAsync, isDark, theme, true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SlidingSegmentedControl extends StatelessWidget {
  final TabController tabController;
  final bool isDark;
  final ThemeData theme;

  const SlidingSegmentedControl({
    super.key,
    required this.tabController,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: AnimatedBuilder(
        // The AnimatedBuilder MUST be here to trigger frame-by-frame updates of the offset
        animation: tabController.animation!,
        builder: (context, child) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final tabWidth = constraints.maxWidth / 2;
              final offset = tabController.animation!.value * tabWidth;

              return Stack(
                children: [
                  Positioned(
                    left: offset,
                    top: 0,
                    bottom: 0,
                    width: tabWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: theme.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      ),
                    ),
                  ),
                  // The interactive text tabs
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => tabController.animateTo(0),
                          child: Container(
                            alignment: Alignment.center,
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: tabController.index == 0 ? Colors.white : (isDark ? Colors.white54 : Colors.black54),
                              ),
                              child: const Text('Agent'),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => tabController.animateTo(1),
                          child: Container(
                            alignment: Alignment.center,
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: tabController.index == 1 ? Colors.white : (isDark ? Colors.white54 : Colors.black54),
                              ),
                              child: const Text('Map Search'),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }
          );
        }
      ),
    );
  }
}
