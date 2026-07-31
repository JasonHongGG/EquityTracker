import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/features/category/domain/category_entity.dart';
import 'package:equity_tracker/features/category/domain/i_category_repository.dart';
import 'package:equity_tracker/features/transaction/domain/i_transaction_repository.dart';

class GetCategoriesUseCase {
  final ICategoryRepository categoryRepository;
  GetCategoriesUseCase(this.categoryRepository);

  Future<List<CategoryEntity>> execute() => categoryRepository.getAllCategories();
}

class AddCategoryUseCase {
  final ICategoryRepository categoryRepository;
  AddCategoryUseCase(this.categoryRepository);

  Future<void> execute(CategoryEntity category) => categoryRepository.insertCategory(category);
}

class UpdateCategoryUseCase {
  final ICategoryRepository categoryRepository;
  UpdateCategoryUseCase(this.categoryRepository);

  Future<void> execute(CategoryEntity category) => categoryRepository.updateCategory(category);
}

class ReorderCategoriesUseCase {
  final ICategoryRepository categoryRepository;
  ReorderCategoriesUseCase(this.categoryRepository);

  Future<void> execute(List<CategoryEntity> categories) => categoryRepository.reorderCategories(categories);
}

class DeleteCategoryUseCase {
  final ICategoryRepository categoryRepository;
  final ITransactionRepository transactionRepository;

  DeleteCategoryUseCase(this.categoryRepository, this.transactionRepository);

  Future<void> execute(String id, TransactionType type) async {
    // 1. Find or Create "Other" category
    final categories = await categoryRepository.getAllCategories();
    CategoryEntity? otherCategory;
    
    try {
      otherCategory = categories.firstWhere(
        (c) => c.name == '未分類' && c.type == type,
      );
    } catch (_) {
      // Not found, create it
      otherCategory = CategoryEntity(
        id: const Uuid().v4(),
        name: '未分類',
        iconCodePoint: FontAwesomeIcons.circleQuestion.codePoint,
        iconFontFamily: FontAwesomeIcons.circleQuestion.fontFamily,
        iconFontPackage: FontAwesomeIcons.circleQuestion.fontPackage,
        colorValue: Colors.grey.value,
        type: type,
        isSystem: true,
        isEnabled: true,
      );
      await categoryRepository.insertCategory(otherCategory);
    }

    // 2. Reassign to Other
    if (id != otherCategory.id) {
      await transactionRepository.reassignCategory(id, otherCategory.id);
    }

    // 3. Delete
    await categoryRepository.deleteCategory(id);
  }
}
