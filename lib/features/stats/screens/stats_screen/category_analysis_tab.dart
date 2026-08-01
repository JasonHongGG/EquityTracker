import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/transaction/providers/transaction_notifier.dart' as equity_tracker_transaction_notifier;
import 'package:equity_tracker/features/stats/widgets/stats_screen/category_pie_chart.dart';
import 'package:equity_tracker/features/stats/widgets/stats_screen/category_legend.dart';
import 'package:equity_tracker/features/stats/widgets/stats_screen/category_progress_item.dart';
import 'package:equity_tracker/features/stats/widgets/stats_screen/category_details_modal.dart';
import 'package:equity_tracker/features/stats/providers/category_analysis_provider.dart';
import 'package:equity_tracker/core/widgets/segmented_type_tab.dart';

class CategoryAnalysisTab extends ConsumerWidget {
  const CategoryAnalysisTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(categoryStatsProvider);
    final transactionsAsync = ref.watch(equity_tracker_transaction_notifier.filteredTransactionsProvider);
    final transactions = transactionsAsync.value ?? [];
    final currentType = ref.watch(categoryAnalysisTypeProvider);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: SegmentedTypeTab(
              selectedType: currentType,
              onChanged: (type) {
                ref.read(categoryAnalysisTypeProvider.notifier).state = type;
              },
            ),
          ),
        ),
        statsAsync.when(
          data: (stats) {
            if (stats.isEmpty) {
              return SliverFillRemaining(
                child: Center(
                  child: Text('No ${currentType.name} categories'),
                ),
              );
            }

            final totalAmount = stats.fold<int>(0, (sum, stat) => sum + stat.totalAmount);

            return SliverList(
              delegate: SliverChildListDelegate([
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 220,
                        child: CategoryPieChart(
                          stats: stats,
                          totalAmount: totalAmount,
                        ),
                      ),
                      const SizedBox(height: 16),
                      CategoryLegend(stats: stats),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                ...stats.map((stat) {
                  return CategoryProgressItem(
                    category: stat.category,
                    amount: stat.totalAmount,
                    percent: stat.percentage,
                    onTap: () {
                      CategoryDetailsModal.show(context, stat.category, transactions);
                    },
                  );
                }),
                const SizedBox(height: 80),
              ]),
            );
          },
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, stack) => SliverFillRemaining(
            child: Center(child: Text('Error: $err')),
          ),
        ),
      ],
    );
  }
}

