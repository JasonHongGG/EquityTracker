import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/widgets/month_navigation_bar.dart';
import 'package:equity_tracker/core/providers/analytics_registry_providers.dart';
import 'package:equity_tracker/features/transaction/presentation/providers/transaction_notifier.dart';

class AnalyticsDashboardScreen extends ConsumerWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    final extensions = ref.watch(analyticsRegistryProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F111A) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Analytics',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
      ),
      body: DefaultTabController(
        length: extensions.length,
        child: Column(
          children: [
            MonthNavigationBar(
              selectedDate: ref.watch(selectedMonthProvider),
              onPrevious: () {
                final current = ref.read(selectedMonthProvider);
                ref.read(selectedMonthProvider.notifier).state =
                    DateTime(current.year, current.month - 1);
              },
              onNext: () {
                final current = ref.read(selectedMonthProvider);
                ref.read(selectedMonthProvider.notifier).state =
                    DateTime(current.year, current.month + 1);
              },
              onSearch: () {},
              onClearSearch: () {},
              enableSearch: false,
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: primaryColor.withValues(alpha: 0.15),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: primaryColor,
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.bold,
                ),
                tabs: extensions.map((ext) {
                  return Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(ext.tabIcon, size: 20),
                        const SizedBox(width: 8),
                        Text(ext.tabTitle),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: extensions.map((ext) {
                  return ext.buildTabView(context, ref);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
