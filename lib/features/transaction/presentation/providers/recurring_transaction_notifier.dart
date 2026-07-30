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
  @override
  Future<List<RecurringTransactionEntity>> build() async {
    return _fetchExistingRecurringTransactions();
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
    // This is business logic that evaluates if nextDueDate has passed and generates regular transactions.
    final generated = await ref.read(transactionRepositoryProvider).checkAndProcessRecurringTransactions();
    if (generated) {
      ref.invalidateSelf();
      ref.invalidate(transactionListProvider);
      await future;
    }
  }
}
