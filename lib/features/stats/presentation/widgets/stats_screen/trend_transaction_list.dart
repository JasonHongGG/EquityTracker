import 'package:flutter/material.dart';

import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/features/transaction/presentation/widgets/common/transaction_item.dart';
import 'package:equity_tracker/features/transaction/presentation/widgets/common/date_header.dart';
import 'package:go_router/go_router.dart';
import 'package:equity_tracker/features/transaction/data/transaction_model.dart';

class TrendTransactionList extends StatelessWidget {
  final int? selectedDay;
  final DateTime month;
  final List<TransactionModel> transactions;

  const TrendTransactionList({
    super.key,
    required this.selectedDay,
    required this.month,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedDay == null) {
      return Center(
        child: Text(
          'Select a day to view transactions',
          style: TextStyle(color: Theme.of(context).hintColor),
        ),
      );
    }

    if (transactions.isEmpty) {
      return Center(
        child: Text(
          'No transactions',
          style: TextStyle(color: Theme.of(context).hintColor),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: 100,
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
                  month.year,
                  month.month,
                  selectedDay!,
                ),
                totalAmount: transactions.fold<int>(
                  0,
                  (sum, t) => t.type == TransactionType.income
                      ? sum + t.amount
                      : sum - t.amount,
                ),
              ),
              for (var i = 0; i < transactions.length; i++) ...[
                if (i > 0)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 74,
                      right: 16,
                    ),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                    ),
                  ),
                TransactionItem(
                  transaction: transactions[i],
                  onTap: () {
                    context.push(
                      '/add-transaction',
                      extra: {'transaction': transactions[i]},
                    );
                  },
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }
}
