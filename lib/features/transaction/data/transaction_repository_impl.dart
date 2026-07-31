import 'package:equity_tracker/features/transaction/domain/transaction_entity.dart';
import 'package:equity_tracker/features/transaction/domain/recurring_transaction_entity.dart';
import 'package:equity_tracker/features/transaction/domain/i_transaction_repository.dart';
import 'package:equity_tracker/features/transaction/data/transaction_model.dart';
import 'package:equity_tracker/features/transaction/data/recurring_transaction_model.dart';
import 'package:equity_tracker/features/transaction/data/transaction_local_data_source.dart';

class TransactionRepositoryImpl implements ITransactionRepository {
  final ITransactionLocalDataSource _localDataSource;

  TransactionRepositoryImpl(this._localDataSource);

  @override
  Future<List<TransactionEntity>> getAllTransactions() async {
    return await _localDataSource.getAllTransactions();
  }

  @override
  Future<List<TransactionEntity>> getTransactionsByDateRange(DateTime start, DateTime end) async {
    return await _localDataSource.getTransactionsByDateRange(start, end);
  }

  @override
  Future<int> insertTransaction(TransactionEntity transaction) async {
    return await _localDataSource.insertTransaction(TransactionModel.fromEntity(transaction));
  }

  @override
  Future<int> updateTransaction(TransactionEntity transaction) async {
    return await _localDataSource.updateTransaction(TransactionModel.fromEntity(transaction));
  }

  @override
  Future<int> deleteTransaction(int id) async {
    return await _localDataSource.deleteTransaction(id);
  }

  @override
  Future<void> reassignCategory(String oldCategoryId, String newCategoryId) async {
    await _localDataSource.reassignCategory(oldCategoryId, newCategoryId);
  }
  
  @override
  Future<void> clearAllTransactions() async {
    await _localDataSource.clearAllTransactions();
  }
  
  @override
  Future<List<String>> getRecentTitles({int limit = 1000}) async {
    return await _localDataSource.getRecentTitles(limit: limit);
  }

  // Recurring Transactions
  @override
  Future<List<RecurringTransactionEntity>> getAllRecurringTransactions() async {
    return await _localDataSource.getAllRecurringTransactions();
  }
  
  @override
  Future<List<RecurringTransactionEntity>> getEnabledRecurringTransactions() async {
    return await _localDataSource.getEnabledRecurringTransactions();
  }

  @override
  Future<int> insertRecurringTransaction(RecurringTransactionEntity transaction) async {
    return await _localDataSource.insertRecurringTransaction(RecurringTransactionModel.fromEntity(transaction));
  }

  @override
  Future<int> updateRecurringTransaction(RecurringTransactionEntity transaction) async {
    return await _localDataSource.updateRecurringTransaction(RecurringTransactionModel.fromEntity(transaction));
  }

  @override
  Future<int> deleteRecurringTransaction(int id) async {
    return await _localDataSource.deleteRecurringTransaction(id);
  }
}
