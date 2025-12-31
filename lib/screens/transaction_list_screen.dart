import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/transaction_provider.dart';
import '../widgets/date_header.dart';
import '../widgets/transaction_item.dart';
import '../widgets/gradient_card.dart';
import '../theme/app_colors.dart';
import 'add_edit_transaction_screen.dart';

class TransactionListScreen extends ConsumerWidget {
  const TransactionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupedTransactionsAsync = ref.watch(groupedTransactionsProvider);
    final dailyTotalsAsync = ref.watch(dailyTotalProvider);
    final transactionsAsync = ref.watch(transactionListProvider);

    // Better Calc
    int balance = 0;
    int income = 0;
    int expense = 0;
    if (transactionsAsync.hasValue) {
      for (var t in transactionsAsync.value!) {
        if (t.type.name == 'income') {
          balance += t.amount;
          income += t.amount;
        } else {
          balance -= t.amount;
          expense += t.amount;
        }
      }
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar & Dashboard
          SliverAppBar(
            expandedHeight: 260,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                child: GradientCard(
                  gradient: AppColors.backgroundGradientDark,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Total Balance',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondaryDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$$balance',
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSummaryItem(
                            context,
                            'Income',
                            income,
                            AppColors.income,
                          ),
                          _buildSummaryItem(
                            context,
                            'Expense',
                            expense,
                            AppColors.expense,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // List
          groupedTransactionsAsync.when(
            data: (groupedTransactions) {
              if (groupedTransactions.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('No transactions recently.')),
                );
              }

              final dates = groupedTransactions.keys.toList();

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final date = dates[index];
                  final transactions = groupedTransactions[date]!;
                  final dayTotal = dailyTotalsAsync.asData?.value[date] ?? 0;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DateHeader(date: date, totalAmount: dayTotal),
                      ...transactions.map(
                        (tx) => TransactionItem(
                          transaction: tx,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AddEditTransactionScreen(transaction: tx),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                }, childCount: dates.length),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, s) =>
                SliverFillRemaining(child: Center(child: Text('Error: $e'))),
          ),

          // Bottom Padding for Nav Bar
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    int amount,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            label == 'Income' ? Icons.arrow_downward : Icons.arrow_upward,
            color: color,
            size: 16,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryDark,
              ),
            ),
            Text(
              '\$$amount',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
