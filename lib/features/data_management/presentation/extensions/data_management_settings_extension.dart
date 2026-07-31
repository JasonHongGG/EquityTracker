import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/registry/settings_extension.dart';
import 'package:equity_tracker/features/data_management/presentation/widgets/data_management_section.dart';
import 'package:equity_tracker/features/data_management/presentation/widgets/danger_zone_section.dart';
import 'package:equity_tracker/features/data_management/presentation/widgets/experimental_section.dart';

class DataManagementSettingsExtension implements SettingsExtension {
  @override
  int get sortPriority => 20;

  @override
  Widget buildSection(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const DataManagementSection(),
        const ExperimentalSection(),
        const DangerZoneSection(),
      ],
    );
  }
}
