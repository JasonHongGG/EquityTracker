import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/core/providers/repository_providers.dart';
import 'package:equity_tracker/features/transaction/domain/transaction_usecases.dart';
import 'package:equity_tracker/features/transaction/domain/services/title_suggestion_service.dart';
import 'package:equity_tracker/features/transaction/data/transaction_model.dart';
import 'package:equity_tracker/core/enums/sync_status.dart';
import 'package:equity_tracker/features/notion_sync/controllers/notion_config_controller.dart';
import 'package:equity_tracker/core/database/database_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:equity_tracker/features/notion_sync/services/notion_sync_service.dart';

// --- UseCase Providers ---

final filterTransactionsUseCaseProvider = Provider<FilterTransactionsUseCase>((ref) {
  return FilterTransactionsUseCase();
});

final groupTransactionsByDateUseCaseProvider = Provider<GroupTransactionsByDateUseCase>((ref) {
  return GroupTransactionsByDateUseCase();
});

final calculateMonthlyTotalsUseCaseProvider = Provider<CalculateMonthlyTotalsUseCase>((ref) {
  return CalculateMonthlyTotalsUseCase();
});

// --- Filter State ---
class TransactionFilter {
  final TransactionType? type;
  final List<String> categoryIds;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? searchQuery;

  TransactionFilter({
    this.type,
    this.categoryIds = const [],
    this.startDate,
    this.endDate,
    this.searchQuery,
  });

