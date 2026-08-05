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
          height: 320, // Increased to accommodate the legend
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
              // Title removed (now inside PieChart)
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
        return Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: CategoryPieChart(
                  stats: stats,
                  totalAmount: totalAmount,
                  currencySymbol: currencySymbol,
                  type: type,
                ),
              ),
            ),
            if (stats.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: CategoryLegend(stats: stats),
              ),
          ],
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
          return const SizedBox.shrink();
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: stats.length,
          itemBuilder: (context, index) {
            final stat = stats[index];
            final item = CategoryProgressItem(
              category: stat.category,
              amount: stat.totalAmount,
              percent: stat.percentage,
              currencySymbol: currencySymbol,
              onTap: () {
                CategoryDetailsModal.show(context, stat.category, transactions);
              },
            );
            
            return StaggeredEntryItem(
              index: index,
              child: item,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}

// ============================================================================
// STAGGERED ENTRY ANIMATION WRAPPER
// ============================================================================
class StaggeredEntryItem extends StatefulWidget {
  final Widget child;
  final int index;

  const StaggeredEntryItem({super.key, required this.child, required this.index});

  @override
  State<StaggeredEntryItem> createState() => _StaggeredEntryItemState();
}

class _StaggeredEntryItemState extends State<StaggeredEntryItem> {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    // Stagger delay: 50ms per index
    Future.delayed(Duration(milliseconds: widget.index * 50), () {
      if (mounted) {
        setState(() {
          _isVisible = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: _isVisible ? Offset.zero : const Offset(0, 0.2), // Slide up slightly
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _isVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

