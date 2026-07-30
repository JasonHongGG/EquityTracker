import 'package:equity_tracker/domain/entities/transaction_entity.dart';
import 'package:equity_tracker/domain/entities/recurring_transaction_entity.dart';
import 'package:equity_tracker/domain/repositories/i_transaction_repository.dart';
import 'package:equity_tracker/data/models/transaction_model.dart';
import 'package:equity_tracker/data/models/recurring_transaction_model.dart';
import 'package:equity_tracker/data/datasources/database_helper.dart';
import 'package:equity_tracker/core/services/database_service.dart';

class TransactionRepositoryImpl implements ITransactionRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Future<List<TransactionEntity>> getAllTransactions() async {
    final db = await _dbHelper.database;
    final maps = await db.query('transactions', orderBy: 'date DESC, id DESC');
    return maps.map<TransactionEntity>((map) => TransactionModel.fromMap(map)).toList();
  }

  @override
  Future<List<TransactionEntity>> getTransactionsByDateRange(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'transactions',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC, id DESC',
    );
    return maps.map<TransactionEntity>((map) => TransactionModel.fromMap(map)).toList();
  }

  @override
  Future<int> insertTransaction(TransactionEntity transaction) async {
    final db = await _dbHelper.database;
    final model = TransactionModel.fromEntity(transaction);
    return await db.insert('transactions', model.toMap());
  }

  @override
  Future<int> updateTransaction(TransactionEntity transaction) async {
    final db = await _dbHelper.database;
    final model = TransactionModel.fromEntity(transaction);
    return await db.update(
      'transactions',
      model.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  @override
  Future<int> deleteTransaction(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> reassignCategory(String oldCategoryId, String newCategoryId) async {
    final db = await _dbHelper.database;
    await db.update(
      'transactions',
      {'categoryId': newCategoryId},
      where: 'categoryId = ?',
      whereArgs: [oldCategoryId],
    );
    await db.update(
      'recurring_transactions',
      {'categoryId': newCategoryId},
      where: 'categoryId = ?',
      whereArgs: [oldCategoryId],
    );
  }

  // Recurring Transactions

  @override
  Future<List<RecurringTransactionEntity>> getAllRecurringTransactions() async {
    final db = await _dbHelper.database;
    final maps = await db.query('recurring_transactions');
    return maps.map<RecurringTransactionEntity>((map) => RecurringTransactionModel.fromMap(map)).toList();
  }

  @override
  Future<int> insertRecurringTransaction(RecurringTransactionEntity transaction) async {
    final db = await _dbHelper.database;
    final model = RecurringTransactionModel.fromEntity(transaction);
    return await db.insert('recurring_transactions', model.toMap());
  }

  @override
  Future<int> updateRecurringTransaction(RecurringTransactionEntity transaction) async {
    final db = await _dbHelper.database;
    final model = RecurringTransactionModel.fromEntity(transaction);
    return await db.update(
      'recurring_transactions',
      model.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  @override
  Future<int> deleteRecurringTransaction(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'recurring_transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<bool> checkAndProcessRecurringTransactions() async {
    // We defer to the proven legacy logic in DatabaseService for now.
    // In a fully pure clean architecture, we would move that logic here.
    return await DatabaseService().checkAndProcessRecurringTransactions();
  }
}
