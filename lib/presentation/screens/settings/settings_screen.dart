import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/presentation/providers/update_notifier.dart';
import 'package:equity_tracker/presentation/widgets/app/update_dialog.dart';

import 'package:equity_tracker/presentation/widgets/settings/preferences_section.dart';
import 'package:equity_tracker/presentation/widgets/settings/data_management_section.dart';
import 'package:equity_tracker/presentation/widgets/settings/experimental_section.dart';
import 'package:equity_tracker/presentation/widgets/settings/danger_zone_section.dart';

const currentAppVersion = '1.0.0';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Future<void> _checkForUpdate() async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const UpdateStatusDialog(message: '正在檢查 GitHub 版本...'),
    );

    await ref.read(updateNotifierProvider.notifier).checkForUpdate();

    if (!mounted) return;
    Navigator.of(context).pop();

    final updateState = ref.read(updateNotifierProvider);

    if (updateState.hasUpdate && updateState.releaseInfo?.downloadUrl != null) {
      await showUpdateDialog(context);
    } else if (updateState.error != null) {
      await showDialog(
        context: context,
        builder: (ctx) => UpdateStatusDialog(message: updateState.error!, isError: true),
      );
    } else {
      await showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.green,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '已是最新版本',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '目前使用版本 $currentAppVersion',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('太棒了'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F111A) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          children: [
            const PreferencesSection(),
            const DataManagementSection(),
            const ExperimentalSection(),
            const DangerZoneSection(),

            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: _checkForUpdate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Version $currentAppVersion',
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontFamily: 'Outfit',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
