import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/settings/presentation/providers/update_notifier.dart';
import 'package:equity_tracker/core/widgets/app/update_dialog.dart';

import 'package:equity_tracker/features/settings/presentation/widgets/settings_screen/preferences_section.dart';
import 'package:equity_tracker/features/settings/presentation/widgets/settings_screen/data_management_section.dart';
import 'package:equity_tracker/features/settings/presentation/widgets/settings_screen/experimental_section.dart';
import 'package:equity_tracker/features/settings/presentation/widgets/settings_screen/danger_zone_section.dart';
import 'package:equity_tracker/features/settings/presentation/widgets/settings_screen/already_latest_version_dialog.dart';
import 'package:equity_tracker/features/settings/presentation/widgets/settings_screen/version_display_button.dart';

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
        builder: (ctx) => const AlreadyLatestVersionDialog(
          currentAppVersion: currentAppVersion,
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
            VersionDisplayButton(
              version: currentAppVersion,
              onTap: _checkForUpdate,
            ),
          ],
        ),
      ),
    );
  }
}
