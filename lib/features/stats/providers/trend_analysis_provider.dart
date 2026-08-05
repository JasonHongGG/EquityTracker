import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/transaction/providers/transaction_notifier.dart';
import 'package:equity_tracker/features/stats/domain/calculate_monthly_trend_usecase.dart';

final calculateMonthlyTrendUseCaseProvider = Provider<CalculateMonthlyTrendUseCase>((ref) {
  return CalculateMonthlyTrendUseCase();
});

final monthlyTrendProvider = Provider<AsyncValue<MonthlyTrendResult>>((ref) {
  final transactionsAsync = ref.watch(filteredTransactionsProvider);
  final month = ref.watch(selectedMonthProvider);
  final useCase = ref.watch(calculateMonthlyTrendUseCaseProvider);

  return transactionsAsync.whenData((transactions) {
    return useCase.execute(
      transactions: transactions,
      month: month,
    );
  });
});
