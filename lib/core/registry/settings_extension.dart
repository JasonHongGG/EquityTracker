import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class SettingsExtension {
  int get sortPriority;
  Widget buildSection(BuildContext context, WidgetRef ref);
}
