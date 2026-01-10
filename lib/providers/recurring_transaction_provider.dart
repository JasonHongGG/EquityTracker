import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recurring_transaction_model.dart';
import '../services/database_service.dart';
import 'transaction_provider.dart';

// Provider to get the list of recurring transactions
final recurringTransactionListProvider =
    AsyncNotifierProvider<
      RecurringTransactionListNotifier,
      List<RecurringTransaction>
    >(RecurringTransactionListNotifier.new);

class RecurringTransactionListNotifier
    extends AsyncNotifier<List<RecurringTransaction>> {
  @override
  Future<List<RecurringTransaction>> build() async {
    return _fetchExisitingRecurringTransactions();
  }

  Future<List<RecurringTransaction>>
  _fetchExisitingRecurringTransactions() async {
    final db = DatabaseService();
    return db.getRecurringTransactions();
  }

  Future<void> addRecurringTransaction(RecurringTransaction transaction) async {
    final db = DatabaseService();
    await db.insertRecurringTransaction(transaction);
    // Refresh the list
    ref.invalidateSelf();
    await future;
  }

  Future<void> updateRecurringTransaction(
    RecurringTransaction transaction,
  ) async {
    final db = DatabaseService();
    await db.updateRecurringTransaction(transaction);
    // Refresh the list
    ref.invalidateSelf();
    await future;
  }

  Future<void> deleteRecurringTransaction(int id) async {
    final db = DatabaseService();
    await db.deleteRecurringTransaction(id);
    // Refresh the list
    ref.invalidateSelf();
    await future;
  }

  Future<void> checkAndProcess() async {
    final db = DatabaseService();
    // This now returns true if ANY transaction was generated
    final generated = await db.checkAndProcessRecurringTransactions();

    if (generated) {
      // If transactions were generated, we must invalidate:
      // 1. Recurring List (dates changed)
      ref.invalidateSelf();
      // 2. Main Transaction List (new items added)
      ref.invalidate(transactionListProvider);

      // Wait for the refresh to complete to ensure UI is ready?
      // Not strictly necessary for "invalidate", but good practice to ensure state is clean
      await future;
      // Force read of transaction list to trigger immediate fetch if it was disposed?
      // Or just let the UI watcher handle it.
    }
  }
}
