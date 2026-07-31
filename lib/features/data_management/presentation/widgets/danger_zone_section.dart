import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:equity_tracker/core/providers/repository_providers.dart';
import 'package:equity_tracker/features/transaction/presentation/providers/transaction_notifier.dart';
import 'package:equity_tracker/core/widgets/toast_notification.dart';
import 'package:equity_tracker/core/widgets/scale_button.dart';
import 'package:equity_tracker/features/settings/presentation/widgets/common/settings_section.dart';
import 'package:equity_tracker/features/settings/presentation/widgets/common/settings_tile.dart';

class DangerZoneSection extends ConsumerWidget {
  const DangerZoneSection({super.key});

  Future<void> _clearAllData(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(transactionRepositoryProvider).clearAllTransactions();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_import_ids');
      await prefs.remove('notion_last_sync_time');
      await prefs.remove('notion_last_pull_ids');
      await prefs.remove('notion_prev_sync_time');

      // ignore: unused_result
      ref.refresh(transactionNotifierProvider);
      // ignore: unused_result
      ref.refresh(recentTitlesProvider); 

      if (context.mounted) {
        ToastService.showSuccess(context, 'All data cleared.');
      }
    } catch (e) {
      if (context.mounted) {
        ToastService.showError(context, 'Failed to clear data: $e');
      }
    }
  }

  void _showClearDataConfirmation(BuildContext context, WidgetRef ref) {
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
                  color: Colors.redAccent.withOpacity(0.1),
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
                'This action cannot be undone. All transactions will be permanently deleted.',
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
                          color: Colors.grey.withOpacity(0.1),
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
                        await _clearAllData(context, ref);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Text(
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
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsSection(
      title: 'DANGER ZONE',
      children: [
        SettingsTile(
          icon: Icons.delete_forever_rounded,
          iconColor: Colors.red,
          title: 'Clear All Data',
          subtitle: 'Permanently delete all records',
          isDestructive: true,
          onTap: () => _showClearDataConfirmation(context, ref),
        ),
      ],
    );
  }
}
