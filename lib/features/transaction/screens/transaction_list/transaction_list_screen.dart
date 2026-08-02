import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/settings/screens/settings_screen.dart';
import 'package:equity_tracker/core/widgets/search_dialog.dart';
import 'package:equity_tracker/features/transaction/providers/transaction_notifier.dart';
import 'package:equity_tracker/features/transaction/controllers/transaction_list_controller.dart';
import 'package:equity_tracker/features/settings/providers/settings_notifier.dart';
import 'package:equity_tracker/features/transaction/screens/transaction_list/dashboard_header_delegate.dart';
import 'package:equity_tracker/core/widgets/month_navigation_bar.dart';
import 'package:equity_tracker/core/widgets/pickers/date_time_wheel_picker.dart';
import 'package:equity_tracker/features/transaction/widgets/transaction_list_screen/daily_transaction_card.dart';
import 'package:equity_tracker/features/transaction/widgets/transaction_list_screen/transaction_empty_state.dart';

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
    final currentFilter = ref.watch(transactionFilterProvider);
    final settingsAsync = ref.watch(settingsNotifierProvider);
    final isPrivacyMode = settingsAsync.value?.isPrivacyModeEnabled ?? false;
    final isSearching = currentFilter.searchQuery != null && currentFilter.searchQuery!.isNotEmpty;
    final currencySymbol = settingsAsync.value?.currencySymbol ?? '\$';
        
    final state = ref.watch(transactionListControllerProvider);

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
              child: MonthNavigationBar(
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
                  final newDate = await showCustomDateTimePicker(
                    context: context,
                    initialDate: ref.read(selectedMonthProvider),
                    showYear: true,
                    showMonth: true,
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
              totalBalance: state.totalBalance,
              totalIncome: state.totalIncome,
              totalExpense: state.totalExpense,
              monthlyBalance: state.monthlyBalance,
              monthlyIncome: state.monthlyIncome,
              monthlyExpense: state.monthlyExpense,
              isMonthlyView: _isMonthlyView,
              currencySymbol: currencySymbol,
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
                final newDate = await showCustomDateTimePicker(
                  context: context,
                  initialDate: ref.read(selectedMonthProvider),
                  showYear: true,
                  showMonth: true,
                );
                if (newDate != null) {
                  ref.read(selectedMonthProvider.notifier).update(newDate);
                }
              },
              isPrivacyMode: isPrivacyMode,
            ),
          ),

          // List
          if (state.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.errorMessage != null)
            SliverFillRemaining(child: Center(child: Text('Error: \${state.errorMessage}')))
          else if (state.groupedTransactions.isEmpty)
            const TransactionEmptyState()
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final dates = state.groupedTransactions.keys.toList();
                final date = dates[index];
                final transactions = state.groupedTransactions[date]!;
                return DailyTransactionCard(
                  date: date,
                  transactions: transactions,
                  index: index,
                  currencySymbol: currencySymbol,
                );
              }, childCount: state.groupedTransactions.length),
            ),

          // Bottom Padding for Nav Bar
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }
}
