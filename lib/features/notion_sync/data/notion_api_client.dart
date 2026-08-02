import 'dart:convert';
import 'package:http/http.dart' as http;


import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/features/transaction/data/transaction_model.dart';
import 'package:equity_tracker/features/category/data/category_model.dart';

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
              final props = page['properties'];
              if (props == null) continue;

              String? title;
              final nameProp = props['名稱']?['title'];
              if (nameProp != null && (nameProp as List).isNotEmpty) {
                title = nameProp[0]['plain_text'];
              }
              if (title == null || title.isEmpty) title = 'Notion Import';

              int amount = 0;
              final amountProp = props['金額']?['number'];
              if (amountProp != null) {
                amount = (amountProp as num).toInt();
              }
              if (amount <= 0) continue; 

              DateTime date = DateTime.now();
              final dateProp = props['時間']?['date']?['start'];
              if (dateProp != null) {
                date = DateTime.parse(dateProp).toLocal();
              }

              String categoryId = 'other';
              String? catName;

              catName = props['類別']?['select']?['name'];
              if (catName == null) {
                final richText = props['類別']?['rich_text'];
                if (richText != null && (richText as List).isNotEmpty) {
                  catName = richText[0]['plain_text'];
                }
              }

              TransactionType type = TransactionType.expense;
              if (catName != null) {
                final matched = categories.firstWhere(
                  (c) => c.name.toLowerCase() == catName!.toLowerCase(),
                  orElse: () => categories.firstWhere((c) => c.id == 'other', orElse: () => categories.first),
                );
                categoryId = matched.id;
                type = matched.type;
              }

              allTransactions.add(
                TransactionModel(
                  notionId: page['id'],
                  title: title,
                  amount: amount,
                  type: type,
                  categoryId: categoryId,
                  date: date,
                  createdAt: DateTime.now(),
                  note: '',
                ),
              );
            } catch (e) {
              continue;
            }
          }
        } else {
          hasMore = false;
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
