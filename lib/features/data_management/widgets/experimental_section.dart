import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/settings/widgets/common/settings_section.dart';
import 'package:equity_tracker/features/settings/widgets/common/settings_tile.dart';
import 'package:equity_tracker/features/notion_sync/screens/notion_config_screen.dart';

class ExperimentalSection extends ConsumerWidget {
  const ExperimentalSection({super.key});

  void _showNotionConfig(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => const NotionConfigScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsSection(
      title: 'EXPERIMENTAL',
      children: [
        SettingsTile(
          icon: Icons.sync_rounded,
          iconColor: Colors.black87,
          title: 'Notion Integration',
          subtitle: 'Sync new transactions to Notion',
          onTap: () => _showNotionConfig(context),
        ),
      ],
    );
  }
}
