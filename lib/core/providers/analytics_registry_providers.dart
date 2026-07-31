import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/registry/analytics_extension.dart';
import 'package:equity_tracker/features/category_analysis/presentation/extensions/category_analytics_extension.dart';
import 'package:equity_tracker/features/trend_analysis/presentation/extensions/trend_analytics_extension.dart';

final analyticsRegistryProvider = Provider<List<AnalyticsExtension>>((ref) {
  final extensions = [
    CategoryAnalyticsExtension(),
    TrendAnalyticsExtension(),
  ];
  
  extensions.sort((a, b) => a.sortPriority.compareTo(b.sortPriority));
  return extensions;
});
