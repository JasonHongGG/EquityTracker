import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/features/transaction/data/transaction_model.dart';
import 'package:equity_tracker/features/category/data/category_model.dart';
import 'package:equity_tracker/features/notion_sync/domain/notion_models.dart';

class NotionApiClient {
  static const String _kApiUrl = 'https://api.notion.com/v1/pages';
  static const String _kNotionVersion = '2022-06-28';

  Future<bool> testConnection(String token, String dbId) async {
    if (token.isEmpty || dbId.isEmpty) return false;
    try {
      final url = Uri.parse('https://api.notion.com/v1/databases/$dbId');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Notion-Version': _kNotionVersion,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<TransactionModel>> fetchTransactions(
    String token, 
    String dbId, 
    List<CategoryModel> categories, 
    {DateTime? since}
  ) async {
    if (token.isEmpty || dbId.isEmpty) return [];

    try {
      final url = Uri.parse('https://api.notion.com/v1/databases/$dbId/query');
      final List<TransactionModel> allTransactions = [];

      bool hasMore = true;
      String? nextCursor;

      while (hasMore) {
        Map<String, dynamic> body = {};

        if (since != null) {
          body["filter"] = {
            "timestamp": "created_time",
            "created_time": {"after": since.toIso8601String()},
          };
        }

        if (nextCursor != null) {
          body["start_cursor"] = nextCursor;
        }

        final response = await http.post(
          url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Notion-Version': _kNotionVersion,
          },
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final results = data['results'] as List;

          hasMore = data['has_more'] as bool? ?? false;
          nextCursor = data['next_cursor'] as String?;

          for (var page in results) {
            try {
              final dto = NotionPageDto.fromJson(page);
              final transaction = NotionTransactionMapper.toTransactionModel(dto, categories);
              allTransactions.add(transaction);
            } on FormatException catch (e) {
              debugPrint('NotionAPI: Skipped transaction ID ${page["id"]}. Reason: ${e.message}');
              continue; // Skip invalid records but log them
            } catch (e) {
              debugPrint('NotionAPI: Unexpected error parsing transaction ${page["id"]}: $e');
              continue;
            }
          }
        } else {
          hasMore = false;
          debugPrint('NotionAPI: fetchTransactions failed with status \${response.statusCode}, body: \${response.body}');
        }
      }
      return allTransactions;
    } catch (e) {
      return [];
    }
  }

  Future<String?> createTransaction(
    String token,
    String dbId,
    TransactionModel transaction,
    String categoryName,
  ) async {
    try {
      final url = Uri.parse(_kApiUrl);
      final body = {
        "parent": {"database_id": dbId},
        "properties": {
          "名稱": {
            "title": [
              {
                "text": {"content": transaction.title ?? 'Transaction'}
              }
            ]
          },
          "金額": {"number": transaction.amount},
          "時間": {
            "date": {"start": transaction.date.toIso8601String()}
          },
          "類別": {
            "select": {"name": categoryName}
          }
        }
      };

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Notion-Version': _kNotionVersion,
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['id'] as String?;
      }
    } catch (e) {
      // Ignore
    }
    return null;
  }

  Future<bool> updateTransaction(
    String token,
    String pageId,
    TransactionModel transaction,
    String categoryName,
  ) async {
    try {
      final url = Uri.parse('$_kApiUrl/$pageId');
      final body = {
        "properties": {
          "名稱": {
            "title": [
              {
                "text": {"content": transaction.title ?? 'Transaction'}
              }
            ]
          },
          "金額": {"number": transaction.amount},
          "時間": {
            "date": {"start": transaction.date.toIso8601String()}
          },
          "類別": {
            "select": {"name": categoryName}
          }
        }
      };

      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Notion-Version': _kNotionVersion,
        },
        body: jsonEncode(body),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteTransaction(String token, String pageId) async {
    try {
      final url = Uri.parse('$_kApiUrl/$pageId');
      final body = {
        "archived": true
      };

      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Notion-Version': _kNotionVersion,
        },
        body: jsonEncode(body),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
