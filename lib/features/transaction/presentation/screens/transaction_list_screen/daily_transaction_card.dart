import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import 'package:equity_tracker/features/transaction/presentation/screens/add_edit_transaction_screen/add_edit_transaction_screen.dart';
import 'package:equity_tracker/features/transaction/presentation/widgets/common/date_header.dart';
import 'package:equity_tracker/features/transaction/presentation/widgets/common/transaction_item.dart';
import 'package:equity_tracker/features/transaction/data/transaction_model.dart';

class DailyTransactionCard extends StatelessWidget {
  final DateTime date;
  final List<TransactionModel> transactions;
  final int index;

  const DailyTransactionCard({
    super.key,
    required this.date,
    required this.transactions,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final dayTotal = transactions.fold<int>(
      0,
      (sum, t) => t.type.name == 'income' ? sum + t.amount : sum - t.amount,
    );

    return AnimationConfiguration.staggeredList(
      position: index,
      duration: const Duration(milliseconds: 375),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddEditTransactionScreen(initialDate: date),
                      ),
                    );
                  },
                  child: DateHeader(
                    date: date,
                    totalAmount: dayTotal,
                  ),
                ),
                for (var i = 0; i < transactions.length; i++) ...[
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 74, right: 16),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.05),
                      ),
                    ),
                  TransactionItem(
                    transaction: transactions[i],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AddEditTransactionScreen(transaction: transactions[i]),
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
