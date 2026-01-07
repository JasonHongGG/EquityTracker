import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../models/transaction_type.dart';

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
    return await openDatabase(
      path,
      version: 1, // Reset to version 1 for clean install
      onCreate: _onCreate,
    );
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
        isEnabled INTEGER
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
        name: '加油',
        iconCodePoint: FontAwesomeIcons.gasPump.codePoint,
        iconFontFamily: FontAwesomeIcons.gasPump.fontFamily,
        iconFontPackage: FontAwesomeIcons.gasPump.fontPackage,
        colorValue: Colors.indigo.toARGB32(),
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
        name: '提款',
        iconCodePoint: FontAwesomeIcons.buildingColumns.codePoint,
        iconFontFamily: FontAwesomeIcons.buildingColumns.fontFamily,
        iconFontPackage: FontAwesomeIcons.buildingColumns.fontPackage,
        colorValue: Colors.purple.toARGB32(),
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
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
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
}
