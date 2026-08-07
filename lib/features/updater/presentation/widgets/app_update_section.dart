import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/updater/presentation/providers/updater_notifier.dart';
import 'package:equity_tracker/features/updater/presentation/widgets/github_updater_bottom_sheet.dart';
import 'package:equity_tracker/features/updater/presentation/widgets/version_display_button.dart';
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
          onTap: () {
            // 1. First, show the bottom sheet (it will display the initial 'Checking' state)
            showGithubUpdaterBottomSheet(context);
            
            // 2. Then trigger the update check. The bottom sheet will react to state changes automatically.
            ref.read(githubUpdaterNotifierProvider.notifier).checkForUpdate();
          },
        ),
      ],
    );
  }
}
