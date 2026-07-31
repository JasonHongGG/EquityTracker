import 'package:sqflite/sqflite.dart';
import 'package:equity_tracker/core/database/database_helper.dart';
import 'package:equity_tracker/features/category/data/category_model.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';

class CategoryRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<CategoryModel>> getCategories() async {
    final db = await _dbHelper.database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'categories',
        orderBy: 'sortOrder ASC',
      );
      return List.generate(maps.length, (i) => CategoryModel.fromMap(maps[i]));
    } catch (e) {
      if (e.toString().contains('sortOrder')) {
        await db.execute('ALTER TABLE categories ADD COLUMN sortOrder INTEGER DEFAULT 0');
        final List<Map<String, dynamic>> maps = await db.query('categories', orderBy: 'sortOrder ASC');
        return List.generate(maps.length, (i) => CategoryModel.fromMap(maps[i]));
      }
      rethrow;
    }
  }

  Future<void> addCategoryModel(CategoryModel category) async {
    final db = await _dbHelper.database;
    await db.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateCategoryModel(CategoryModel category) async {
    final db = await _dbHelper.database;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> updateCategoryOrder(List<CategoryModel> categories) async {
    final db = await _dbHelper.database;
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

  Future<void> deleteCategoryModel(String id) async {
    final db = await _dbHelper.database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}
