import 'package:equity_tracker/domain/entities/category_entity.dart';
import 'package:equity_tracker/domain/repositories/i_category_repository.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/data/models/category_model.dart';
import 'package:equity_tracker/data/datasources/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class CategoryRepositoryImpl implements ICategoryRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Future<List<CategoryEntity>> getAllCategories() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      orderBy: 'sortOrder ASC',
    );
    return maps.map<CategoryEntity>((map) => CategoryModel.fromMap(map)).toList();
  }

  @override
  Future<List<CategoryEntity>> getCategoriesByType(TransactionType type) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'type = ?',
      whereArgs: [type.name],
      orderBy: 'sortOrder ASC',
    );
    return maps.map<CategoryEntity>((map) => CategoryModel.fromMap(map)).toList();
  }

  @override
  Future<void> insertCategory(CategoryEntity category) async {
    final db = await _dbHelper.database;
    final model = CategoryModel.fromEntity(category);
    await db.insert(
      'categories',
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateCategory(CategoryEntity category) async {
    final db = await _dbHelper.database;
    final model = CategoryModel.fromEntity(category);
    await db.update(
      'categories',
      model.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  @override
  Future<void> deleteCategory(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> reorderCategories(List<CategoryEntity> categories) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (int i = 0; i < categories.length; i++) {
      final updatedCat = categories[i].copyWith(order: i);
      final model = CategoryModel.fromEntity(updatedCat);
      batch.update(
        'categories',
        model.toMap(),
        where: 'id = ?',
        whereArgs: [model.id],
      );
    }
    await batch.commit(noResult: true);
  }
}
