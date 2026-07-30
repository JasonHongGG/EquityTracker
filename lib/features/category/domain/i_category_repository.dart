import 'package:equity_tracker/features/category/domain/category_entity.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';

abstract class ICategoryRepository {
  Future<List<CategoryEntity>> getAllCategories();
  Future<List<CategoryEntity>> getCategoriesByType(TransactionType type);
  Future<void> insertCategory(CategoryEntity category);
  Future<void> updateCategory(CategoryEntity category);
  Future<void> deleteCategory(String id);
  Future<void> reorderCategories(List<CategoryEntity> categories);
}
