import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/features/transaction/providers/transaction_notifier.dart';
import 'package:equity_tracker/features/category/providers/category_notifier.dart';
import 'package:equity_tracker/features/stats/domain/category_stat.dart';
import 'package:equity_tracker/features/stats/domain/calculate_category_stats_usecase.dart';

final calculateCategoryStatsUseCaseProvider = Provider<CalculateCategoryStatsUseCase>((ref) {
  return CalculateCategoryStatsUseCase();
});

class CategoryAnalysisTypeNotifier extends Notifier<TransactionType> {
  @override
  TransactionType build() => TransactionType.expense;

  void updateType(TransactionType type) {
    state = type;
  }
}

final categoryAnalysisTypeProvider = NotifierProvider<CategoryAnalysisTypeNotifier, TransactionType>(
  CategoryAnalysisTypeNotifier.new,
);

final categoryStatsProvider = FutureProvider<List<CategoryStat>>((ref) async {
  final transactionsAsync = ref.watch(filteredTransactionsProvider);
  final categoriesAsync = ref.watch(categoryListProvider);
  final useCase = ref.watch(calculateCategoryStatsUseCaseProvider);
  final type = ref.watch(categoryAnalysisTypeProvider);

  return useCase.execute(
    transactions: transactionsAsync.value ?? [],
    allCategories: categoriesAsync.value ?? [],
    type: type,
  );
});
