import 'package:sqflite/sqflite.dart';
import 'package:equity_tracker/core/database/database_helper.dart';
import 'package:equity_tracker/features/transaction/data/transaction_model.dart';
import 'package:equity_tracker/features/transaction/data/recurring_transaction_model.dart';

class TransactionRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('transactions', orderBy: 'date DESC, id DESC');
    return List.generate(maps.length, (i) => TransactionModel.fromMap(maps[i]));
  }

  Future<List<TransactionModel>> getTransactionsByDateRange(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC, id DESC',
    );
    return List.generate(maps.length, (i) => TransactionModel.fromMap(maps[i]));
  }

  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await _dbHelper.database;
    return await db.insert('transactions', transaction.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await _dbHelper.database;
    return await db.update('transactions', transaction.toMap(), where: 'id = ?', whereArgs: [transaction.id]);
  }

  Future<int> deleteTransaction(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAllTransactions() async {
    final db = await _dbHelper.database;
    await db.delete('transactions');
  }

  Future<void> reassignCategoryModel(String oldCategoryId, String newCategoryId) async {
    final db = await _dbHelper.database;
    await db.update(
      'transactions',
      {'categoryId': newCategoryId},
      where: 'categoryId = ?',
      whereArgs: [oldCategoryId],
    );
  }

  Future<List<String>> getRecentTitles({int limit = 100}) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      columns: ['title'],
      orderBy: 'id DESC',
      limit: limit,
    );
    return maps.map((m) => m['title'] as String).where((t) => t.isNotEmpty).toSet().toList();
  }

  Future<List<RecurringTransactionModel>> getAllRecurringTransactions() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('recurring_transactions', orderBy: 'id DESC');
    return List.generate(maps.length, (i) => RecurringTransactionModel.fromMap(maps[i]));
  }

  Future<List<RecurringTransactionModel>> getEnabledRecurringTransactions() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('recurring_transactions', where: 'isEnabled = ?', whereArgs: [1]);
    return List.generate(maps.length, (i) => RecurringTransactionModel.fromMap(maps[i]));
  }

  Future<int> insertRecurringTransaction(RecurringTransactionModel transaction) async {
    final db = await _dbHelper.database;
    return await db.insert('recurring_transactions', transaction.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateRecurringTransaction(RecurringTransactionModel transaction) async {
    final db = await _dbHelper.database;
    return await db.update('recurring_transactions', transaction.toMap(), where: 'id = ?', whereArgs: [transaction.id]);
  }

  Future<int> deleteRecurringTransaction(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('recurring_transactions', where: 'id = ?', whereArgs: [id]);
  }
}
