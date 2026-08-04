import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/core/providers/repository_providers.dart';
import 'package:equity_tracker/features/transaction/data/transaction_model.dart';
import 'package:equity_tracker/features/transaction/providers/transaction_notifier.dart';

class TransactionListState {
  final int totalBalance;
  final int totalIncome;
  final int totalExpense;
  final int monthlyBalance;
  final int monthlyIncome;
  final int monthlyExpense;
  final Map<DateTime, List<TransactionModel>> groupedTransactions;
  final bool isLoading;
  final String? errorMessage;

  TransactionListState({
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpense,
    required this.monthlyBalance,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.groupedTransactions,
    this.isLoading = false,
    this.errorMessage,
  });

  factory TransactionListState.initial() => TransactionListState(
        totalBalance: 0,
        totalIncome: 0,
        totalExpense: 0,
        monthlyBalance: 0,
        monthlyIncome: 0,
        monthlyExpense: 0,
        groupedTransactions: {},
        isLoading: true,
      );
}

final transactionListControllerProvider = FutureProvider<TransactionListState>((ref) async {
  final filteredTransactionsAsync = ref.watch(filteredTransactionsProvider);
  final groupedTransactionsAsync = ref.watch(groupedTransactionsProvider);
  
  // This watch ensures that when we add/delete, this provider invalidates and rebuilds
  ref.watch(transactionListProvider);

  // We DO NOT return initial() on loading. This allows the UI to show the old state 
  // while fetching new data, enabling seamless Optimistic Updates.
  if (!filteredTransactionsAsync.hasValue && filteredTransactionsAsync.isLoading) {
    return TransactionListState.initial();
  }

  // 1. Fetch All-Time Stats from SQLite directly (Extremely Fast, NO memory loops)
  final repo = ref.watch(transactionRepositoryProvider);
  final totalIncome = await repo.getTotalAmountByType(TransactionType.income);
  final totalExpense = await repo.getTotalAmountByType(TransactionType.expense);
  final totalBalance = totalIncome - totalExpense;

  // 2. Calculate Monthly Stats from memory (Only a few dozen items, extremely fast)
  int monthlyBalance = 0;
  int monthlyIncome = 0;
  int monthlyExpense = 0;

  if (filteredTransactionsAsync.hasValue) {
    for (var t in filteredTransactionsAsync.value!) {
      if (t.type == TransactionType.income) {
        monthlyIncome += t.amount;
        monthlyBalance += t.amount;
      } else {
        monthlyExpense += t.amount;
        monthlyBalance -= t.amount;
      }
    }
  }

  return TransactionListState(
    totalBalance: totalBalance,
    totalIncome: totalIncome,
    totalExpense: totalExpense,
    monthlyBalance: monthlyBalance,
    monthlyIncome: monthlyIncome,
    monthlyExpense: monthlyExpense,
    groupedTransactions: groupedTransactionsAsync.value ?? {},
    isLoading: false,
  );
});

extension TransactionListStateExt on TransactionListState {
  TransactionListState copyWithError(String err) {
    return TransactionListState(
      totalBalance: totalBalance,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      monthlyBalance: monthlyBalance,
      monthlyIncome: monthlyIncome,
      monthlyExpense: monthlyExpense,
      groupedTransactions: groupedTransactions,
      isLoading: false,
      errorMessage: err,
    );
  }
}

