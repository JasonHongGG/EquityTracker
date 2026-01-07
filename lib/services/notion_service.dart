import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart'; // To get category name if needed
import '../services/database_service.dart';

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
}
