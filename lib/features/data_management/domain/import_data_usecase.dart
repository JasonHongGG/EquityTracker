import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uuid/uuid.dart';


import 'package:equity_tracker/features/category/data/category_repository.dart';

import 'package:equity_tracker/features/transaction/data/transaction_repository.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/features/transaction/data/transaction_model.dart';
import 'package:equity_tracker/features/category/data/category_model.dart';

class ImportResult {
  final List<int> insertedIds;
  final int failureCount;
  final String? lastError;

  ImportResult({
    required this.insertedIds,
    required this.failureCount,
    this.lastError,
  });
}

class ImportDataUseCase {
  final TransactionRepository _transactionRepository;
  final CategoryRepository _categoryRepository;
  final Uuid _uuid = const Uuid();

  ImportDataUseCase(this._transactionRepository, this._categoryRepository);

  Future<ImportResult> execute(String jsonContent) async {
    final json = jsonDecode(jsonContent);

    if (json is! Map || !json.containsKey('results') || json['results'] is! List) {
      throw Exception('Invalid JSON format: Missing "results" array');
    }

    final results = json['results'] as List;
    final List<int> insertedIds = [];
    int failureCount = 0;
    String? lastError;

    final allCategoriesList = await _categoryRepository.getCategories();
    final allCategories = List<CategoryModel>.from(allCategoriesList);

    for (var item in results) {
      if (item is Map) {
        try {
          final id = await _processAndInsertItem(item, allCategories);
          if (id != null) {
            insertedIds.add(id);
          } else {
            failureCount++;
          }
        } catch (e) {
          debugPrint('Error importing item: $e');
          failureCount++;
          lastError = e.toString();
        }
      }
    }

    return ImportResult(
      insertedIds: insertedIds,
      failureCount: failureCount,
      lastError: lastError,
    );
  }

  Future<int?> _processAndInsertItem(Map item, List<CategoryModel> allCategories) async {
    final amountDynamic = item['金額'];
    if (amountDynamic == null) return null;
    final amount = (amountDynamic as num).toInt().abs();

    final title = item['名稱']?.toString() ?? 'Untitled';

    DateTime date;
    if (item['時間'] != null && item['時間'] is Map) {
      final start = item['時間']['start'];
      if (start != null) {
        date = DateTime.parse(start);
      } else {
        date = DateTime.now();
      }
    } else {
      final created = item['_created_time'];
      if (created != null) {
        date = DateTime.parse(created);
      } else {
        date = DateTime.now();
      }
    }

    final rawCategory = item['類別']?.toString() ?? '其他';
    final categoryName = rawCategory.trim();
    CategoryModel matchedCategory;

    try {
      matchedCategory = allCategories.firstWhere((c) => c.name == categoryName);
    } catch (e) {
      matchedCategory = await _resolveOtherCategoryModel(allCategories);
    }

    TransactionType type;
    final balanceAmount = item['收支金額'];
    if (balanceAmount != null && (balanceAmount as num) < 0) {
      type = TransactionType.expense;
    } else if (balanceAmount != null && (balanceAmount as num) > 0) {
      type = TransactionType.income;
    } else {
      type = matchedCategory.type;
    }

    final transaction = TransactionModel(
      title: title,
      type: type,
      amount: amount,
      categoryId: matchedCategory.id,
      date: date,
      createdAt: DateTime.now(),
      note: '(匯入資料)',
    );

    return await _transactionRepository.insertTransaction(transaction);
  }

  Future<CategoryModel> _resolveOtherCategoryModel(List<CategoryModel> allCategories) async {
    try {
      return allCategories.firstWhere((c) => c.name == '其他');
    } catch (e) {
      final newOther = CategoryModel(
        id: _uuid.v4(),
        name: '其他',
        iconCodePoint: FontAwesomeIcons.question.codePoint,
        iconFontFamily: FontAwesomeIcons.question.fontFamily,
        iconFontPackage: FontAwesomeIcons.question.fontPackage,
        colorValue: Colors.grey.value,
        type: TransactionType.expense,
        isSystem: false,
        isEnabled: true,
        order: allCategories.length,
      );
      await _categoryRepository.addCategoryModel(newOther);
      allCategories.add(newOther);
      return newOther;
    }
  }
}
