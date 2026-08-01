import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/stats/presentation/widgets/stats_screen/trend_line_chart.dart';
import 'package:equity_tracker/core/widgets/horizontal_day_slider.dart';
import 'package:equity_tracker/features/stats/presentation/providers/trend_analysis_provider.dart';
import 'package:equity_tracker/features/transaction/presentation/providers/transaction_notifier.dart';
import 'package:equity_tracker/features/stats/presentation/widgets/stats_screen/trend_legend_item.dart';
import 'package:equity_tracker/features/stats/presentation/widgets/stats_screen/trend_transaction_list.dart';
import 'package:equity_tracker/features/transaction/data/transaction_model.dart';

class MonthlyTrendTab extends ConsumerStatefulWidget {
  const MonthlyTrendTab({super.key});

  @override
  ConsumerState<MonthlyTrendTab> createState() => _MonthlyTrendTabState();
}

class _MonthlyTrendTabState extends ConsumerState<MonthlyTrendTab> {
  int? _selectedDay = 1;

  @override
  void initState() {
    super.initState();
  }

  void _initializeSelectedDay() {
    setState(() {
      _selectedDay = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final trendAsync = ref.watch(monthlyTrendProvider);
    final transactionsAsync = ref.watch(filteredTransactionsProvider);
    final transactions = transactionsAsync.value ?? [];
    final month = ref.watch(selectedMonthProvider);

    ref.listen(selectedMonthProvider, (prev, next) {
      if (prev != next) {
        _initializeSelectedDay();
      }
    });

    return trendAsync.when(
      data: (trendResult) {
        final daysInMonth = DateTime(
          month.year,
          month.month + 1,
          0,
        ).day;

        final List<TransactionModel> selectedTransactions = _selectedDay == null
            ? <TransactionModel>[]
            : transactions
                .where((t) => t.date.day == _selectedDay)
                .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return Column(
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                height: 180,
                child: TrendLineChart(
                  incomeSpots: trendResult.incomeData,
                  expenseSpots: trendResult.expenseData,
                  daysInMonth: daysInMonth,
                  month: month,
                  selectedDay: _selectedDay,
                  onDateSelected: (day) {
                    setState(() {
                      _selectedDay = day;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  TrendLegendItem(color: const Color(0xFF34C759), label: 'Income'),
                  const SizedBox(width: 20),
                  TrendLegendItem(
                    color: Colors.redAccent.shade200,
                    label: 'Expense',
                  ),
                  const Spacer(),
                  if (_selectedDay != null)
                    HorizontalDaySlider(
                      selectedDay: _selectedDay!,
                      daysInMonth: daysInMonth,
                      onDayChanged: (day) {
                        setState(() {
                          _selectedDay = day;
                        });
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: TrendTransactionList(
                selectedDay: _selectedDay,
                month: month,
                transactions: selectedTransactions,
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}
