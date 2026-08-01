class DailyTrend {
  final int day;
  final double income;
  final double expense;

  const DailyTrend({
    required this.day,
    this.income = 0.0,
    this.expense = 0.0,
  });
}
