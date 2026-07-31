import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/transaction/domain/recurring_transaction_entity.dart';
import 'package:equity_tracker/core/providers/repository_providers.dart';
import 'package:equity_tracker/features/transaction/presentation/providers/transaction_notifier.dart';

final recurringTransactionListProvider =
    AsyncNotifierProvider<
      RecurringTransactionListNotifier,
      List<RecurringTransactionEntity>
    >(RecurringTransactionListNotifier.new);

class RecurringTransactionListNotifier extends AsyncNotifier<List<RecurringTransactionEntity>> {
  Timer? _timer;

  @override
  Future<List<RecurringTransactionEntity>> build() async {
    ref.onDispose(() {
      _timer?.cancel();
    });
    final list = await _fetchExistingRecurringTransactions();
    _scheduleNextTrigger(list);
    return list;
  }

  Future<List<RecurringTransactionEntity>> _fetchExistingRecurringTransactions() async {
    return await ref.read(transactionRepositoryProvider).getAllRecurringTransactions();
  }

  Future<void> addRecurringTransaction(RecurringTransactionEntity transaction) async {
    await ref.read(transactionRepositoryProvider).insertRecurringTransaction(transaction);
    ref.invalidateSelf();
    await future;
  }

  Future<void> updateRecurringTransaction(RecurringTransactionEntity transaction) async {
    await ref.read(transactionRepositoryProvider).updateRecurringTransaction(transaction);
    ref.invalidateSelf();
    await future;
  }

  Future<void> deleteRecurringTransaction(int id) async {
    await ref.read(transactionRepositoryProvider).deleteRecurringTransaction(id);
    ref.invalidateSelf();
    await future;
  }

  Future<void> checkAndProcess() async {
    final generated = await ref.read(transactionRepositoryProvider).checkAndProcessRecurringTransactions();
    if (generated) {
      ref.invalidate(transactionListProvider);
      final list = await _fetchExistingRecurringTransactions();
      state = AsyncValue.data(list);
      _scheduleNextTrigger(list);
    }
  }

  void _scheduleNextTrigger(List<RecurringTransactionEntity> transactions) {
    _timer?.cancel();

    final enabled = transactions.where((t) => t.isEnabled).toList();
    if (enabled.isEmpty) return;

    enabled.sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
    final earliest = enabled.first;

    final now = DateTime.now();
    final difference = earliest.nextDueDate.difference(now);

    if (difference.isNegative) {
      checkAndProcess();
    } else {
      _timer = Timer(difference + const Duration(seconds: 1), () {
        checkAndProcess();
      });
    }
  }
}
