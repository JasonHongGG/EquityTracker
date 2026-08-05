import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/transaction/providers/transaction_notifier.dart' as equity_tracker_transaction_notifier;
import 'package:equity_tracker/features/stats/screens/stats_screen/category_pie_chart.dart';
import 'package:equity_tracker/features/stats/screens/stats_screen/category_legend.dart';
import 'package:equity_tracker/features/stats/screens/stats_screen/category_progress_item.dart';
import 'package:equity_tracker/features/stats/screens/stats_screen/category_details_modal.dart';
import 'package:equity_tracker/features/stats/providers/category_analysis_provider.dart';
import 'package:equity_tracker/features/settings/providers/settings_notifier.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';

class CategoryAnalysisTab extends ConsumerStatefulWidget {
  const CategoryAnalysisTab({super.key});

  @override
  ConsumerState<CategoryAnalysisTab> createState() => _CategoryAnalysisTabState();
}

class _CategoryAnalysisTabState extends ConsumerState<CategoryAnalysisTab> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentType = ref.watch(categoryAnalysisTypeProvider);
    final targetPage = currentType == TransactionType.expense ? 0 : 1;

    // Sync PageController when provider type changes
    if (_pageController.hasClients) {
      if ((_pageController.page ?? 0).round() != targetPage) {
        _pageController.animateToPage(
          targetPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      _pageController = PageController(initialPage: targetPage);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // 1. Swipeable Chart Area (Fixed at Top)
        SizedBox(
          height: 250,
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              final newType = index == 0 ? TransactionType.expense : TransactionType.income;
              if (currentType != newType) {
                ref.read(categoryAnalysisTypeProvider.notifier).updateType(newType);
              }
            },
            children: [
              _buildChart(TransactionType.expense, ref),
              _buildChart(TransactionType.income, ref),
            ],
          ),
        ),
        
        // 2. Swipe Indicator & Title
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chevron_left, 
                    color: currentType == TransactionType.income ? (isDark ? Colors.white54 : Colors.black54) : Colors.transparent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: Text(
                      currentType == TransactionType.expense ? 'Expense' : 'Income',
                      key: ValueKey(currentType),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right, 
                    color: currentType == TransactionType.expense ? (isDark ? Colors.white54 : Colors.black54) : Colors.transparent,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Page Dots Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: currentType == TransactionType.expense 
                          ? (isDark ? Colors.white : Colors.black87) 
                          : (isDark ? Colors.white24 : Colors.black12),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: currentType == TransactionType.income 
                          ? (isDark ? Colors.white : Colors.black87) 
                          : (isDark ? Colors.white24 : Colors.black12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // 3. Animated List Area (Takes remaining space)
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _CategoryAnalysisList(
              key: ValueKey(currentType), 
              type: currentType
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChart(TransactionType type, WidgetRef ref) {
    final statsAsync = ref.watch(categoryStatsProvider(type));
    final settingsAsync = ref.watch(settingsNotifierProvider);
    final currencySymbol = settingsAsync.value?.currencySymbol ?? '\$';

    return statsAsync.when(
      data: (stats) {
        final totalAmount = stats.fold<int>(0, (sum, stat) => sum + stat.totalAmount);
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: CategoryPieChart(
            stats: stats,
            totalAmount: totalAmount,
            currencySymbol: currencySymbol,
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}

class _CategoryAnalysisList extends ConsumerWidget {
  final TransactionType type;

  const _CategoryAnalysisList({super.key, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(categoryStatsProvider(type));
    final transactionsAsync = ref.watch(equity_tracker_transaction_notifier.filteredTransactionsProvider);
    final transactions = transactionsAsync.value ?? [];
    final settingsAsync = ref.watch(settingsNotifierProvider);
    final currencySymbol = settingsAsync.value?.currencySymbol ?? '\$';

    return statsAsync.when(
      data: (stats) {
        if (stats.isEmpty) {
          return Center(
            child: Text(
              'No ${type.name} categories',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black54,
                fontSize: 16,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: stats.length + 1, // +1 for the legend at the top
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: CategoryLegend(stats: stats),
              );
            }
            final stat = stats[index - 1];
            return CategoryProgressItem(
              category: stat.category,
              amount: stat.totalAmount,
              percent: stat.percentage,
              currencySymbol: currencySymbol,
              onTap: () {
                CategoryDetailsModal.show(context, stat.category, transactions);
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}

