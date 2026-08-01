import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:equity_tracker/features/settings/screens/settings_screen/preferences_section.dart';
import 'package:equity_tracker/features/data_management/widgets/data_management_section.dart';
import 'package:equity_tracker/features/data_management/widgets/experimental_section.dart';
import 'package:equity_tracker/features/data_management/widgets/danger_zone_section.dart';
import 'package:equity_tracker/features/app_update/widgets/app_update_section.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      body: ListView(
        padding: const EdgeInsets.only(bottom: 20),
        children: const [
          PreferencesSection(),
          DataManagementSection(),
          ExperimentalSection(), // Contains Notion Sync & Import
          DangerZoneSection(),
          AppUpdateSection(),
        ],
      ),
    );
  }
}
