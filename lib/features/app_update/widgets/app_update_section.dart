import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/updater/updater_notifier.dart';
import 'package:equity_tracker/features/app_update/widgets/update_dialog_helpers.dart';
import 'package:equity_tracker/features/app_update/widgets/update_status_dialog.dart';
import 'package:equity_tracker/features/app_update/widgets/already_latest_version_dialog.dart';
import 'package:equity_tracker/features/app_update/widgets/version_display_button.dart';
import 'package:equity_tracker/core/providers/package_info_provider.dart';

class AppUpdateSection extends ConsumerWidget {
  const AppUpdateSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packageInfo = ref.watch(packageInfoProvider);
    final currentAppVersion = packageInfo.version;

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

            await ref.read(githubUpdaterNotifierProvider.notifier).checkForUpdate();
            
            if (context.mounted) Navigator.of(context).pop();

            final updateState = ref.read(githubUpdaterNotifierProvider);
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
                  builder: (ctx) => AlreadyLatestVersionDialog(currentAppVersion: currentAppVersion),
                );
              }
            }
          },
        ),
      ],
    );
  }
}
