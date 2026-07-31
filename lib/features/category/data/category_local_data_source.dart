import 'package:sqflite/sqflite.dart';
import 'package:equity_tracker/core/database/database_helper.dart';
import 'package:equity_tracker/features/category/data/category_model.dart';

abstract class ICategoryLocalDataSource {
  Future<List<CategoryModel>> getCategories();
  Future<void> insertCategory(CategoryModel category);
  Future<void> updateCategory(CategoryModel category);
  Future<void> updateCategoryOrder(List<CategoryModel> categories);
  Future<void> deleteCategory(String id);
}

class CategoryLocalDataSourceImpl implements ICategoryLocalDataSource {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Future<List<CategoryModel>> getCategories() async {
    final db = await _dbHelper.database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'categories',
        orderBy: 'sortOrder ASC',
      );
      return List.generate(maps.length, (i) => CategoryModel.fromMap(maps[i]));
    } catch (e) {
      if (e.toString().contains('no column named sortOrder') ||
          e.toString().contains('no such column: sortOrder')) {
        await db.execute(
          'ALTER TABLE categories ADD COLUMN sortOrder INTEGER DEFAULT 0',
        );
        final List<Map<String, dynamic>> maps = await db.query(
          'categories',
          orderBy: 'sortOrder ASC',
        );
        return List.generate(maps.length, (i) => CategoryModel.fromMap(maps[i]));
      }
      rethrow;
    }
  }

  @override
  Future<void> insertCategory(CategoryModel category) async {
    final db = await _dbHelper.database;
    await db.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateCategory(CategoryModel category) async {
    final db = await _dbHelper.database;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  @override
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

  @override
  Future<void> deleteCategory(String id) async {
    final db = await _dbHelper.database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}
