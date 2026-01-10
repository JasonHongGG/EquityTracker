import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../models/transaction_type.dart';
import '../models/recurring_transaction_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'equity_tracker.db');
    final db = await openDatabase(
      path,
      version: 1, // Reset to version 1 for clean install
      onCreate: _onCreate,
    );

    // Ensure recurring_transactions table exists for existing users
    await _createRecurringTransactionsTable(db);

    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create Categories Table
    await db.execute('''
      CREATE TABLE categories(
        id TEXT PRIMARY KEY,
        name TEXT,
        iconCodePoint INTEGER,
        iconFontFamily TEXT,
        iconFontPackage TEXT,
        colorValue INTEGER,
        type TEXT,
        isSystem INTEGER,
        isEnabled INTEGER,
        sortOrder INTEGER DEFAULT 0
      )
    ''');

    // Create Transactions Table
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        type TEXT,
        amount INTEGER,
        categoryId TEXT,
        date TEXT,
        createdAt TEXT,
        note TEXT,
        FOREIGN KEY(categoryId) REFERENCES categories(id)
      )
    ''');

    await _seedCategories(db);
  }
  // _onUpgrade removed

  Future<void> _createRecurringTransactionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS recurring_transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        amount INTEGER,
        type TEXT,
        categoryId TEXT,
        frequency TEXT,
        nextDueDate TEXT,
        lastGeneratedDate TEXT,
        isEnabled INTEGER,
        note TEXT,
        createdAt TEXT,
        FOREIGN KEY(categoryId) REFERENCES categories(id)
      )
    ''');
  }

  Future<void> _seedCategories(Database db) async {
    const uuid = Uuid();

    final List<Category> systemCategories = [
      // Expense
      Category(
        id: uuid.v4(),
        name: '伙食',
        iconCodePoint: FontAwesomeIcons.utensils.codePoint,
        iconFontFamily: FontAwesomeIcons.utensils.fontFamily,
        iconFontPackage: FontAwesomeIcons.utensils.fontPackage,
        colorValue: Colors.orange.toARGB32(),
        type: TransactionType.expense,
        isSystem: true,
        isEnabled: true,
      ),
      Category(
        id: uuid.v4(),
        name: '交通',
        iconCodePoint: FontAwesomeIcons.trainSubway.codePoint,
        iconFontFamily: FontAwesomeIcons.trainSubway.fontFamily,
        iconFontPackage: FontAwesomeIcons.trainSubway.fontPackage,
        colorValue: Colors.green.toARGB32(),
        type: TransactionType.expense,
        isSystem: true,
        isEnabled: true,
      ),
      Category(
        id: uuid.v4(),
        name: '生活',
        iconCodePoint: FontAwesomeIcons.basketShopping.codePoint,
        iconFontFamily: FontAwesomeIcons.basketShopping.fontFamily,
        iconFontPackage: FontAwesomeIcons.basketShopping.fontPackage,
        colorValue: Colors.blue.toARGB32(),
        type: TransactionType.expense,
        isSystem: true,
        isEnabled: true,
      ),
      Category(
        id: uuid.v4(),
        name: '加油',
        iconCodePoint: FontAwesomeIcons.gasPump.codePoint,
        iconFontFamily: FontAwesomeIcons.gasPump.fontFamily,
        iconFontPackage: FontAwesomeIcons.gasPump.fontPackage,
        colorValue: Colors.indigo.toARGB32(),
        type: TransactionType.expense,
        isSystem: true,
        isEnabled: true,
      ),
      Category(
        id: uuid.v4(),
        name: '醫療', // Medical
        iconCodePoint: FontAwesomeIcons.briefcaseMedical.codePoint,
        iconFontFamily: FontAwesomeIcons.briefcaseMedical.fontFamily,
        iconFontPackage: FontAwesomeIcons.briefcaseMedical.fontPackage,
        colorValue: Colors.redAccent.toARGB32(),
        type: TransactionType.expense,
        isSystem: true,
        isEnabled: true,
      ),
      Category(
        id: uuid.v4(),
        name: '購物', // Shopping
        iconCodePoint: FontAwesomeIcons.bagShopping.codePoint,
        iconFontFamily: FontAwesomeIcons.bagShopping.fontFamily,
        iconFontPackage: FontAwesomeIcons.bagShopping.fontPackage,
        colorValue: Colors.deepPurpleAccent.toARGB32(),
        type: TransactionType.expense,
        isSystem: true,
        isEnabled: true,
      ),
      Category(
        id: uuid.v4(),
        name: '娛樂', // Entertainment
        iconCodePoint: Icons.sports_esports.codePoint,
        iconFontFamily: 'MaterialIcons',
        iconFontPackage: null,
        colorValue: Colors.pinkAccent.toARGB32(),
        type: TransactionType.expense,
        isSystem: true,
        isEnabled: true,
      ),
      Category(
        id: uuid.v4(),
        name: '社交', // Social
        iconCodePoint: Icons.groups.codePoint,
        iconFontFamily: 'MaterialIcons',
        iconFontPackage: null,
        colorValue: Colors.lightBlueAccent.toARGB32(),
        type: TransactionType.expense,
        isSystem: true,
        isEnabled: true,
      ),
      Category(
        id: uuid.v4(),
        name: '禮物', // Gift
        iconCodePoint: FontAwesomeIcons.gift.codePoint,
        iconFontFamily: FontAwesomeIcons.gift.fontFamily,
        iconFontPackage: FontAwesomeIcons.gift.fontPackage,
        colorValue: Colors.red.shade300.toARGB32(),
        type: TransactionType.expense,
        isSystem: true,
        isEnabled: true,
      ),
      Category(
        id: uuid.v4(),
        name: '其他', // Other (Expense)
        iconCodePoint: FontAwesomeIcons.circleQuestion.codePoint,
        iconFontFamily: FontAwesomeIcons.circleQuestion.fontFamily,
        iconFontPackage: FontAwesomeIcons.circleQuestion.fontPackage,
        colorValue: Colors.grey.toARGB32(),
        type: TransactionType.expense,
        isSystem: true,
        isEnabled: true,
      ),
      // Income
      Category(
        id: uuid.v4(),
        name: '薪水',
        iconCodePoint: FontAwesomeIcons.moneyBillWave.codePoint,
        iconFontFamily: FontAwesomeIcons.moneyBillWave.fontFamily,
        iconFontPackage: FontAwesomeIcons.moneyBillWave.fontPackage,
        colorValue: Colors.teal.toARGB32(),
        type: TransactionType.income,
        isSystem: true,
        isEnabled: true,
      ),
      Category(
        id: uuid.v4(),
        name: '投資', // Investment
        iconCodePoint: FontAwesomeIcons.chartLine.codePoint,
        iconFontFamily: FontAwesomeIcons.chartLine.fontFamily,
        iconFontPackage: FontAwesomeIcons.chartLine.fontPackage,
        colorValue: Colors.greenAccent.shade700.toARGB32(),
        type: TransactionType.income,
        isSystem: true,
        isEnabled: true,
      ),
      Category(
        id: uuid.v4(),
        name: '交易', // Trading
        iconCodePoint: FontAwesomeIcons.moneyBillTransfer.codePoint,
        iconFontFamily: FontAwesomeIcons.moneyBillTransfer.fontFamily,
        iconFontPackage: FontAwesomeIcons.moneyBillTransfer.fontPackage,
        colorValue: Colors.cyan.shade600.toARGB32(),
        type: TransactionType.income,
        isSystem: true,
        isEnabled: true,
      ),
      Category(
        id: uuid.v4(),
        name: '獎金', // Bonus
        iconCodePoint: FontAwesomeIcons.sackDollar.codePoint,
        iconFontFamily: FontAwesomeIcons.sackDollar.fontFamily,
        iconFontPackage: FontAwesomeIcons.sackDollar.fontPackage,
        colorValue: Colors.amber.shade700.toARGB32(),
        type: TransactionType.income,
        isSystem: true,
        isEnabled: true,
      ),
      Category(
        id: uuid.v4(),
        name: '回饋', // Cashback
        iconCodePoint: FontAwesomeIcons.percent.codePoint,
        iconFontFamily: FontAwesomeIcons.percent.fontFamily,
        iconFontPackage: FontAwesomeIcons.percent.fontPackage,
        colorValue: Colors.orangeAccent.shade400.toARGB32(),
        type: TransactionType.income,
        isSystem: true,
        isEnabled: true,
      ),
      Category(
        id: uuid.v4(),
        name: '提款',
        iconCodePoint: FontAwesomeIcons.moneyBill1.codePoint,
        iconFontFamily: FontAwesomeIcons.moneyBill1.fontFamily,
        iconFontPackage: FontAwesomeIcons.moneyBill1.fontPackage,
        colorValue: Colors.indigo.shade400.toARGB32(),
        type: TransactionType.income,
        isSystem: true,
        isEnabled: true,
      ),
      Category(
        id: uuid.v4(),
        name: '其他', // Other (Income)
        iconCodePoint: FontAwesomeIcons.circleQuestion.codePoint,
        iconFontFamily: FontAwesomeIcons.circleQuestion.fontFamily,
        iconFontPackage: FontAwesomeIcons.circleQuestion.fontPackage,
        colorValue: Colors.grey.toARGB32(),
        type: TransactionType.income,
        isSystem: true,
        isEnabled: true,
      ),
    ];

    for (var cat in systemCategories) {
      await db.insert('categories', cat.toMap());
    }
  }

  // Helper Methods
  Future<List<Category>> getCategories() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'categories',
        orderBy: 'sortOrder ASC',
      );
      return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
    } catch (e) {
      // Check for both common error message formats
      if (e.toString().contains('no column named sortOrder') ||
          e.toString().contains('no such column: sortOrder')) {
        // Migration: Add sortOrder column
        await db.execute(
          'ALTER TABLE categories ADD COLUMN sortOrder INTEGER DEFAULT 0',
        );
        final List<Map<String, dynamic>> maps = await db.query(
          'categories',
          orderBy: 'sortOrder ASC',
        );
        return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
      }
      rethrow;
    }
  }

  Future<void> insertCategory(Category category) async {
    final db = await database;
    await db.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateCategory(Category category) async {
    final db = await database;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> updateCategoryOrder(List<Category> categories) async {
    final db = await database;
    final batch = db.batch();
    for (var category in categories) {
      batch.update(
        'categories',
        {'sortOrder': category.order},
        where: 'id = ?',
        whereArgs: [category.id],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> reassignCategory(String oldId, String newId) async {
    final db = await database;
    await db.update(
      'transactions',
      {'categoryId': newId},
      where: 'categoryId = ?',
      whereArgs: [oldId],
    );
  }

  Future<void> deleteCategory(String id) async {
    final db = await database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<TransactionModel>> getTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'createdAt DESC', // As per requirement 3.4
    );
    return List.generate(maps.length, (i) => TransactionModel.fromMap(maps[i]));
  }

  Future<List<TransactionModel>> getTransactionsByDate(DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().split('T')[0];
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'date = ?',
      whereArgs: [dateStr],
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => TransactionModel.fromMap(maps[i]));
  }

  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await database;
    try {
      return await db.insert('transactions', transaction.toMap());
    } catch (e) {
      if (e.toString().contains('no column named title')) {
        // Fallback migration for hot-reload scenarios
        await db.execute('ALTER TABLE transactions ADD COLUMN title TEXT');
        return await db.insert('transactions', transaction.toMap());
      }
      rethrow;
    }
  }

  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // For Dashboard/Stats
  Future<List<TransactionModel>> getTransactionsInPeriod(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final startStr = start.toIso8601String().split('T')[0];
    final endStr = end.toIso8601String().split('T')[0];

    // Simple string comparison works for YYYY-MM-DD
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startStr, endStr],
      orderBy: 'date DESC, createdAt DESC',
    );
    return List.generate(maps.length, (i) => TransactionModel.fromMap(maps[i]));
  }

  Future<List<String>> getRecentTitles({int limit = 1000}) async {
    final db = await database;
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

  Future<void> clearAllTransactions() async {
    final db = await database;
    await db.delete('transactions');
  }

  // Recurring Transactions Methods

  Future<List<RecurringTransaction>> getRecurringTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'recurring_transactions',
      orderBy: 'nextDueDate ASC',
    );
    return List.generate(
      maps.length,
      (i) => RecurringTransaction.fromMap(maps[i]),
    );
  }

  Future<int> insertRecurringTransaction(
    RecurringTransaction transaction,
  ) async {
    final db = await database;
    return await db.insert('recurring_transactions', transaction.toMap());
  }

  Future<int> updateRecurringTransaction(
    RecurringTransaction transaction,
  ) async {
    final db = await database;
    return await db.update(
      'recurring_transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteRecurringTransaction(int id) async {
    final db = await database;
    return await db.delete(
      'recurring_transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Checks for due recurring transactions and generates them.
  /// Returns true if any transactions were generated.
  /// Checks for due recurring transactions and generates them.
  /// Returns true if any transactions were generated.
  Future<bool> checkAndProcessRecurringTransactions() async {
    final db = await database;
    bool generatedAny = false;

    // 1. Get all enabled recurring transactions
    final List<Map<String, dynamic>> maps = await db.query(
      'recurring_transactions',
      where: 'isEnabled = ?',
      whereArgs: [1],
    );

    final recurringList = List.generate(
      maps.length,
      (i) => RecurringTransaction.fromMap(maps[i]),
    );

    final now = DateTime.now();

    for (var recurring in recurringList) {
      DateTime nextDue = recurring.nextDueDate;
      // Store original time components to preserve them
      final int hour = nextDue.hour;
      final int minute = nextDue.minute;

      // Using a while loop to handle multiple missed periods
      // Limit to 50 iterations to prevent infinite loop
      int iterations = 0;

      // key change: Compare EXACT time (nextDue) vs Current Time (now)
      // This fixes "Premature Triggering" where future times today were fired immediately
      while ((nextDue.isBefore(now) || nextDue.isAtSameMomentAs(now)) &&
          iterations < 50) {
        generatedAny = true;
        iterations++;

        // Create the transaction
        // Use nextDue as the date so the record reflects when it SHOULD have happened
        final newTransaction = TransactionModel(
          title: recurring.title,
          type: recurring.type,
          amount: recurring.amount,
          categoryId: recurring.categoryId,
          date: nextDue,
          createdAt: DateTime.now(), // But created now
          note:
              'Auto-generated: ${recurring.note ?? recurring.frequency.label}',
        );

        await insertTransaction(newTransaction);

        // Update last generated date
        DateTime lastGenerated = nextDue;

        // Calculate new next due date
        // Key change: We must reconstruct the date WITH the original time
        // The previous logic used 'nextDueDay' which stripped time.

        DateTime calcNewDate(DateTime base) {
          return DateTime(base.year, base.month, base.day, hour, minute);
        }

        switch (recurring.frequency) {
          case Frequency.daily:
            nextDue = nextDue.add(const Duration(days: 1));
            break;
          case Frequency.weekly:
            nextDue = nextDue.add(const Duration(days: 7));
            break;
          case Frequency.monthly:
            // Standard month addition logic
            var newMonth = nextDue.month + 1;
            var newYear = nextDue.year;
            if (newMonth > 12) {
              newMonth = 1;
              newYear++;
            }
            // Logic to preserve the "Day of Month" anchor if possible
            // Note: recurring.nextDueDate is the anchor.
            // Ideally we need to store "start day" separately if we want perfect "Jan 31 -> Feb 28 -> Mar 31" logic.
            // But simplistic approach: use current nextDue day? No, use previous nextDue day?
            // If nextDue was Jan 31, +1 month -> Feb 28 (via logic).
            // If we just add month to Feb 28, we get Mar 28. We lose the "31st" anchor.
            // For now, let's just stick to "Add 1 month to current nextDue".
            // It will drift if we hit a shorter month.
            // Improving logic to attempt to keep the original day would be better but requires schema change (store 'anchorDay').
            // Let's stick to the previous implementation's logic but preserve time.

            // Re-implementing previous logic safely:
            int targetDay = nextDue.day;
            // Ideally we want the targetDay to be the one from the *original* setting,
            // but we don't have that stored separately. We only have 'nextDue'.
            // So if it was already adjusted (Feb 28), it stays 28.

            int daysInNewMonth = DateUtils.getDaysInMonth(newYear, newMonth);
            int actualDay = targetDay > daysInNewMonth
                ? daysInNewMonth
                : targetDay;

            nextDue = DateTime(newYear, newMonth, actualDay, hour, minute);
            break;
          case Frequency.yearly:
            var newYear = nextDue.year + 1;
            // Same drift issue applies, but less frequent.
            int targetDay = nextDue.day;
            int daysInNewMonth = DateUtils.getDaysInMonth(
              newYear,
              nextDue.month,
            );
            int actualDay = targetDay > daysInNewMonth
                ? daysInNewMonth
                : targetDay;

            nextDue = DateTime(newYear, nextDue.month, actualDay, hour, minute);
            break;
        }

        // Update the recurring record
        await updateRecurringTransaction(
          recurring.copyWith(
            lastGeneratedDate: lastGenerated,
            nextDueDate: nextDue,
          ),
        );
      }
    }

    return generatedAny;
  }
}
