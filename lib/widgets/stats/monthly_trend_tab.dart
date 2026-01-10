import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';
import '../../models/transaction_type.dart';
import '../transaction_item.dart';
import '../date_header.dart';
import 'trend_line_chart.dart';
import '../day_selector.dart';
import '../../screens/add_edit_transaction_screen.dart';

class MonthlyTrendTab extends StatefulWidget {
  final List<TransactionModel> transactions;
  final DateTime month;

  const MonthlyTrendTab({
    super.key,
    required this.transactions,
    required this.month,
  });

  @override
  State<MonthlyTrendTab> createState() => _MonthlyTrendTabState();
}

class _MonthlyTrendTabState extends State<MonthlyTrendTab> {
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
    // 1. Process Data for Chart
    final daysInMonth = DateTime(
      widget.month.year,
      widget.month.month + 1,
      0,
    ).day;
    final Map<int, double> incomeData = {};
    final Map<int, double> expenseData = {};

    for (var t in widget.transactions) {
      final day = t.date.day;
      if (t.type == TransactionType.income) {
        incomeData[day] = (incomeData[day] ?? 0) + t.amount;
      } else {
        expenseData[day] = (expenseData[day] ?? 0) + t.amount;
      }
    }

    // 2. Filter List based on selection
    // 2. Filter List based on selection
    final List<TransactionModel> selectedTransactions =
        _selectedDay == null
              ? <TransactionModel>[]
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
              incomeSpots: incomeData,
              expenseSpots: expenseData,
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
              _TrendLegendItem(color: const Color(0xFF34C759), label: 'Income'),
              const SizedBox(width: 20),
              _TrendLegendItem(
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
          child: _selectedDay == null
              ? Center(
                  child: Text(
                    'Select a day to view transactions',
                    style: TextStyle(color: Theme.of(context).hintColor),
                  ),
                )
              : selectedTransactions.isEmpty
              ? Center(
                  child: Text(
                    'No transactions',
                    style: TextStyle(color: Theme.of(context).hintColor),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 10,
                    bottom: 100, // Extra padding for bottom nav
                  ),
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DateHeader(
                            date: DateTime(
                              widget.month.year,
                              widget.month.month,
                              _selectedDay!,
                            ),
                            totalAmount: selectedTransactions.fold<int>(
                              0,
                              (sum, t) => t.type == TransactionType.income
                                  ? sum + t.amount
                                  : sum - t.amount,
                            ),
                          ),
                          for (
                            var i = 0;
                            i < selectedTransactions.length;
                            i++
                          ) ...[
                            if (i > 0)
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 74,
                                  right: 16,
                                ),
                                child: Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.05),
                                ),
                              ),
                            TransactionItem(
                              transaction: selectedTransactions[i],
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AddEditTransactionScreen(
                                          transaction: selectedTransactions[i],
                                        ),
                                  ),
                                );
                              },
                            ),
                          ],
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _TrendLegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _TrendLegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ],
    );
  }
}
