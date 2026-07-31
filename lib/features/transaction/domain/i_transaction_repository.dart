import 'package:equity_tracker/features/transaction/domain/transaction_entity.dart';
import 'package:equity_tracker/features/transaction/domain/recurring_transaction_entity.dart';

abstract class ITransactionRepository {
  Future<List<TransactionEntity>> getAllTransactions();
  Future<List<TransactionEntity>> getTransactionsByDateRange(DateTime start, DateTime end);
  Future<int> insertTransaction(TransactionEntity transaction);
  Future<int> updateTransaction(TransactionEntity transaction);
  Future<int> deleteTransaction(int id);
  Future<void> reassignCategory(String oldCategoryId, String newCategoryId);
  
  // Recurring Transactions
  Future<List<RecurringTransactionEntity>> getAllRecurringTransactions();
  Future<List<RecurringTransactionEntity>> getEnabledRecurringTransactions();
  Future<void> clearAllTransactions();
  Future<List<String>> getRecentTitles({int limit = 1000});
  Future<int> insertRecurringTransaction(RecurringTransactionEntity transaction);
  Future<int> updateRecurringTransaction(RecurringTransactionEntity transaction);
  Future<int> deleteRecurringTransaction(int id);
}
