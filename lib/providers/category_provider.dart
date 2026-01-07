import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_model.dart';
import '../services/database_service.dart';

class CategoryList extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() async {
    return _fetchCategories();
  }

  Future<List<Category>> _fetchCategories() async {
    return await DatabaseService().getCategories();
  }

  Future<void> addCategory(Category category) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await DatabaseService().insertCategory(category);
      return _fetchCategories();
    });
  }

  Future<void> updateCategory(Category category) async {
    // Optimistic update could be done here, but safe refetch is easier
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await DatabaseService().updateCategory(category);
      return _fetchCategories();
    });
  }

  Future<void> deleteCategory(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await DatabaseService().deleteCategory(id);
      return _fetchCategories();
    });
  }
}

final categoryListProvider =
    AsyncNotifierProvider<CategoryList, List<Category>>(CategoryList.new);
