import 'package:equity_tracker/features/category/domain/category_entity.dart';
import 'package:equity_tracker/features/category/domain/i_category_repository.dart';
import 'package:equity_tracker/features/category/data/category_model.dart';
import 'package:equity_tracker/features/category/data/category_local_data_source.dart';

class CategoryRepositoryImpl implements ICategoryRepository {
  final ICategoryLocalDataSource _localDataSource;

  CategoryRepositoryImpl(this._localDataSource);

  @override
  Future<List<CategoryEntity>> getCategories() async {
    return await _localDataSource.getCategories();
  }

  @override
  Future<void> addCategory(CategoryEntity category) async {
    await _localDataSource.insertCategory(CategoryModel.fromEntity(category));
  }

  @override
  Future<void> updateCategory(CategoryEntity category) async {
    await _localDataSource.updateCategory(CategoryModel.fromEntity(category));
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _localDataSource.deleteCategory(id);
  }

  @override
  Future<void> reorderCategories(List<CategoryEntity> categories) async {
    final models = categories.map((e) => CategoryModel.fromEntity(e)).toList();
    await _localDataSource.updateCategoryOrder(models);
  }
}
