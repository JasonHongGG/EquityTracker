import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/transaction/presentation/providers/transaction_notifier.dart' as equity_tracker_transaction_notifier;
import 'package:equity_tracker/features/category_analysis/presentation/widgets/category_pie_chart.dart';
import 'package:equity_tracker/features/category_analysis/presentation/widgets/category_legend.dart';
import 'package:equity_tracker/features/category_analysis/presentation/widgets/category_progress_item.dart';
import 'package:equity_tracker/features/category_analysis/presentation/widgets/category_details_modal.dart';
import 'package:equity_tracker/features/category_analysis/presentation/providers/category_analysis_provider.dart';

class CategoryAnalysisTab extends ConsumerWidget {
  const CategoryAnalysisTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(categoryStatsProvider);
    final transactionsAsync = ref.watch(equity_tracker_transaction_notifier.filteredTransactionsProvider);
    final transactions = transactionsAsync.value ?? [];

    return statsAsync.when(
      data: (stats) {
        if (stats.isEmpty) {
          return const Center(child: Text('No expense categories'));
        }

        final totalExpense = stats.fold<int>(0, (sum, stat) => sum + stat.totalAmount);

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    SizedBox(
                      height: 220,
                      child: CategoryPieChart(
                        stats: stats,
                        totalAmount: totalExpense,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CategoryLegend(stats: stats),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final stat = stats[index];
                return CategoryProgressItem(
                  category: stat.category,
                  amount: stat.totalAmount,
                  percent: stat.percentage,
                  onTap: () {
                    CategoryDetailsModal.show(context, stat.category, transactions);
                  },
                );
              }, childCount: stats.length),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}
