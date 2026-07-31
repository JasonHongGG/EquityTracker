import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class AnalyticsExtension {
  String get tabTitle;
  IconData get tabIcon;
  int get sortPriority;
  Widget buildTabView(BuildContext context, WidgetRef ref);
}
