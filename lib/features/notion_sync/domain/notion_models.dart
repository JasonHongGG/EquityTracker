// No flutter/foundation.dart
import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/features/transaction/data/transaction_model.dart';
import 'package:equity_tracker/features/category/data/category_model.dart';

class NotionPageDto {
  final String id;
  final Map<String, dynamic> properties;

  NotionPageDto({required this.id, required this.properties});

  factory NotionPageDto.fromJson(Map<String, dynamic> json) {
    return NotionPageDto(
      id: json['id'] as String,
      properties: json['properties'] as Map<String, dynamic>? ?? {},
    );
  }
}

class NotionTransactionMapper {
  /// Maps a NotionPageDto to a TransactionModel.
  /// Throws FormatException if critical properties are missing or invalid.
  static TransactionModel toTransactionModel(
    NotionPageDto dto,
    List<CategoryModel> availableCategories,
  ) {
    final props = dto.properties;

    // Parse Title
    String title = 'Notion Import';
    final nameProp = props['名稱']?['title'];
    if (nameProp != null && (nameProp as List).isNotEmpty) {
      title = nameProp[0]['plain_text'] as String? ?? 'Notion Import';
    }

    // Parse Amount
    final amountProp = props['金額']?['number'];
    if (amountProp == null) {
      throw const FormatException('Missing or invalid amount field (金額)');
    }
    final amount = (amountProp as num).toInt();
    if (amount <= 0) {
      throw const FormatException('Amount is zero or negative, skipping');
    }

    // Parse Date
    DateTime date = DateTime.now();
    final dateProp = props['時間']?['date']?['start'];
    if (dateProp != null) {
      date = DateTime.parse(dateProp.toString()).toLocal();
    } else {
      throw const FormatException('Missing date field (時間)');
    }

    // Parse Category
    String? catName;
    catName = props['類別']?['select']?['name']?.toString();
    if (catName == null) {
      final richText = props['類別']?['rich_text'];
      if (richText != null && (richText as List).isNotEmpty) {
        catName = richText[0]['plain_text']?.toString();
      }
    }

    String categoryId = 'other';
    TransactionType type = TransactionType.expense;

    if (catName != null) {
      // Find matching category
      try {
        final matched = availableCategories.firstWhere(
          (c) => c.name.toLowerCase() == catName!.toLowerCase(),
        );
        categoryId = matched.id;
        type = matched.type;
      } catch (e) {
        // Fallback to 'other' if no exact match
        try {
          final otherCat = availableCategories.firstWhere((c) => c.id == 'other');
          categoryId = otherCat.id;
          type = otherCat.type;
        } catch (e2) {
          // Fallback to the first available category if 'other' is missing
          if (availableCategories.isNotEmpty) {
            categoryId = availableCategories.first.id;
            type = availableCategories.first.type;
          } else {
            throw const FormatException('No categories available in the system');
          }
        }
      }
    } else {
       try {
          final otherCat = availableCategories.firstWhere((c) => c.id == 'other');
          categoryId = otherCat.id;
          type = otherCat.type;
        } catch (e2) {
          if (availableCategories.isNotEmpty) {
            categoryId = availableCategories.first.id;
            type = availableCategories.first.type;
          } else {
            throw const FormatException('No categories available in the system');
          }
        }
    }

    return TransactionModel(
      notionId: dto.id,
      title: title,
      amount: amount,
      type: type,
      categoryId: categoryId,
      date: date,
      createdAt: DateTime.now(),
      note: '',
    );
  }
}
