import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/category_provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/stats/monthly_trend_tab.dart';
import '../widgets/stats/category_analysis_tab.dart';
import '../theme/app_colors.dart';
import '../widgets/month_selector.dart';
import '../widgets/custom_month_picker.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(filteredTransactionsProvider);
    final categoriesAsync = ref.watch(categoryListProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        appBar: AppBar(
          toolbarHeight: 65,
          title: MonthSelector(
            selectedDate: selectedMonth,
            onPrevious: () {
              ref
                  .read(selectedMonthProvider.notifier)
                  .update(
                    DateTime(selectedMonth.year, selectedMonth.month - 1),
                  );
            },
            onNext: () {
              ref
                  .read(selectedMonthProvider.notifier)
                  .update(
                    DateTime(selectedMonth.year, selectedMonth.month + 1),
                  );
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
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Trend'),
              Tab(text: 'Categories'),
            ],
          ),
        ),
        body: transactionsAsync.when(
          data: (transactions) {
            if (transactions.isEmpty) {
              return const Center(
                child: Text('No transactions for this period'),
              );
            }

            final categories = categoriesAsync.asData?.value ?? [];

            return TabBarView(
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
    );
  }
}
