import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/widgets/premium_config_header.dart';

import 'package:equity_tracker/features/settings/screens/settings_screen/preferences_section.dart';
import 'package:equity_tracker/features/data_management/widgets/data_management_section.dart';
import 'package:equity_tracker/features/data_management/widgets/experimental_section.dart';
import 'package:equity_tracker/features/data_management/widgets/danger_zone_section.dart';
import 'package:equity_tracker/features/app_update/widgets/app_update_section.dart';
import 'package:equity_tracker/features/ai/presentation/screens/ai_settings_screen.dart';
import 'package:equity_tracker/features/settings/widgets/common/settings_section.dart';
import 'package:equity_tracker/features/settings/widgets/common/settings_tile.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: isDark ? const Color(0xFF0F111A) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.5),
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(color: Colors.transparent),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 20),
        children: [
          const PremiumConfigHeader(
            title: 'Settings',
            subtitle: 'PREFERENCES & SYSTEM CONFIG',
            isBehindAppBar: true,
          ),
          const PreferencesSection(),
          SettingsSection(
            title: 'AI ASSISTANT',
            children: [
              SettingsTile(
                icon: Icons.smart_toy_rounded,
                iconColor: Colors.blueAccent,
                title: 'AI Configuration',
                subtitle: 'Manage API keys and models',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AiSettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          const DataManagementSection(),
          ExperimentalSection(), // Contains Notion Sync & Import
          DangerZoneSection(),
          AppUpdateSection(),
        ],
      ),
    );
  }
}
