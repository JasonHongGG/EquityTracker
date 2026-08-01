import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/features/transaction/presentation/providers/transaction_notifier.dart';
import 'package:equity_tracker/features/category/presentation/providers/category_notifier.dart';
import 'package:equity_tracker/features/stats/domain/category_stat.dart';
import 'package:equity_tracker/features/stats/domain/calculate_category_stats_usecase.dart';

final calculateCategoryStatsUseCaseProvider = Provider<CalculateCategoryStatsUseCase>((ref) {
  return CalculateCategoryStatsUseCase();
});

final categoryAnalysisTypeProvider = StateProvider<TransactionType>((ref) => TransactionType.expense);

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
