import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/transaction_provider.dart';
import '../widgets/date_header.dart';
import '../widgets/dashboard_header_delegate.dart';
import '../widgets/month_selector.dart';
import '../widgets/transaction_item.dart';
import 'add_edit_transaction_screen.dart';

class TransactionListScreen extends ConsumerWidget {
  const TransactionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final groupedTransactionsAsync = ref.watch(groupedTransactionsProvider);
    final dailyTotalsAsync = ref.watch(dailyTotalProvider);
    final filteredTransactionsAsync = ref.watch(filteredTransactionsProvider);
    final transactionsAsync = ref.watch(transactionListProvider);

    // 1. Total Balance (All Time)
    int balance = 0;
    if (transactionsAsync.hasValue) {
      for (var t in transactionsAsync.value!) {
        if (t.type.name == 'income') {
          balance += t.amount;
        } else {
          balance -= t.amount;
        }
      }
    }

    // 2. Income & Expense (Selected Month)
    int income = 0;
    int expense = 0;
    if (filteredTransactionsAsync.hasValue) {
      for (var t in filteredTransactionsAsync.value!) {
        if (t.type.name == 'income') {
          income += t.amount;
        } else {
          expense += t.amount;
        }
      }
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 1. Scrollable Month Selector
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 0),
              child: MonthSelector(
                selectedDate: selectedMonth,
                onPrevious: () {
                  ref
                      .read(selectedMonthProvider.notifier)
                      .update(
                        DateTime(selectedMonth.year, selectedMonth.month - 1),
                      );
                },
                onNext: () {
                  ref
                      .read(selectedMonthProvider.notifier)
                      .update(
                        DateTime(selectedMonth.year, selectedMonth.month + 1),
                      );
                },
              ),
            ),
          ),

          // 2. AppBar & Dashboard
          SliverPersistentHeader(
            pinned: true,
            delegate: DashboardHeaderDelegate(
              balance: balance,
              income: income,
              expense: expense,
              topPadding: MediaQuery.of(context).padding.top,
              selectedDate: selectedMonth,
              onPreviousMonth: () {
                ref
                    .read(selectedMonthProvider.notifier)
                    .update(
                      DateTime(selectedMonth.year, selectedMonth.month - 1),
                    );
              },
              onNextMonth: () {
                ref
                    .read(selectedMonthProvider.notifier)
                    .update(
                      DateTime(selectedMonth.year, selectedMonth.month + 1),
                    );
              },
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
}
