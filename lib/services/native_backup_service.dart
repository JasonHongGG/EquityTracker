import 'dart:convert';
// import 'dart:io'; // Unused

import 'package:flutter/foundation.dart' hide Category;
// import 'package:uuid/uuid.dart'; // Unused

import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../models/transaction_type.dart';
import 'database_service.dart';

class NativeBackupService {
  final DatabaseService _dbService = DatabaseService();
  // final Uuid _uuid = const Uuid(); // Unused

  // ---------------------------------------------------------------------------
  // EXPORT
  // ---------------------------------------------------------------------------

  Future<String> createBackupJson() async {
    final categories = await _dbService.getCategories();
    final transactions = await _dbService.getTransactions();

    final backupData = {
      'version': 1,
      'timestamp': DateTime.now().toIso8601String(),
      'categories': categories.map((c) => c.toMap()).toList(),
      'transactions': transactions.map((t) => t.toMap()).toList(),
    };

    // Use specific encoder to ensure pretty printing for better readability if user opens it
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(backupData);
  }

  // ---------------------------------------------------------------------------
  // IMPORT
  // ---------------------------------------------------------------------------

  /// Returns a summary report of what was done.
  Future<BackupRestoreResult> restoreFromBackupContent(
    String jsonContent,
  ) async {
    dynamic json;
    try {
      json = jsonDecode(jsonContent);
    } catch (e) {
      throw const FormatException('Invalid JSON format');
    }

    if (json is! Map<String, dynamic>) {
      throw const FormatException('Root must be a JSON object');
    }

    // Basic validation
    if (!json.containsKey('categories') || !json.containsKey('transactions')) {
      throw const FormatException(
        'Missing "categories" or "transactions" fields',
      );
    }

    final List<dynamic> catList = json['categories'];
    final List<dynamic> txnList = json['transactions'];

    int categoriesImported = 0;
    int transactionsImported = 0;

    // 1. Load existing categories
    final existingCategories = await _dbService.getCategories();

    // Map from "Old (Imported) ID" -> "New (Local) ID"
    final Map<String, String> idMapping = {};

    // -------------------------------------------------------------------------
    // PROCESS CATEGORIES
    // -------------------------------------------------------------------------
    for (var catMap in catList) {
      if (catMap is! Map<String, dynamic>) continue;

      try {
        // We temporarily create a Category object to easily access fields
        // Note: fromMap might fail if schema changed, so wrap in try/catch
        final importedCat = Category.fromMap(catMap);

        // STRATEGY:
        // 1. Match by ID
        // 2. Match by Name + Type
        // 3. Create New

        // 1. Match by ID
        final finalId = _findMatchingCategoryId(
          importedCat,
          existingCategories,
        );

        if (finalId != null) {
          // Re-use existing ID mapping
          idMapping[importedCat.id] = finalId;
        } else {
          // Create new Category
          // If the ID in the backup is just valid UUID, we CAN try to reuse it
          // if it doesn't exist locally. But safe bet is strictly checking.
          // However, if we preserve ID, it's better for round-tripping.
          // Let's check if the ID *technically* already exists (we checked above).
          // If not exists, we can try to insert as is.

          await _dbService.insertCategory(importedCat);
          idMapping[importedCat.id] = importedCat.id; // Kept same ID

          // Update local cache for subsequent lookups
          existingCategories.add(importedCat);
          categoriesImported++;
        }
      } catch (e) {
        debugPrint('Skipping invalid category in backup: $e');
      }
    }

    // -------------------------------------------------------------------------
    // PROCESS TRANSACTIONS
    // -------------------------------------------------------------------------
    for (var txnMap in txnList) {
      if (txnMap is! Map<String, dynamic>) continue;

      try {
        final originalCatId = txnMap['categoryId'];

        // Resolve Category ID
        // If we have a mapping, use it.
        // If not (maybe category was deleted or failed import), fallback?
        // Fallback to "Other" or skip?
        // Let's fallback to finding a system "Expense" or "Income" category or skip.

        String? finalCatId = idMapping[originalCatId];

        if (finalCatId == null) {
          // Fallback logic
          // Try to find a default category
          if (existingCategories.isNotEmpty) {
            finalCatId = existingCategories.first.id; // Very naive fallback
          } else {
            // Should not happen if app is seeded
            continue; // Skip transaction
          }
        }

        // Prepare Transaction Model
        // We DISCARD 'id' to allow auto-increment to handle it
        final newTxn = TransactionModel(
          // id: null, // intentionally null
          title: txnMap['title'],
          type: TransactionType.fromJson(txnMap['type']),
          amount: txnMap['amount'],
          categoryId: finalCatId, // Mapped ID
          date: DateTime.parse(txnMap['date']),
          createdAt:
              DateTime.tryParse(txnMap['createdAt'] ?? '') ?? DateTime.now(),
          note: txnMap['note'],
        );

        await _dbService.insertTransaction(newTxn);
        transactionsImported++;
      } catch (e) {
        debugPrint('Skipping invalid transaction in backup: $e');
      }
    }

    return BackupRestoreResult(
      categoriesImported: categoriesImported,
      transactionsImported: transactionsImported,
    );
  }

  /// Helper to find existing category ID match
  String? _findMatchingCategoryId(Category imported, List<Category> existing) {
    // 1. Exact ID Match
    for (var ex in existing) {
      if (ex.id == imported.id) {
        return ex.id;
      }
    }

    // 2. Name + Type Match
    // (Ignore colors/icons for now, assume name is the key identifier for user)
    for (var ex in existing) {
      if (ex.name == imported.name && ex.type == imported.type) {
        return ex.id;
      }
    }

    return null; // No match found
  }
}

class BackupRestoreResult {
  final int categoriesImported;
  final int transactionsImported;

  BackupRestoreResult({
    required this.categoriesImported,
    required this.transactionsImported,
  });
}
