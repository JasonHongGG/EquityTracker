import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Dark Mode'),
            trailing: themeModeAsync.when(
              data: (mode) => Switch(
                value: mode == ThemeMode.dark,
                onChanged: (val) {
                  ref
                      .read(settingsProvider.notifier)
                      .setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                },
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, s) => const Icon(Icons.error),
            ),
          ),
          // Placeholder for Date Format / Currency if needed
          const ListTile(
            title: Text('Currency Symbol'),
            subtitle: Text('\$ (Default)'),
          ),
        ],
      ),
    );
  }
}
