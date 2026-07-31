import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/transaction/presentation/providers/transaction_notifier.dart';
import 'package:equity_tracker/features/category/presentation/providers/category_notifier.dart';
import 'package:equity_tracker/features/stats/domain/category_stat_entity.dart';
import 'package:equity_tracker/features/stats/domain/calculate_category_stats_usecase.dart';
import 'package:equity_tracker/features/stats/domain/calculate_monthly_trend_usecase.dart';

final calculateCategoryStatsUseCaseProvider = Provider<CalculateCategoryStatsUseCase>((ref) {
  return CalculateCategoryStatsUseCase();
});

final calculateMonthlyTrendUseCaseProvider = Provider<CalculateMonthlyTrendUseCase>((ref) {
  return CalculateMonthlyTrendUseCase();
});

final categoryStatsProvider = FutureProvider<List<CategoryStatEntity>>((ref) async {
  final transactionsAsync = ref.watch(filteredTransactionsProvider);
  final categoriesAsync = ref.watch(categoryListProvider);
  final useCase = ref.watch(calculateCategoryStatsUseCaseProvider);

  return useCase.execute(
    transactions: transactionsAsync.value ?? [],
    allCategories: categoriesAsync.value ?? [],
  );
});

final monthlyTrendProvider = FutureProvider<MonthlyTrendResult>((ref) async {
  final transactionsAsync = ref.watch(filteredTransactionsProvider);
  final month = ref.watch(selectedMonthProvider);
  final useCase = ref.watch(calculateMonthlyTrendUseCaseProvider);

  return useCase.execute(
    transactions: transactionsAsync.value ?? [],
    month: month,
  );
});
