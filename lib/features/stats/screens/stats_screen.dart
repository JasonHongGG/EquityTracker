import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:equity_tracker/core/widgets/month_navigation_bar.dart';
import 'package:equity_tracker/core/widgets/segment_tab_selector.dart';
import 'package:equity_tracker/core/widgets/pickers/date_time_wheel_picker.dart';
import 'package:equity_tracker/core/widgets/search_dialog.dart';

import 'package:equity_tracker/features/transaction/providers/transaction_notifier.dart';
import 'package:equity_tracker/features/stats/screens/stats_screen/monthly_trend_tab.dart';
import 'package:equity_tracker/features/stats/screens/stats_screen/category_analysis_tab.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedMonth = ref.watch(selectedMonthProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F111A) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        centerTitle: true,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: MonthNavigationBar(
          onSettings: () {
            context.push('/settings');
          },
          selectedDate: selectedMonth,
          onPrevious: () {
            ref.read(selectedMonthProvider.notifier).update(
                DateTime(selectedMonth.year, selectedMonth.month - 1));
          },
          onNext: () {
            ref.read(selectedMonthProvider.notifier).update(
                DateTime(selectedMonth.year, selectedMonth.month + 1));
          },
          onSearch: () {
            showDialog(
              context: context,
              builder: (context) {
                return SearchDialog(
                  subtitle: 'Find transactions by title or note',
                  initialQuery:
                      ref.read(transactionFilterProvider).searchQuery ?? '',
                  onChanged: (value) {
                    ref.read(transactionFilterProvider.notifier).update(
                          ref
                              .read(transactionFilterProvider)
                              .copyWith(searchQuery: value),
                        );
                  },
                  onClear: () {
                    ref.read(transactionFilterProvider.notifier).update(
                          ref
                              .read(transactionFilterProvider)
                              .copyWith(searchQuery: ''),
                        );
                    Navigator.pop(context);
                  },
                );
              },
            );
          },
          onClearSearch: () {
            ref.read(transactionFilterProvider.notifier).update(
                  ref.read(transactionFilterProvider).copyWith(searchQuery: ''),
                );
          },
          enableSearch: true,
          onTitleTap: () async {
            final newDate = await showCustomDateTimePicker(
              context: context,
              initialDate: selectedMonth,
              showYear: true,
              showMonth: true,
            );
            if (newDate != null) {
              ref.read(selectedMonthProvider.notifier).update(newDate);
            }
          },
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          CustomTabSelector(
            controller: _tabController,
            tabs: const ['Trend', 'Category'],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                MonthlyTrendTab(),
                CategoryAnalysisTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
