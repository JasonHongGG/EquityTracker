import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../models/transaction_type.dart';
import 'database_service.dart';

class ImportService {
  final DatabaseService _dbService = DatabaseService();
  final Uuid _uuid = const Uuid();

  Future<ImportResult> importFromJsonFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw Exception('File not found');
    }

    final content = await file.readAsString();
    final json = jsonDecode(content);

    if (json is! Map ||
        !json.containsKey('results') ||
        json['results'] is! List) {
      throw Exception('Invalid JSON format: Missing "results" array');
    }

    final results = json['results'] as List;
    final List<int> insertedIds = [];
    int failureCount = 0;
    String? lastError;

    // Pre-fetch categories
    final allCategories = await _dbService.getCategories();

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

  Future<int?> _processAndInsertItem(
    Map item,
    List<Category> allCategories,
  ) async {
    // 1. Extract Fields
    final amountDynamic = item['金額'];
    if (amountDynamic == null) return null; // Mandatory field
    final amount = (amountDynamic as num).toInt().abs();

    final title = item['Page']?.toString() ?? 'Untitled';

    // Date Parsing
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

    // Category Logic
    final rawCategory = item['類別']?.toString() ?? '其他';
    final categoryName = rawCategory.trim();
    Category matchedCategory;

    // 1. Try exact match
    try {
      matchedCategory = allCategories.firstWhere((c) => c.name == categoryName);
    } catch (e) {
      // 2. No match, resolve "其他"
      matchedCategory = await _resolveOtherCategory(allCategories);
    }

    // Type Logic
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
      note: 'Imported',
    );

    return await _dbService.insertTransaction(transaction);
  }

  // Helper for "Other" category resolution
  Future<Category> _resolveOtherCategory(List<Category> allCategories) async {
    try {
      return allCategories.firstWhere((c) => c.name == '其他');
    } catch (e) {
      // Create it
      final newOther = Category(
        id: _uuid.v4(),
        name: '其他',
        iconCodePoint: FontAwesomeIcons.question.codePoint,
        iconFontFamily: FontAwesomeIcons.question.fontFamily,
        iconFontPackage: FontAwesomeIcons.question.fontPackage,
        colorValue: Colors.grey.toARGB32(),
        type: TransactionType.expense,
        isSystem: false,
        isEnabled: true,
      );
      await _dbService.insertCategory(newOther);
      allCategories.add(newOther);
      return newOther;
    }
  }

  Future<void> revertImport(List<int> ids) async {
    for (var id in ids) {
      await _dbService.deleteTransaction(id);
    }
  }
}

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
