

import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/features/stats/domain/category_stat.dart';
import 'package:equity_tracker/features/transaction/data/transaction_model.dart';
import 'package:equity_tracker/features/category/data/category_model.dart';

class CalculateCategoryStatsUseCase {
  List<CategoryStat> execute({
    required List<TransactionModel> transactions,
    required List<CategoryModel> allCategories,
  }) {
    final Map<String, int> categoryTotals = {};
    int totalExpense = 0;

    for (var t in transactions) {
      if (t.type == TransactionType.expense) {
        categoryTotals[t.categoryId] =
            (categoryTotals[t.categoryId] ?? 0) + t.amount;
        totalExpense += t.amount;
      }
    }

    final List<CategoryStat> stats = [];
    for (var entry in categoryTotals.entries) {
      final cat = allCategories.firstWhere(
        (c) => c.id == entry.key,
        orElse: () => CategoryModel(
          id: 'unknown',
          name: 'Unknown',
          iconCodePoint: 0,
          colorValue: 0xFF9E9E9E,
          type: TransactionType.expense,
          isSystem: false,
          isEnabled: true,
        ),
      );
      
      final percent = totalExpense > 0 ? (entry.value / totalExpense) : 0.0;
      
      stats.add(
        CategoryStat(
          category: cat,
          totalAmount: entry.value,
          percentage: percent,
        ),
      );
    }
    
    stats.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    return stats;
  }
}
