import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/registry/settings_extension.dart';
import 'package:equity_tracker/features/settings/presentation/extensions/preferences_settings_extension.dart';
import 'package:equity_tracker/features/data_management/presentation/extensions/data_management_settings_extension.dart';
import 'package:equity_tracker/features/app_update/presentation/extensions/app_update_settings_extension.dart';

final settingsRegistryProvider = Provider<List<SettingsExtension>>((ref) {
  final extensions = [
    PreferencesSettingsExtension(),
    DataManagementSettingsExtension(),
    AppUpdateSettingsExtension(),
  ];
  
  extensions.sort((a, b) => a.sortPriority.compareTo(b.sortPriority));
  return extensions;
});
