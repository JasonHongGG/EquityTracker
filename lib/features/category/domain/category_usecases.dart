import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';

import 'package:equity_tracker/features/category/data/category_repository.dart';
import 'package:equity_tracker/features/transaction/data/transaction_repository.dart';
import 'package:equity_tracker/features/category/data/category_model.dart';

class GetCategoriesUseCase {
  final CategoryRepository categoryRepository;
  GetCategoriesUseCase(this.categoryRepository);

  Future<List<CategoryModel>> execute() => categoryRepository.getCategories();
}

class AddCategoryUseCase {
  final CategoryRepository categoryRepository;
  AddCategoryUseCase(this.categoryRepository);

  Future<void> execute(CategoryModel category) => categoryRepository.addCategoryModel(category);
}

class UpdateCategoryUseCase {
  final CategoryRepository categoryRepository;
  UpdateCategoryUseCase(this.categoryRepository);

  Future<void> execute(CategoryModel category) => categoryRepository.updateCategoryModel(category);
}

class ReorderCategoriesUseCase {
  final CategoryRepository categoryRepository;
  ReorderCategoriesUseCase(this.categoryRepository);

  Future<void> execute(List<CategoryModel> categories) => categoryRepository.updateCategoryOrder(categories);
}

class DeleteCategoryUseCase {
  final CategoryRepository categoryRepository;
  final TransactionRepository transactionRepository;

  DeleteCategoryUseCase(this.categoryRepository, this.transactionRepository);

  Future<void> execute(String id, TransactionType type) async {
    // 1. Find or Create "Other" category
    final categories = await categoryRepository.getCategories();
    CategoryModel? otherCategory;
    
    try {
      otherCategory = categories.firstWhere(
        (c) => c.name == '未分類' && c.type == type,
      );
    } catch (_) {
      // Not found, create it
      otherCategory = CategoryModel(
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
      await categoryRepository.addCategoryModel(otherCategory);
    }

    // 2. Reassign to Other
    if (id != otherCategory!.id) {
      await transactionRepository.reassignCategoryModel(id, otherCategory.id);
    }

    // 3. Delete
    await categoryRepository.deleteCategoryModel(id);
  }
}
