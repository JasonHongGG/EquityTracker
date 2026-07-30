import 'package:equity_tracker/features/transaction/domain/transaction_entity.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/features/stats/domain/entities/daily_trend_entity.dart';

class MonthlyTrendResult {
  final List<DailyTrendEntity> dailyTrends;
  final Map<int, double> incomeData;
  final Map<int, double> expenseData;

  const MonthlyTrendResult({
    required this.dailyTrends,
    required this.incomeData,
    required this.expenseData,
  });
}

class CalculateMonthlyTrendUseCase {
  MonthlyTrendResult execute({
    required List<TransactionEntity> transactions,
    required DateTime month,
  }) {
    final Map<int, double> incomeData = {};
    final Map<int, double> expenseData = {};
    final Set<int> daysWithActivity = {};

    for (var t in transactions) {
      final day = t.date.day;
      daysWithActivity.add(day);
      
      if (t.type == TransactionType.income) {
        incomeData[day] = (incomeData[day] ?? 0) + t.amount;
      } else {
        expenseData[day] = (expenseData[day] ?? 0) + t.amount;
      }
    }

    final List<DailyTrendEntity> dailyTrends = [];
    final sortedDays = daysWithActivity.toList()..sort();
    
    for (var day in sortedDays) {
      dailyTrends.add(
        DailyTrendEntity(
          day: day,
          income: incomeData[day] ?? 0.0,
          expense: expenseData[day] ?? 0.0,
        ),
      );
    }

    return MonthlyTrendResult(
      dailyTrends: dailyTrends,
      incomeData: incomeData,
      expenseData: expenseData,
    );
  }
}
