import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/transaction_type.dart';
import '../models/category_model.dart';
import '../services/database_service.dart';
import 'transaction_provider.dart';

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

  Future<void> deleteCategory(String id, TransactionType type) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final db = DatabaseService();

      // 1. Find or Create "Other" category
      final categories = await db.getCategories();
      Category? otherCategory;
      try {
        otherCategory = categories.firstWhere(
          (c) => c.name == '其他' && c.type == type,
        );
      } catch (_) {
        // Not found, create it
        otherCategory = Category(
          id: const Uuid().v4(),
          name: '其他',
          iconCodePoint: FontAwesomeIcons.circleQuestion.codePoint,
          iconFontFamily: FontAwesomeIcons.circleQuestion.fontFamily,
          iconFontPackage: FontAwesomeIcons.circleQuestion.fontPackage,
          colorValue: Colors.grey.value,
          type: type,
          isSystem: true,
          isEnabled: true,
        );
        await db.insertCategory(otherCategory);
      }

      // 2. Reassign to Other (only if not deleting "Other" itself, though UI should block that)
      if (id != otherCategory.id) {
        await db.reassignCategory(id, otherCategory.id);
      }

      // 3. Delete
      await db.deleteCategory(id);

      // 4. Invalidate TransactionList to force refresh of updated categoryIds
      ref.invalidate(transactionListProvider);

      return _fetchCategories();
    });
  }

  Future<void> updateOrder(List<Category> categories) async {
    // Optimistic update
    state = AsyncValue.data(categories);
    // Background sync
    await DatabaseService().updateCategoryOrder(categories);
  }
}

final categoryListProvider =
    AsyncNotifierProvider<CategoryList, List<Category>>(CategoryList.new);
