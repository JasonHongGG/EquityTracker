import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../services/database_service.dart';
import '../models/transaction_type.dart';

class NotionService {
  static const String _kNotionToken = 'notion_token';
  static const String _kNotionDatabaseId = 'notion_database_id';
  static const String _kApiUrl = 'https://api.notion.com/v1/pages';
  static const String _kNotionVersion = '2022-06-28';

  // Singleton instance
  static final NotionService _instance = NotionService._internal();
  factory NotionService() => _instance;
  NotionService._internal();

  static const String _kNotionEnabled = 'notion_enabled';

  // Getters for settings UI
  Future<String?> get token async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kNotionToken);
  }

  Future<String?> get databaseId async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kNotionDatabaseId);
  }

  Future<bool> get isEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kNotionEnabled) ?? false;
  }

  // Setters for settings UI
  Future<void> setCredentials(String token, String dbId, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kNotionToken, token);
    await prefs.setString(_kNotionDatabaseId, dbId);
    await prefs.setBool(_kNotionEnabled, enabled);
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotionEnabled, enabled);
  }

  Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kNotionToken);
    await prefs.remove(_kNotionDatabaseId);
    await prefs.remove(_kNotionEnabled);
  }

  // Test Connection
  Future<bool> testConnection() async {
    final apiKey = await token;
    final dbId = await databaseId;

    if (apiKey == null || dbId == null || apiKey.isEmpty || dbId.isEmpty) {
      return false;
    }

    try {
      // Trying to retrieve database info to verify access
      final url = Uri.parse('https://api.notion.com/v1/databases/$dbId');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Notion-Version': _kNotionVersion,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Sync Transaction
  Future<void> syncTransaction(TransactionModel transaction) async {
    final apiKey = await token;
    final dbId = await databaseId;

    if (apiKey == null || dbId == null || apiKey.isEmpty || dbId.isEmpty) {
      return; // Not configured
    }

    if (!await isEnabled) {
      return; // Disabled
    }

    try {
      // 1. Get Category Name
      String categoryName = 'Unknown';
      // This causes a database read for every sync, arguably okay for "fire and forget"
      // Alternatively we could pass the category name into this method
      final categories = await DatabaseService().getCategories();
      final category = categories.firstWhere(
        (c) => c.id == transaction.categoryId,
        orElse: () => Category(
          id: 'unknown',
          name: 'Unknown',
          iconCodePoint: 0,
          iconFontFamily: '',
          iconFontPackage: '',
          colorValue: 0,
          type: transaction.type,
          isSystem: false,
          isEnabled: true,
        ),
      );
      categoryName = category.name;

      // 2. Prepare Payload
      // Requirements: Name (Title), Amount (Number), Category (Select/Text), Date (Date)
      final body = jsonEncode({
        "parent": {"database_id": dbId},
        "properties": {
          "名稱": {
            "title": [
              {
                "text": {"content": transaction.title ?? 'Unified Transaction'},
              },
            ],
          },
          "金額": {"number": transaction.amount},
          "類別": {
            // Using Rich Text is safer than Select if the option doesn't exist in Notion schema
            // But user asked for "Category" which implies Select to many users.
            // Given requirement "Notion DB doesn't limit columns but MUST have these 4",
            // safe bet is Rich Text or Select. Let's try Select (will create if allowed) or just Text.
            // Text is safest for "experimental". Let's stick to Rich Text for "Category" unless user specified Select type.
            // User just said "Category" item.
            // To be robust, let's use Rich Text for easiest compatibility,
            // OR Select if we want it to look nice.
            // Let's use Select for "類別" as it makes more sense for categories.
            "select": {"name": categoryName},
          },
          "時間": {
            "date": {"start": transaction.date.toIso8601String()},
          },
        },
      });

      // 3. Send Request
      final response = await http.post(
        Uri.parse(_kApiUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'Notion-Version': _kNotionVersion,
        },
        body: body,
      );

      if (response.statusCode != 200) {
        print('Notion Sync Failed: ${response.body}');
        // Optionally store failed sync to retry, but strictly "experimental" means simple
      } else {
        print('Notion Sync Success');
      }
    } catch (e) {
      print('Notion Sync Error: $e');
    }
  }

  // Fetch Transactions (Pull)
  Future<List<TransactionModel>> fetchTransactions({DateTime? since}) async {
    final apiKey = await token;
    final dbId = await databaseId;

    if (apiKey == null || dbId == null || apiKey.isEmpty || dbId.isEmpty) {
      return [];
    }

    try {
      final url = Uri.parse('https://api.notion.com/v1/databases/$dbId/query');
      final List<TransactionModel> allTransactions = [];

      bool hasMore = true;
      String? nextCursor;

      // Cache categories for lookup
      final categories = await DatabaseService().getCategories();

      while (hasMore) {
        Map<String, dynamic> body = {};

        // Filter
        if (since != null) {
          body["filter"] = {
            "timestamp": "created_time",
            "created_time": {"after": since.toIso8601String()},
          };
        }

        // Pagination
        if (nextCursor != null) {
          body["start_cursor"] = nextCursor;
        }

        final response = await http.post(
          url,
          headers: {
            'Authorization': 'Bearer $apiKey',
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

              // 1. Title (Name)
              String? title;
              final nameProp = props['名稱']?['title'];
              if (nameProp != null && (nameProp as List).isNotEmpty) {
                title = nameProp[0]['plain_text'];
              }
              if (title == null || title.isEmpty) title = 'Notion Import';

              // 2. Amount (Number)
              int amount = 0;
              final amountProp = props['金額']?['number'];
              if (amountProp != null) {
                amount = (amountProp as num).toInt();
              }
              if (amount <= 0) continue; // Skip invalid amounts

              // 3. Date (Date)
              DateTime date = DateTime.now();
              final dateProp = props['時間']?['date']?['start'];
              if (dateProp != null) {
                date = DateTime.parse(dateProp);
              }

              // 4. Category (Select/RichText) -> ID
              String categoryId = 'other'; // Default
              String? catName;

              // Try Select
              catName = props['類別']?['select']?['name'];
              if (catName == null) {
                // Try Rich Text (if user used Text instead of Select)
                final richText = props['類別']?['rich_text'];
                if (richText != null && (richText as List).isNotEmpty) {
                  catName = richText[0]['plain_text'];
                }
              }

              if (catName != null) {
                final matched = categories.firstWhere(
                  (c) => c.name.toLowerCase() == catName!.toLowerCase(),
                  orElse: () => categories.firstWhere((c) => c.id == 'other'),
                );
                categoryId = matched.id;
              }

              // Determine Type based on Category?
              // Or default to Expense?
              // Notion doesn't strictly have "Type" in requirements.
              // We can infer from Category if matched.
              // If matched category is Income, use Income. Else Expense.
              TransactionType type = TransactionType.expense;
              if (catName != null) {
                final matched = categories.firstWhere(
                  (c) => c.name.toLowerCase() == catName!.toLowerCase(),
                  orElse: () => categories.firstWhere((c) => c.id == 'other'),
                );
                type = matched.type;
              }

              allTransactions.add(
                TransactionModel(
                  title: title,
                  amount: amount,
                  type: type,
                  categoryId: categoryId,
                  date: date,
                  createdAt: DateTime.now(), // Local creation time
                  note: '',
                ),
              );
            } catch (e) {
              print('Error parsing page: $e');
              continue;
            }
          }
        } else {
          print('Notion Fetch Failed: ${response.body}');
          // If a page fails, we stop
          hasMore = false;
        }
      }
      return allTransactions;
    } catch (e) {
      print('Notion Fetch Error: $e');
      return [];
    }
  }
}
