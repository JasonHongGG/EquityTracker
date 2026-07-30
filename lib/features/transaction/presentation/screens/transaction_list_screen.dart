import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/settings/presentation/screens/settings_screen.dart';
import 'package:equity_tracker/core/widgets/search_dialog.dart';
import 'package:equity_tracker/features/transaction/presentation/providers/transaction_notifier.dart';
import 'package:equity_tracker/features/settings/presentation/providers/settings_notifier.dart';
import 'package:equity_tracker/features/transaction/presentation/widgets/transaction_list_screen/dashboard_header_delegate.dart';
import 'package:equity_tracker/features/transaction/presentation/widgets/common/month_selector.dart';
import 'package:equity_tracker/core/widgets/custom_month_picker.dart';
import 'package:equity_tracker/features/transaction/presentation/widgets/transaction_list_screen/daily_transaction_card.dart';
import 'package:equity_tracker/features/transaction/presentation/widgets/transaction_list_screen/transaction_empty_state.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() =>
      _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  bool _isMonthlyView = false;

  @override
  Widget build(BuildContext context) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final groupedTransactionsAsync = ref.watch(groupedTransactionsProvider);
    
    final filteredTransactionsAsync = ref.watch(filteredTransactionsProvider);
    final transactionsAsync = ref.watch(transactionListProvider);
    final currentFilter = ref.watch(transactionFilterProvider);

    // Read privacy mode
    final settingsAsync = ref.watch(settingsNotifierProvider);
    final isPrivacyMode = settingsAsync.value?.isPrivacyModeEnabled ?? false;

    final isSearching =
        currentFilter.searchQuery != null &&
        currentFilter.searchQuery!.isNotEmpty;
        
    // 1. Total Balance & Stats (All Time)
    int totalBalance = 0;
    int totalIncome = 0;
    int totalExpense = 0;
    if (transactionsAsync.hasValue) {
      for (var t in transactionsAsync.value!) {
        if (t.type.name == 'income') {
          totalIncome += t.amount;
          totalBalance += t.amount;
        } else {
          totalExpense += t.amount;
          totalBalance -= t.amount;
        }
      }
    }

    // 2. Monthly Stats (Selected Month from Filter)
    int monthlyBalance = 0;
    int monthlyIncome = 0;
    int monthlyExpense = 0;

    if (filteredTransactionsAsync.hasValue) {
      for (var t in filteredTransactionsAsync.value!) {
        if (t.type.name == 'income') {
          monthlyIncome += t.amount;
          monthlyBalance += t.amount;
        } else {
          monthlyExpense += t.amount;
          monthlyBalance -= t.amount;
        }
      }
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 1. Scrollable Month Selector
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top,
                bottom: 0,
              ),
              child: MonthSelector(
                selectedDate: selectedMonth,
                isSearching: isSearching,
                onSettings: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
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
                onClearSearch: () {
                  ref
                      .read(transactionFilterProvider.notifier)
                      .update(
                        ref
                            .read(transactionFilterProvider)
                            .copyWith(searchQuery: ''),
                      );
                },
                onSearch: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return SearchDialog(
                        subtitle: 'Find transactions by title or note',
                        initialQuery:
                            ref.read(transactionFilterProvider).searchQuery ??
                            '',
                        onChanged: (value) {
                          ref
                              .read(transactionFilterProvider.notifier)
                              .update(
                                ref
                                    .read(transactionFilterProvider)
                                    .copyWith(searchQuery: value),
                              );
                        },
                        onClear: () {
                          ref
                              .read(transactionFilterProvider.notifier)
                              .update(
                                ref
                                    .read(transactionFilterProvider)
                                    .copyWith(searchQuery: ''),
                              );
                          Navigator.pop(context);
                        },
                      );
                    },
                  );
                },
                onTitleTap: () async {
                  final newDate = await showCustomMonthPicker(
                    context: context,
                    initialDate: selectedMonth,
                  );
                  if (newDate != null) {
                    ref.read(selectedMonthProvider.notifier).update(newDate);
                  }
                },
              ),
            ),
          ),

          // 2. AppBar & Dashboard
          SliverPersistentHeader(
            pinned: true,
            delegate: DashboardHeaderDelegate(
              totalBalance: totalBalance,
              totalIncome: totalIncome,
              totalExpense: totalExpense,
              monthlyBalance: monthlyBalance,
              monthlyIncome: monthlyIncome,
              monthlyExpense: monthlyExpense,
              isMonthlyView: _isMonthlyView,
              onToggleView: () {
                setState(() {
                  _isMonthlyView = !_isMonthlyView;
                });
              },
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
              onDateTap: () async {
                final newDate = await showCustomMonthPicker(
                  context: context,
                  initialDate: selectedMonth,
                );
                if (newDate != null) {
                  ref.read(selectedMonthProvider.notifier).update(newDate);
                }
              },
              isPrivacyMode: isPrivacyMode,
            ),
          ),

          // List
          groupedTransactionsAsync.when(
            data: (groupedTransactions) {
              if (groupedTransactions.isEmpty) {
                return const TransactionEmptyState();
              }

              final dates = groupedTransactions.keys.toList();

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final date = dates[index];
                  final transactions = groupedTransactions[date]!;
                  return DailyTransactionCard(
                    date: date,
                    transactions: transactions,
                    index: index,
                  );
                }, childCount: dates.length),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, s) =>
                SliverFillRemaining(child: Center(child: Text('Error: \$e'))),
          ),

          // Bottom Padding for Nav Bar
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }
}
