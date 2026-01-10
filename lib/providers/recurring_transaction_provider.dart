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
    final generated = await db.checkAndProcessRecurringTransactions();
    if (generated) {
      // If transactions were generated, we need to refresh recurring list (dates changed)
      // AND transaction list (new entries appear)
      ref.invalidateSelf();
      ref.invalidate(transactionListProvider);
    }
  }
}
