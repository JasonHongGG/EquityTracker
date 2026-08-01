import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/registry/analytics_extension.dart';
import 'package:equity_tracker/features/category_analysis/presentation/widgets/category_analysis_tab.dart';

class CategoryAnalyticsExtension implements AnalyticsExtension {
  @override
  String get tabTitle => 'Category';

  @override
  IconData get tabIcon => Icons.pie_chart_rounded;

  @override
  int get sortPriority => 20;

  @override
  Widget buildTabView(BuildContext context, WidgetRef ref) {
    return const CategoryAnalysisTab();
  }
}
