import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/domain/entities/category_entity.dart';
import 'package:equity_tracker/presentation/providers/repository_providers.dart';
import 'package:equity_tracker/presentation/providers/transaction_notifier.dart'; // To invalidate transaction list

class CategoryList extends AsyncNotifier<List<CategoryEntity>> {
  @override
  Future<List<CategoryEntity>> build() async {
    return _fetchCategories();
  }

  Future<List<CategoryEntity>> _fetchCategories() async {
    return await ref.read(categoryRepositoryProvider).getAllCategories();
  }

  Future<void> addCategory(CategoryEntity category) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(categoryRepositoryProvider).insertCategory(category);
      return _fetchCategories();
    });
  }

  Future<void> updateCategory(CategoryEntity category) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(categoryRepositoryProvider).updateCategory(category);
      return _fetchCategories();
    });
  }

  Future<void> deleteCategory(String id, TransactionType type) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(categoryRepositoryProvider);

      // 1. Find or Create "Other" category
      final categories = await repo.getAllCategories();
      CategoryEntity? otherCategory;
      try {
        otherCategory = categories.firstWhere(
          (c) => c.name == '?嗡?' && c.type == type,
        );
      } catch (_) {
        // Not found, create it
        otherCategory = CategoryEntity(
          id: const Uuid().v4(),
          name: '?嗡?',
          iconCodePoint: FontAwesomeIcons.circleQuestion.codePoint,
          iconFontFamily: FontAwesomeIcons.circleQuestion.fontFamily,
          iconFontPackage: FontAwesomeIcons.circleQuestion.fontPackage,
          colorValue: Colors.grey.value,
          type: type,
          isSystem: true,
          isEnabled: true,
        );
        await repo.insertCategory(otherCategory);
      }

      // 2. Reassign to Other
      if (id != otherCategory.id) {
        // Wait, we need reassign logic in TransactionRepository
        await ref.read(transactionRepositoryProvider).reassignCategory(id, otherCategory.id);
      }

      // 3. Delete
      await repo.deleteCategory(id);

      // 4. Invalidate TransactionList to force refresh
      ref.invalidate(transactionListProvider);

      return _fetchCategories();
    });
  }

  Future<void> updateOrder(List<CategoryEntity> categories) async {
    state = AsyncValue.data(categories);
    await ref.read(categoryRepositoryProvider).reorderCategories(categories);
  }
}

final categoryListProvider =
    AsyncNotifierProvider<CategoryList, List<CategoryEntity>>(CategoryList.new);
