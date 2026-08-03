import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:equity_tracker/core/widgets/month_selector_title.dart';
import 'package:equity_tracker/core/widgets/segment_tab_selector.dart';
import 'package:equity_tracker/core/widgets/pickers/date_time_wheel_picker.dart';
import 'package:equity_tracker/core/widgets/search_dialog.dart';

import 'package:equity_tracker/features/transaction/providers/transaction_notifier.dart';
import 'package:equity_tracker/features/stats/screens/stats_screen/monthly_trend_tab.dart';
import 'package:equity_tracker/features/stats/screens/stats_screen/category_analysis_tab.dart';
import 'package:equity_tracker/features/stats/providers/stats_tab_provider.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedMonth = ref.watch(selectedMonthProvider);
    final currentTab = ref.watch(statsTabProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F111A) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        centerTitle: true,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            context.push('/settings');
          },
          icon: Icon(
            Icons.settings_outlined,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        title: MonthSelectorTitle(
          selectedDate: selectedMonth,
          onPrevious: () {
            ref.read(selectedMonthProvider.notifier).update(
                DateTime(selectedMonth.year, selectedMonth.month - 1));
          },
          onNext: () {
            ref.read(selectedMonthProvider.notifier).update(
                DateTime(selectedMonth.year, selectedMonth.month + 1));
          },
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
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Theme(
                data: Theme.of(context).copyWith(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: IconButton(
                  onPressed: () {
                    ref.read(statsTabProvider.notifier).toggle();
                  },
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    currentTab == StatsTab.trend 
                        ? Icons.pie_chart_outline_rounded 
                        : Icons.show_chart_rounded,
                    color: isDark ? Colors.white70 : Colors.black54,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Theme(
                data: Theme.of(context).copyWith(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: IconButton(
                  onPressed: () {
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
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.search,
                    color: isDark ? Colors.white70 : Colors.black54,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                child: currentTab == StatsTab.trend 
                    ? const MonthlyTrendTab(key: ValueKey('trend'))
                    : const CategoryAnalysisTab(key: ValueKey('category')),
              ),
            ),
          ],
        ),
    );
  }
}
