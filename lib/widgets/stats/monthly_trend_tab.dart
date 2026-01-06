import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';
import '../../models/transaction_type.dart';
import '../transaction_item.dart';
import 'trend_line_chart.dart';

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
    final selectedTransactions =
        _selectedDay == null
              ? []
              : widget.transactions
                    .where((t) => t.date.day == _selectedDay)
                    .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      children: [
        // CHART SECTION
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SizedBox(
            height: 250,
            child: TrendLineChart(
              incomeSpots: incomeData,
              expenseSpots: expenseData,
              daysInMonth: daysInMonth,
              onDateSelected: (day) {
                setState(() {
                  _selectedDay = day;
                });
              },
            ),
          ),
        ),

        // DIVIDER / INFO
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                _selectedDay != null
                    ? 'Transactions on ${_selectedDay}/${widget.month.month}'
                    : 'Tap on chart to view details',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              if (_selectedDay != null) ...[
                // Could show daily total here
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),

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
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: selectedTransactions.length,
                  itemBuilder: (context, index) {
                    return TransactionItem(
                      transaction: selectedTransactions[index],
                      onTap: () {
                        // Drill down? Or just view.
                        // Ideally we can open edit screen but we need navigation context
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
