import 'dart:convert';
import 'package:equity_tracker/features/category/domain/category_entity.dart';
import 'package:equity_tracker/features/transaction/domain/transaction_entity.dart';
import 'package:equity_tracker/features/category/domain/i_category_repository.dart';
import 'package:equity_tracker/features/transaction/domain/i_transaction_repository.dart';
import 'package:equity_tracker/features/category/data/category_model.dart';
import 'package:equity_tracker/features/transaction/data/transaction_model.dart';
import 'package:uuid/uuid.dart';

class BackupRestoreResult {
  final int categoriesImported;
  final int transactionsImported;
  const BackupRestoreResult(this.categoriesImported, this.transactionsImported);
}

class NativeBackupService {
  final ICategoryRepository _categoryRepo;
  final ITransactionRepository _transactionRepo;

  NativeBackupService(this._categoryRepo, this._transactionRepo);

  Future<String> createBackupJson() async {
    final categories = await _categoryRepo.getAllCategories();
    final transactions = await _transactionRepo.getAllTransactions();

    final backupData = {
      'version': 1,
      'timestamp': DateTime.now().toIso8601String(),
      'categories': categories.map((c) => CategoryModel.fromEntity(c).toMap()).toList(),
      'transactions': transactions.map((t) => TransactionModel.fromEntity(t).toMap()).toList(),
    };

    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(backupData);
  }

  Future<BackupRestoreResult> restoreFromBackupContent(String jsonContent) async {
    dynamic json = jsonDecode(jsonContent);
    if (json is! Map<String, dynamic>) throw const FormatException('Root must be object');

    final List<dynamic> catList = json['categories'] ?? [];
    final List<dynamic> txnList = json['transactions'] ?? [];

    int categoriesImported = 0;
    int transactionsImported = 0;

    final existingCategories = await _categoryRepo.getAllCategories();
    final Map<String, String> idMapping = {};

    for (var catMap in catList) {
      if (catMap is! Map<String, dynamic>) continue;
      try {
        final importedCat = CategoryModel.fromMap(catMap);
        final finalId = _findMatchingCategoryId(importedCat, existingCategories);
        if (finalId != null) {
          idMapping[importedCat.id] = finalId;
        } else {
          await _categoryRepo.insertCategory(importedCat);
          idMapping[importedCat.id] = importedCat.id;
          categoriesImported++;
        }
      } catch (e) {
        // ignore
      }
    }

    for (var txnMap in txnList) {
      if (txnMap is! Map<String, dynamic>) continue;
      try {
        final importedTxn = TransactionModel.fromMap(txnMap);
        final mappedCategoryId = idMapping[importedTxn.categoryId];
        if (mappedCategoryId == null) continue;
        
        final newTxn = TransactionModel(
          notionId: importedTxn.notionId,
          title: importedTxn.title,
          type: importedTxn.type,
          amount: importedTxn.amount,
          categoryId: mappedCategoryId,
          date: importedTxn.date,
          createdAt: importedTxn.createdAt,
          note: importedTxn.note,
        );
        await _transactionRepo.insertTransaction(newTxn);
        transactionsImported++;
      } catch (e) {
        // ignore
      }
    }
    return BackupRestoreResult(categoriesImported, transactionsImported);
  }

  String? _findMatchingCategoryId(CategoryEntity imported, List<CategoryEntity> existing) {
    for (var e in existing) {
      if (e.id == imported.id) return e.id;
    }
    for (var e in existing) {
      if (e.name == imported.name && e.type == imported.type) return e.id;
    }
    return null;
  }
}
