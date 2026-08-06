import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/providers/usecase_providers.dart';
import 'package:equity_tracker/features/transaction/providers/transaction_notifier.dart';
import 'package:equity_tracker/core/providers/notification_provider.dart';
import 'package:equity_tracker/core/widgets/scale_button.dart';
import 'package:equity_tracker/features/settings/widgets/common/settings_section.dart';
import 'package:equity_tracker/features/settings/widgets/common/settings_tile.dart';
import 'package:equity_tracker/core/services/native_backup_service.dart';
import 'package:equity_tracker/features/data_management/providers/snapshot_notifier.dart';
import 'package:equity_tracker/features/notion_sync/controllers/notion_config_controller.dart';

class DangerZoneSection extends ConsumerStatefulWidget {
  const DangerZoneSection({super.key});

  @override
  ConsumerState<DangerZoneSection> createState() => _DangerZoneSectionState();
}

class _DangerZoneSectionState extends ConsumerState<DangerZoneSection> {
  bool _isLoading = false;

  Future<void> _clearAllData() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    
    try {
      // 1. Create a snapshot for undo via Notifier
      await ref.read(snapshotNotifierProvider.notifier).createSnapshot(SnapshotSource.clearData);
      
      // 2. Delegate to the Wipe All Data Use Case for atomic wipe
      await ref.read(wipeAllDataUseCaseProvider).execute();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notion Sync cursor reset to protect your cloud archive.')),
        );
      }

      // 3. Refresh state
      // ignore: unused_result
      ref.refresh(transactionNotifierProvider);
      ref.invalidate(titleSuggestionProvider);

      ref.read(notificationControllerProvider.notifier).showSuccess('All data cleared successfully.');
    } catch (e) {
      ref.read(notificationControllerProvider.notifier).showError('Failed to clear data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _undoClearData() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      await ref.read(snapshotNotifierProvider.notifier).restoreFromSnapshot(SnapshotSource.clearData);
      
      // Reload Notion config in case the snapshot restored the sync cursor
      await ref.read(notionConfigControllerProvider.notifier).reloadConfig();
      
      // ignore: unused_result
      ref.refresh(transactionNotifierProvider);
      ref.invalidate(titleSuggestionProvider);

      ref.read(notificationControllerProvider.notifier).showSuccess('Data restored successfully!');
      
    } catch (e) {
      ref.read(notificationControllerProvider.notifier).showError('Undo failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showClearDataConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Colors.redAccent,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Clear All Data?',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This will wipe all local data. A temporary snapshot will be created in case you need to undo.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ScaleButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ScaleButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _clearAllData();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: _isLoading 
                          ? const SizedBox(
                              width: 16, height: 16, 
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            )
                          : const Text(
                              'Delete All',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSnapshot = ref.watch(snapshotNotifierProvider.select((state) => state[SnapshotSource.clearData] ?? false));

    return SettingsSection(
      title: 'DANGER ZONE',
      children: [
        SettingsTile(
          icon: Icons.delete_forever_rounded,
          title: 'Clear All Data',
          subtitle: 'Delete all records (with undo option)',
          isDestructive: true,
          onTap: _isLoading ? null : () => _showClearDataConfirmation(context),
        ),
        if (hasSnapshot)
          SettingsTile(
            icon: Icons.undo_rounded,
            iconColor: Colors.orange,
            title: 'Undo Last Action',
            subtitle: 'Revert to previous state',
            onTap: _isLoading ? null : _undoClearData,
          ),
      ],
    );
  }
}
