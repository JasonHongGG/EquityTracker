import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/registry/settings_extension.dart';
import 'package:equity_tracker/features/settings/presentation/widgets/settings_screen/preferences_section.dart';

class PreferencesSettingsExtension implements SettingsExtension {
  @override
  int get sortPriority => 10; // 最上面

  @override
  Widget buildSection(BuildContext context, WidgetRef ref) {
    return const PreferencesSection();
  }
}
