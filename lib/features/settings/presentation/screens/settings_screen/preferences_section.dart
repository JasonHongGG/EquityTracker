import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/settings/presentation/providers/settings_notifier.dart';
import 'package:equity_tracker/features/settings/presentation/widgets/common/settings_section.dart';
import 'package:equity_tracker/features/settings/presentation/widgets/common/settings_tile.dart';

class PreferencesSection extends ConsumerWidget {
  const PreferencesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeAsync = ref.watch(settingsNotifierProvider);

    return SettingsSection(
      title: 'PREFERENCES',
      children: [
        SettingsTile(
          icon: Icons.dark_mode_rounded,
          iconColor: Colors.purpleAccent,
          title: 'Dark Mode',
          trailing: themeModeAsync.when(
            data: (settings) => Switch(
              value: settings.themeMode == ThemeMode.dark,
              onChanged: (val) {
                ref
                    .read(settingsNotifierProvider.notifier)
                    .setThemeMode(
                      val ? ThemeMode.dark : ThemeMode.light,
                    );
              },
            ),
            loading: () => const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (e, s) => const Icon(Icons.error, size: 20),
          ),
        ),
        SettingsTile(
          icon: Icons.security_rounded,
          iconColor: const Color(0xFF34C759), // iOS Green
          title: 'Privacy Mode',
          subtitle: 'Hide balance on dashboard',
          trailing: themeModeAsync.when(
            data: (settings) => Switch(
              value: settings.isPrivacyModeEnabled,
              onChanged: (val) {
                ref.read(settingsNotifierProvider.notifier).setPrivacyMode(val);
              },
            ),
            loading: () => const SizedBox(height: 0),
            error: (e, s) => const SizedBox(height: 0),
          ),
        ),
        SettingsTile(
          icon: Icons.currency_exchange,
          iconColor: Colors.amber,
          title: 'Currency Symbol',
          subtitle: '\$ (USD)',
        ),
      ],
    );
  }
}
