import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/providers/package_info_provider.dart';
import 'package:equity_tracker/core/updater/updater_notifier.dart';
import 'package:equity_tracker/core/updater/widgets/updater_dialogs.dart';

/// A completely decoupled button that displays the current app version
/// and triggers the GitHub update check process when tapped.
class GithubUpdateCheckerButton extends ConsumerWidget {
  const GithubUpdateCheckerButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Use the real version from package_info_plus!
    final packageInfo = ref.watch(packageInfoProvider);
    final currentAppVersion = packageInfo.version;

    return Center(
      child: GestureDetector(
        onTap: () async {
          // Show checking status
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => const UpdaterStatusDialog(message: '正在檢查版本...'),
          );

          final notifier = ref.read(githubUpdaterNotifierProvider.notifier);
          await notifier.checkForUpdate();

          // Close checking dialog
          if (context.mounted) Navigator.of(context).pop();

          final state = ref.read(githubUpdaterNotifierProvider);
          if (state.hasUpdate && state.releaseInfo?.downloadUrl != null) {
            if (context.mounted) await showGithubUpdaterPrompt(context);
          } else if (state.error != null) {
            if (context.mounted) {
              await showDialog(
                context: context,
                builder: (ctx) => UpdaterStatusDialog(message: state.error!, isError: true),
              );
            }
          } else {
            if (context.mounted) {
              await showDialog(
                context: context,
                builder: (ctx) => UpdaterAlreadyLatestDialog(currentVersion: currentAppVersion),
              );
            }
          }
        },
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
    );
  }
}
