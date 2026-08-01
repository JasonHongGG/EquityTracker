import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/registry/analytics_extension.dart';
import 'package:equity_tracker/features/trend_analysis/presentation/widgets/monthly_trend_tab.dart';

class TrendAnalyticsExtension implements AnalyticsExtension {
  @override
  String get tabTitle => 'Trend';

  @override
  IconData get tabIcon => Icons.show_chart_rounded;

  @override
  int get sortPriority => 10;

  @override
  Widget buildTabView(BuildContext context, WidgetRef ref) {
    return const MonthlyTrendTab();
  }
}