  TransactionFilter copyWith({
    TransactionType? type,
    List<String>? categoryIds,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  }) {
    return TransactionFilter(
      type: type ?? this.type,
      categoryIds: categoryIds ?? this.categoryIds,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class TransactionFilterNotifier extends Notifier<TransactionFilter> {
  @override
  TransactionFilter build() => TransactionFilter();

  void update(TransactionFilter filter) {
    state = filter;
  }
}

final transactionFilterProvider = NotifierProvider<TransactionFilterNotifier, TransactionFilter>(
  TransactionFilterNotifier.new,
);

class SelectedMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  void update(DateTime date) {
    state = date;
  }
}

final selectedMonthProvider = NotifierProvider<SelectedMonthNotifier, DateTime>(
  SelectedMonthNotifier.new,
);

// --- UI Notifier ---
class TransactionList extends AsyncNotifier<List<TransactionModel>> {
  @override
  Future<List<TransactionModel>> build() async {
    // Only fetch for the currently selected month
    final selectedMonth = ref.watch(selectedMonthProvider);
    return await ref.read(transactionRepositoryProvider).getTransactionsByMonth(selectedMonth);
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    final config = ref.read(notionConfigControllerProvider);
    var toInsert = transaction;
    if (config.isEnabled) {
      toInsert = toInsert.copyWith(syncStatus: SyncStatus.pendingCreate);
    }
    
    // Optimistic update
    if (state.hasValue) {
      state = AsyncData([toInsert, ...state.value!]);
    }
    
    try {
      final repo = ref.read(transactionRepositoryProvider);
      
      // Wait for the repository to return the inserted transaction (with the DB-generated ID)
      final insertedId = await repo.insertTransaction(toInsert);
      final transactionWithId = toInsert.copyWith(id: insertedId);

      if (config.isEnabled) {
        Future.microtask(() {
          ref.read(notionSyncServiceProvider).pushPendingChanges(silent: true);
        });
      }
      
      // Quietly reload data for consistency, without invalidating the whole provider
      final freshList = await repo.getTransactionsByMonth(ref.read(selectedMonthProvider));
      state = AsyncData(freshList);
    } catch (e) {
      debugPrint('Add Transaction Error: $e');
      rethrow; // Let the caller handle the error
    }
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    final config = ref.read(notionConfigControllerProvider);
    var toUpdate = transaction;
    if (config.isEnabled) {
      toUpdate = toUpdate.copyWith(syncStatus: SyncStatus.pendingUpdate);
    }

    try {
      // Optimistic update
      if (state.hasValue) {
        final currentList = state.value!;
        final index = currentList.indexWhere((t) => t.id == transaction.id);
        if (index != -1) {
          final newList = List<TransactionModel>.from(currentList);
          newList[index] = toUpdate;
          state = AsyncData(newList);
        }
      }

      await ref.read(transactionRepositoryProvider).updateTransaction(toUpdate);
      
      if (config.isEnabled) {
        Future.microtask(() {
          ref.read(notionSyncServiceProvider).pushPendingChanges(silent: true);
        });
      }
      
      // Quietly reload data for consistency
      final freshList = await ref.read(transactionRepositoryProvider).getTransactionsByMonth(ref.read(selectedMonthProvider));
      state = AsyncData(freshList);
    } catch (e) {
      debugPrint('Update Transaction Error: \$e');
      rethrow;
    }
  }

  Future<void> deleteTransaction(int id, [String? notionId]) async {
    final config = ref.read(notionConfigControllerProvider);
    
    try {
      // Optimistic update
      if (state.hasValue) {
        final currentList = state.value!;
        final newList = currentList.where((t) => t.id != id).toList();
        state = AsyncData(newList);
      }

      if (config.isEnabled && notionId != null && notionId.isNotEmpty) {
        final db = await DatabaseHelper.instance.database;
        await db.update(
          'transactions', 
          {'syncStatus': SyncStatus.pendingDelete.name},
          where: 'id = ?', 
          whereArgs: [id]
        );
        Future.microtask(() {
          ref.read(notionSyncServiceProvider).pushPendingChanges(silent: true);
        });
      } else {
        await ref.read(transactionRepositoryProvider).deleteTransaction(id);
      }
      
      // Quietly reload data for consistency
      final freshList = await ref.read(transactionRepositoryProvider).getTransactionsByMonth(ref.read(selectedMonthProvider));
      state = AsyncData(freshList);
    } catch (e) {
      debugPrint('Delete Transaction Error: \$e');
      rethrow;
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final transactionListProvider = AsyncNotifierProvider<TransactionList, List<TransactionModel>>(
  TransactionList.new,
);
    
final transactionNotifierProvider = transactionListProvider; 

// --- Derived Providers ---

final filteredTransactionsProvider = Provider<AsyncValue<List<TransactionModel>>>((ref) {
  final transactionsAsync = ref.watch(transactionListProvider);
  final filter = ref.watch(transactionFilterProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);
  final useCase = ref.watch(filterTransactionsUseCaseProvider);

  return transactionsAsync.whenData((transactions) {
    return useCase.execute(
      transactions: transactions,
      type: filter.type,
      categoryIds: filter.categoryIds,
      startDate: filter.startDate,
      endDate: filter.endDate,
      selectedMonth: selectedMonth,
      searchQuery: filter.searchQuery,
    );
  });
});

final monthlyTotalsProvider = Provider<AsyncValue<Map<TransactionType, int>>>((ref) {
  final filteredAsync = ref.watch(filteredTransactionsProvider);
  final useCase = ref.watch(calculateMonthlyTotalsUseCaseProvider);

  return filteredAsync.whenData((transactions) {
    return useCase.execute(transactions);
  });
});

final groupedTransactionsProvider = Provider<AsyncValue<Map<DateTime, List<TransactionModel>>>>((ref) {
  final filteredAsync = ref.watch(filteredTransactionsProvider);
  final useCase = ref.watch(groupTransactionsByDateUseCaseProvider);
  
  return filteredAsync.whenData((transactions) {
    return useCase.execute(transactions);
  });
});

final dailyTotalProvider = Provider.family<AsyncValue<int>, DateTime>((ref, date) {
  final groupedAsync = ref.watch(groupedTransactionsProvider);
  return groupedAsync.whenData((grouped) {
    final transactions = grouped[date] ?? [];
    int total = 0;
    for (var tx in transactions) {
      if (tx.type == TransactionType.income) {
        total += tx.amount;
      } else {
        total -= tx.amount;
      }
    }
    return total;
  });
});

final titleSuggestionServiceProvider = FutureProvider<TitleSuggestionService>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  final titles = await repo.getFrequentTitles(limit: 20);
  return TitleSuggestionService(titles);
});
