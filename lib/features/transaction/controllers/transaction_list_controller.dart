import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';
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

final transactionListControllerProvider = Provider<TransactionListState>((ref) {
  final allTransactionsAsync = ref.watch(transactionListProvider);
  final filteredTransactionsAsync = ref.watch(filteredTransactionsProvider);
  final groupedTransactionsAsync = ref.watch(groupedTransactionsProvider);

  if (allTransactionsAsync.isLoading || filteredTransactionsAsync.isLoading || groupedTransactionsAsync.isLoading) {
    return TransactionListState.initial();
  }

  if (allTransactionsAsync.hasError) {
    return TransactionListState.initial()..copyWithError(allTransactionsAsync.error.toString());
  }

  // 1. Calculate All-Time Stats
  int totalBalance = 0;
  int totalIncome = 0;
  int totalExpense = 0;

  if (allTransactionsAsync.hasValue) {
    for (var t in allTransactionsAsync.value!) {
      if (t.type == TransactionType.income) {
        totalIncome += t.amount;
        totalBalance += t.amount;
      } else {
        totalExpense += t.amount;
        totalBalance -= t.amount;
      }
    }
  }

  // 2. Calculate Monthly Stats
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

extension on TransactionListState {
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
