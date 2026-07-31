import 'package:equity_tracker/core/database/database_helper.dart';
import 'package:equity_tracker/features/transaction/data/transaction_model.dart';
import 'package:equity_tracker/features/transaction/data/recurring_transaction_model.dart';

abstract class ITransactionLocalDataSource {
  Future<List<TransactionModel>> getAllTransactions();
  Future<List<TransactionModel>> getTransactionsByDateRange(DateTime start, DateTime end);
  Future<int> insertTransaction(TransactionModel transaction);
  Future<int> updateTransaction(TransactionModel transaction);
  Future<int> deleteTransaction(int id);
  Future<void> clearAllTransactions();
  Future<List<String>> getRecentTitles({int limit = 1000});
  Future<void> reassignCategory(String oldCategoryId, String newCategoryId);
  
  // Recurring
  Future<List<RecurringTransactionModel>> getAllRecurringTransactions();
  Future<List<RecurringTransactionModel>> getEnabledRecurringTransactions();
  Future<int> insertRecurringTransaction(RecurringTransactionModel transaction);
  Future<int> updateRecurringTransaction(RecurringTransactionModel transaction);
  Future<int> deleteRecurringTransaction(int id);
}

class TransactionLocalDataSourceImpl implements ITransactionLocalDataSource {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await _dbHelper.database;
    final maps = await db.query('transactions', orderBy: 'date DESC, createdAt DESC');
    return maps.map<TransactionModel>((map) => TransactionModel.fromMap(map)).toList();
  }

  @override
  Future<List<TransactionModel>> getTransactionsByDateRange(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final startStr = start.toIso8601String().split('T')[0];
    final endStr = '${end.toIso8601String().split('T')[0]}T23:59:59';
    final maps = await db.query(
      'transactions',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startStr, endStr],
      orderBy: 'date DESC, createdAt DESC',
    );
    return maps.map<TransactionModel>((map) => TransactionModel.fromMap(map)).toList();
  }

  @override
  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await _dbHelper.database;
    try {
      return await db.insert('transactions', transaction.toMap());
    } catch (e) {
      if (e.toString().contains('no column named title')) {
        await db.execute('ALTER TABLE transactions ADD COLUMN title TEXT');
        return await db.insert('transactions', transaction.toMap());
      }
      rethrow;
    }
  }

  @override
  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await _dbHelper.database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  @override
  Future<int> deleteTransaction(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> clearAllTransactions() async {
    final db = await _dbHelper.database;
    await db.delete('transactions');
  }

  @override
  Future<List<String>> getRecentTitles({int limit = 1000}) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT title, COUNT(*) as frequency 
      FROM transactions 
      WHERE title IS NOT NULL AND title != ''
      GROUP BY title
      ORDER BY frequency DESC
      LIMIT ?
      ''',
      [limit],
    );
    return List.generate(maps.length, (i) => maps[i]['title'] as String);
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

  @override
  Future<List<RecurringTransactionModel>> getAllRecurringTransactions() async {
    final db = await _dbHelper.database;
    final maps = await db.query('recurring_transactions', orderBy: 'nextDueDate ASC');
    return maps.map<RecurringTransactionModel>((map) => RecurringTransactionModel.fromMap(map)).toList();
  }

  @override
  Future<List<RecurringTransactionModel>> getEnabledRecurringTransactions() async {
    final db = await _dbHelper.database;
    final maps = await db.query('recurring_transactions', where: 'isEnabled = ?', whereArgs: [1]);
    return maps.map<RecurringTransactionModel>((map) => RecurringTransactionModel.fromMap(map)).toList();
  }

  @override
  Future<int> insertRecurringTransaction(RecurringTransactionModel transaction) async {
    final db = await _dbHelper.database;
    return await db.insert('recurring_transactions', transaction.toMap());
  }

  @override
  Future<int> updateRecurringTransaction(RecurringTransactionModel transaction) async {
    final db = await _dbHelper.database;
    return await db.update(
      'recurring_transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  @override
  Future<int> deleteRecurringTransaction(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('recurring_transactions', where: 'id = ?', whereArgs: [id]);
  }
}
