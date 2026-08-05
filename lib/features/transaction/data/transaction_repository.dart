import 'package:sqflite/sqflite.dart';
import 'package:equity_tracker/core/database/database_helper.dart';
import 'package:equity_tracker/features/transaction/data/transaction_model.dart';
import 'package:equity_tracker/features/transaction/data/recurring_transaction_model.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';

import 'package:equity_tracker/core/enums/sync_status.dart';

class TransactionRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'syncStatus != ?',
      whereArgs: [SyncStatus.pendingDelete.name],
      orderBy: 'date DESC, id DESC',
    );
    return List.generate(maps.length, (i) => TransactionModel.fromMap(maps[i]));
  }

  Future<List<TransactionModel>> getTransactionsByDateRange(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'date >= ? AND date <= ? AND syncStatus != ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String(), SyncStatus.pendingDelete.name],
      orderBy: 'date DESC, id DESC',
    );
    return List.generate(maps.length, (i) => TransactionModel.fromMap(maps[i]));
  }

  Future<List<TransactionModel>> getTransactionsByMonth(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    return getTransactionsByDateRange(start, end);
  }

  Future<int> getTotalAmountByType(TransactionType type) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      "SELECT SUM(amount) as total FROM transactions WHERE type = ? AND syncStatus != ?",
      [type.name, SyncStatus.pendingDelete.name]
    );
    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toInt();
    }
    return 0;
  }

  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await _dbHelper.database;
    return await db.insert('transactions', transaction.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<TransactionModel>> getPendingTransactions() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'syncStatus != ?',
      whereArgs: [SyncStatus.synced.name],
    );
    return List.generate(maps.length, (i) => TransactionModel.fromMap(maps[i]));
  }

  Future<TransactionModel?> getTransactionByNotionId(String notionId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'transactions',
      where: 'notionId = ?',
      whereArgs: [notionId],
    );
    if (maps.isEmpty) return null;
    return TransactionModel.fromMap(maps.first);
  }

  Future<List<TransactionModel>> getTransactionsWithoutNotionId() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'notionId IS NULL OR notionId = ""',
    );
    return List.generate(maps.length, (i) => TransactionModel.fromMap(maps[i]));
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

  Future<List<String>> searchFrequentTitles(String query, {int limit = 10}) async {
    final db = await _dbHelper.database;
    final String safeQuery = query.trim();

    if (safeQuery.isEmpty) {
      // 如果查詢字串為空，回傳全域最常記帳的前 N 筆標題
      final List<Map<String, dynamic>> maps = await db.rawQuery(
        "SELECT title, COUNT(title) as count FROM transactions WHERE title IS NOT NULL AND title != '' GROUP BY title ORDER BY count DESC LIMIT ?",
        [limit]
      );
      return maps.map((m) => m['title'] as String).toList();
    } else {
      // 若有查詢字串，則全域搜索包含該字串的標題，並依頻率排序
      final List<Map<String, dynamic>> maps = await db.rawQuery(
        "SELECT title, COUNT(title) as count FROM transactions WHERE title IS NOT NULL AND title != '' AND title LIKE ? GROUP BY title ORDER BY count DESC LIMIT ?",
        ['%$safeQuery%', limit]
      );
      return maps.map((m) => m['title'] as String).toList();
    }
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

  Future<void> clearAllRecurringTransactions() async {
    final db = await _dbHelper.database;
    await db.delete('recurring_transactions');
  }
}
