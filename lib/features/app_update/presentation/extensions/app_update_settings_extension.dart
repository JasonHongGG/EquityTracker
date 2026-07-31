import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/registry/settings_extension.dart';
import 'package:equity_tracker/features/app_update/presentation/providers/update_notifier.dart';
import 'package:equity_tracker/features/app_update/presentation/widgets/update_dialog_helpers.dart';
import 'package:equity_tracker/features/app_update/presentation/widgets/update_status_dialog.dart';
import 'package:equity_tracker/features/app_update/presentation/widgets/already_latest_version_dialog.dart';
import 'package:equity_tracker/features/app_update/presentation/widgets/version_display_button.dart';

class AppUpdateSettingsExtension implements SettingsExtension {
  @override
  int get sortPriority => 99; // 放在最下面

  @override
  Widget buildSection(BuildContext context, WidgetRef ref) {
    const currentAppVersion = '1.0.0'; // 或者從某處讀取

    return Column(
      children: [
        const SizedBox(height: 20),
        VersionDisplayButton(
          version: currentAppVersion,
          onTap: () async {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => const UpdateStatusDialog(message: '正在檢查 GitHub 版本...'),
            );

            await ref.read(updateNotifierProvider.notifier).checkForUpdate();
            
            if (context.mounted) Navigator.of(context).pop();

            final updateState = ref.read(updateNotifierProvider);
            if (updateState.hasUpdate && updateState.releaseInfo?.downloadUrl != null) {
              if (context.mounted) await showUpdateDialog(context);
            } else if (updateState.error != null) {
              if (context.mounted) {
                await showDialog(
                  context: context,
                  builder: (ctx) => UpdateStatusDialog(message: updateState.error!, isError: true),
                );
              }
            } else {
              if (context.mounted) {
                await showDialog(
                  context: context,
                  builder: (ctx) => const AlreadyLatestVersionDialog(currentAppVersion: currentAppVersion),
                );
              }
            }
          },
        ),
      ],
    );
  }
}
