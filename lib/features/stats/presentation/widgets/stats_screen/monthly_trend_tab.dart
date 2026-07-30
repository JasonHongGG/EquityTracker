import 'package:flutter/material.dart';
import 'package:equity_tracker/features/transaction/domain/transaction_entity.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/features/transaction/presentation/widgets/common/transaction_item.dart';
import 'package:equity_tracker/features/transaction/presentation/widgets/common/date_header.dart';
import 'package:equity_tracker/features/stats/presentation/widgets/stats_screen/trend_line_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/transaction/presentation/widgets/common/day_selector.dart';
import 'package:go_router/go_router.dart';
import 'package:equity_tracker/features/stats/presentation/providers/stats_provider.dart';
import 'package:equity_tracker/features/stats/presentation/widgets/stats_screen/trend_legend_item.dart';
import 'package:equity_tracker/features/stats/presentation/widgets/stats_screen/trend_transaction_list.dart';

class MonthlyTrendTab extends ConsumerStatefulWidget {
  final List<TransactionEntity> transactions; // Kept for list view
  final DateTime month;

  const MonthlyTrendTab({
    super.key,
    required this.transactions,
    required this.month,
  });

  @override
  ConsumerState<MonthlyTrendTab> createState() => _MonthlyTrendTabState();
}

class _MonthlyTrendTabState extends ConsumerState<MonthlyTrendTab> {
  int? _selectedDay;

  @override
  void initState() {
    super.initState();
    _initializeSelectedDay();
  }

  @override
  void didUpdateWidget(MonthlyTrendTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.month != widget.month ||
        oldWidget.transactions != widget.transactions) {
      _initializeSelectedDay();
    }
  }

  void _initializeSelectedDay() {
    if (widget.transactions.isEmpty) {
      setState(() => _selectedDay = null);
      return;
    }

    // Filter transactions for the current month just in case (though mostly handled by parent)
    // Actually parent passes all transactions. We need to filter them?
    // The previous implementation didn't filter in build. Let's check logic.
    // Parent StatsScreen passes filteredTransactionsProvider. So it's already filtered by month mostly?
    // Wait, StatsScreen passes 'transactions' which is `filteredTransactionsProvider`.
    // Let's assume they are correct.

    // Find earliest day with transaction
    // Transactions might not be sorted by day.
    final days = widget.transactions.map((t) => t.date.day).toSet().toList()
      ..sort();

    if (days.isNotEmpty) {
      // Requirement: Default to "the first day of the month that has transactions"
      // e.g. 6, 13, 21. Default to 6.
      setState(() {
        _selectedDay = days.first;
      });
    } else {
      setState(() => _selectedDay = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trendAsync = ref.watch(monthlyTrendProvider);

    return trendAsync.when(
      data: (trendResult) {
        final daysInMonth = DateTime(
          widget.month.year,
          widget.month.month + 1,
          0,
        ).day;

    // 2. Filter List based on selection
    // 2. Filter List based on selection
    final List<TransactionEntity> selectedTransactions =
        _selectedDay == null
              ? <TransactionEntity>[]
              : widget.transactions
                    .where((t) => t.date.day == _selectedDay)
                    .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      children: [
        // CHART SECTION
        const SizedBox(height: 10),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SizedBox(
            height: 180,
            child: TrendLineChart(
              incomeSpots: trendResult.incomeData,
              expenseSpots: trendResult.expenseData,
              daysInMonth: daysInMonth,
              month: widget.month, // Pass the month
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
        // Legend (Moved to bottom-left)
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
                DaySelector(
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

        // DIVIDER / INFO
        const SizedBox(height: 4),

        // LIST SECTION
        Expanded(
          child: TrendTransactionList(
            selectedDay: _selectedDay,
            month: widget.month,
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


