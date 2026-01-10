import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/category_provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/stats/monthly_trend_tab.dart';
import '../widgets/stats/category_analysis_tab.dart';
import '../theme/app_colors.dart';
import '../widgets/month_selector.dart';
import '../widgets/custom_month_picker.dart';
import '../widgets/custom_tab_selector.dart';

import 'settings_screen.dart';

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
    final transactionsAsync = ref.watch(filteredTransactionsProvider);
    final categoriesAsync = ref.watch(categoryListProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        toolbarHeight: 65,
        elevation: 0,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: MonthSelector(
          onSettings: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
          selectedDate: selectedMonth,
          onPrevious: () {
            ref
                .read(selectedMonthProvider.notifier)
                .update(DateTime(selectedMonth.year, selectedMonth.month - 1));
          },
          onNext: () {
            ref
                .read(selectedMonthProvider.notifier)
                .update(DateTime(selectedMonth.year, selectedMonth.month + 1));
          },
          onSearch: () {},
          onClearSearch: () {},
          enableSearch: false,
          onTitleTap: () async {
            final newDate = await showCustomMonthPicker(
              context: context,
              initialDate: selectedMonth,
            );
            if (newDate != null) {
              ref.read(selectedMonthProvider.notifier).update(newDate);
            }
          },
        ),
      ),
      body: Column(
        children: [
          // Custom Bubble/Segmented Tab
          Center(
            child: CustomTabSelector(
              controller: _tabController,
              tabs: const ['Trend', 'Categories'],
            ),
          ),

          Expanded(
            child: transactionsAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const Center(
                    child: Text('No transactions for this period'),
                  );
                }

                final categories = categoriesAsync.asData?.value ?? [];

                return TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    // Tab 1: Trend
                    MonthlyTrendTab(
                      transactions: transactions,
                      month: selectedMonth,
                    ),

                    // Tab 2: Categories
                    CategoryAnalysisTab(
                      transactions: transactions,
                      allCategories: categories,
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
