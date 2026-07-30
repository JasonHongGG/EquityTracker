import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/transaction/presentation/providers/transaction_notifier.dart';
import 'package:equity_tracker/features/category/presentation/providers/category_notifier.dart';
import 'package:equity_tracker/features/stats/domain/entities/category_stat_entity.dart';
import 'package:equity_tracker/features/stats/domain/usecases/calculate_category_stats_usecase.dart';
import 'package:equity_tracker/features/stats/domain/usecases/calculate_monthly_trend_usecase.dart';

final calculateCategoryStatsUseCaseProvider = Provider<CalculateCategoryStatsUseCase>((ref) {
  return CalculateCategoryStatsUseCase();
});

final calculateMonthlyTrendUseCaseProvider = Provider<CalculateMonthlyTrendUseCase>((ref) {
  return CalculateMonthlyTrendUseCase();
});

final categoryStatsProvider = FutureProvider<List<CategoryStatEntity>>((ref) async {
  final transactions = await ref.watch(filteredTransactionsProvider.future);
  final categories = await ref.watch(categoryListProvider.future);
  final useCase = ref.watch(calculateCategoryStatsUseCaseProvider);

  return useCase.execute(
    transactions: transactions,
    allCategories: categories,
  );
});

final monthlyTrendProvider = FutureProvider<MonthlyTrendResult>((ref) async {
  final transactions = await ref.watch(filteredTransactionsProvider.future);
  final month = ref.watch(selectedMonthProvider);
  final useCase = ref.watch(calculateMonthlyTrendUseCaseProvider);

  return useCase.execute(
    transactions: transactions,
    month: month,
  );
});
