import 'package:flutter/material.dart';
import 'package:equity_tracker/features/category/domain/category_entity.dart';
import 'package:equity_tracker/features/transaction/domain/transaction_entity.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/stats/presentation/widgets/stats_screen/category_pie_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:equity_tracker/features/stats/presentation/widgets/stats_screen/category_legend.dart';
import 'package:equity_tracker/features/stats/presentation/widgets/stats_screen/category_progress_item.dart';
import 'package:equity_tracker/features/stats/presentation/widgets/stats_screen/category_details_modal.dart';
import 'package:equity_tracker/features/stats/presentation/providers/stats_provider.dart';

class CategoryAnalysisTab extends ConsumerWidget {
  final List<TransactionEntity> transactions; // Kept for modal details

  const CategoryAnalysisTab({
    super.key,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(categoryStatsProvider);

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
