import 'package:equity_tracker/features/category/domain/category_entity.dart';
import 'package:equity_tracker/features/transaction/domain/transaction_entity.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/features/stats/domain/entities/category_stat_entity.dart';

class CalculateCategoryStatsUseCase {
  List<CategoryStatEntity> execute({
    required List<TransactionEntity> transactions,
    required List<CategoryEntity> allCategories,
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

    final List<CategoryStatEntity> stats = [];
    for (var entry in categoryTotals.entries) {
      final cat = allCategories.firstWhere(
        (c) => c.id == entry.key,
        orElse: () => CategoryEntity(
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
        CategoryStatEntity(
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
