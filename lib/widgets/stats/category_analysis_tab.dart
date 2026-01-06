import 'package:flutter/material.dart';
import '../../models/category_model.dart';
import '../../models/transaction_model.dart';
import '../../models/transaction_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'category_pie_chart.dart';
import '../transaction_item.dart'; // Reuse for modal

class CategoryAnalysisTab extends ConsumerWidget {
  final List<TransactionModel> transactions;
  final List<Category> allCategories;

  const CategoryAnalysisTab({
    super.key,
    required this.transactions,
    required this.allCategories,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Calculate Totals by Category
    final Map<String, int> categoryTotals = {};
    int totalExpense = 0;

    for (var t in transactions) {
      // Focus on Expense for analysis? Or both?
      // Usually "Analysis" is Expense focused. Let's do Expense only for the Chart.
      if (t.type == TransactionType.expense) {
        categoryTotals[t.categoryId] =
            (categoryTotals[t.categoryId] ?? 0) + t.amount;
        totalExpense += t.amount;
      }
    }

    // 2. Map to Objects
    final List<MapEntry<Category, int>> sortedEntries = [];
    for (var entry in categoryTotals.entries) {
      final cat = allCategories.firstWhere(
        (c) => c.id == entry.key,
        orElse: () => Category(
          id: 'unknown',
          name: 'Unknown',
          iconCodePoint: 0,
          colorValue: 0xFF9E9E9E,
          type: TransactionType.expense,
          isSystem: false,
          isEnabled: true,
        ),
      );
      sortedEntries.add(MapEntry(cat, entry.value));
    }
    sortedEntries.sort((a, b) => b.value.compareTo(a.value));

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
                    data: sortedEntries,
                    totalAmount: totalExpense,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: sortedEntries.map((entry) {
                    final cat = entry.key;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cat.color,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          cat.name,
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white70
                                : Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),

        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final entry = sortedEntries[index];
            final cat = entry.key;
            final amount = entry.value;
            final percent = totalExpense > 0 ? (amount / totalExpense) : 0.0;

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: cat.color.withOpacity(0.2),
                child: Icon(cat.iconData, color: cat.color, size: 20),
              ),
              title: Text(cat.name),
              subtitle: LinearProgressIndicator(
                value: percent.toDouble(),
                backgroundColor: Colors.grey.withOpacity(0.1),
                color: cat.color,
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
              ),
              trailing: Text(
                '\$$amount',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              onTap: () {
                _showCategoryDetails(context, cat, transactions);
              },
            );
          }, childCount: sortedEntries.length),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
      ],
    );
  }

  void _showCategoryDetails(
    BuildContext context,
    Category category,
    List<TransactionModel> allTransactions,
  ) {
    final categoryTransactions =
        allTransactions.where((t) => t.categoryId == category.id).toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(category.iconData, color: category.color),
                        const SizedBox(width: 10),
                        Text(
                          category.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: categoryTransactions.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 70, endIndent: 16),
                      itemBuilder: (context, index) {
                        return TransactionItem(
                          transaction: categoryTransactions[index],
                          onTap: () {}, // No action in modal for now
                          showDate: true,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
