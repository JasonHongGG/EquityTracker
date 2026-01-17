import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import '../models/transaction_model.dart';
import '../models/transaction_type.dart';
import '../services/database_service.dart';
import '../services/notion_service.dart';

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

// --- Filter State Notifier ---
class TransactionFilterNotifier extends Notifier<TransactionFilter> {
  @override
  TransactionFilter build() => TransactionFilter();

  void update(TransactionFilter filter) {
    state = filter;
  }
}

final transactionFilterProvider =
    NotifierProvider<TransactionFilterNotifier, TransactionFilter>(
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

// --- Transaction List Notifier ---
class TransactionList extends AsyncNotifier<List<TransactionModel>> {
  @override
  Future<List<TransactionModel>> build() async {
    return _fetchAll();
  }

  Future<List<TransactionModel>> _fetchAll() async {
    return await DatabaseService().getTransactions();
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      int localId = await DatabaseService().insertTransaction(transaction);

      // Perform background sync without blocking UI
      _backgroundSyncAdd(transaction.copyWith(id: localId));

      return _fetchAll();
    });
  }

  Future<void> _backgroundSyncAdd(TransactionModel transaction) async {
    try {
      // Notion Sync
      final notionId = await NotionService().syncTransaction(transaction);
      if (notionId != null) {
        // Update local record with Notion ID
        final insertedTx = transaction.copyWith(
          id: transaction.id,
          notionId: notionId,
        );
        await DatabaseService().updateTransaction(insertedTx);

        // Use ref.read here effectively if we inside the class?
        // We are in AsyncNotifier, we can update state if we want, but it might trigger rebuilds.
        // It's better to just update DB. If user refreshes they get it.
        // Or checking if the item still exists (wasn't deleted)
      }
    } catch (e) {
      print('Background Sync Error: $e');
    }
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await DatabaseService().updateTransaction(transaction);

      // Background Sync
      _backgroundSyncUpdate(transaction);

      return _fetchAll();
    });
  }

  Future<void> _backgroundSyncUpdate(TransactionModel transaction) async {
    try {
      if (transaction.notionId != null) {
        await NotionService().updateTransaction(
          transaction.notionId!,
          transaction,
        );
      }
    } catch (e) {
      print('Background Update Error: $e');
    }
  }

  Future<void> deleteTransaction(int id, [String? notionId]) async {
    // Capture the notionId from current state if not provided, BEFORE deleting locally
    String? targetNotionId = notionId;
    if (targetNotionId == null && state.hasValue) {
      final tx = state.value!.firstWhereOrNull((t) => t.id == id);
      targetNotionId = tx?.notionId;
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await DatabaseService().deleteTransaction(id);

      // Background Sync
      if (targetNotionId != null) {
        _backgroundSyncDelete(targetNotionId);
      }

      return _fetchAll();
    });
  }

  Future<void> _backgroundSyncDelete(String notionId) async {
    try {
      await NotionService().deleteTransaction(notionId);
    } catch (e) {
      print('Background Delete Error: $e');
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchAll());
  }
}

final transactionListProvider =
    AsyncNotifierProvider<TransactionList, List<TransactionModel>>(
      TransactionList.new,
    );

// --- Derived Providers ---

// Filitered Transactions
final filteredTransactionsProvider =
    Provider<AsyncValue<List<TransactionModel>>>((ref) {
      final transactionsAsync = ref.watch(transactionListProvider);
      final filter = ref.watch(transactionFilterProvider);
      final selectedMonth = ref.watch(selectedMonthProvider);

      return transactionsAsync.whenData((transactions) {
        return transactions.where((t) {
          // 1. Type Filter
          if (filter.type != null && t.type != filter.type) {
            return false;
          }

          // 2. Category Filter
          if (filter.categoryIds.isNotEmpty &&
              !filter.categoryIds.contains(t.categoryId)) {
            return false;
          }

          // 3. Date Range (Priority: Custom Filter > Selected Month)
          DateTime? effectiveStart = filter.startDate;
          DateTime? effectiveEnd = filter.endDate;

          // If no custom range is set, use the selected month
          if (effectiveStart == null && effectiveEnd == null) {
            effectiveStart = DateTime(
              selectedMonth.year,
              selectedMonth.month,
              1,
            );
            effectiveEnd = DateTime(
              selectedMonth.year,
              selectedMonth.month + 1,
              0,
              23,
              59,
              59,
            );
          }

          if (effectiveStart != null && t.date.isBefore(effectiveStart)) {
            return false;
          }
          if (effectiveEnd != null && t.date.isAfter(effectiveEnd)) {
            return false;
          }

          // 4. Search Query (Title or Note)
          if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
            final query = filter.searchQuery!.toLowerCase();
            final matchTitle =
                t.title != null && t.title!.toLowerCase().contains(query);
            final matchNote =
                t.note != null && t.note!.toLowerCase().contains(query);

            if (!matchTitle && !matchNote) {
              return false;
            }
          }

          return true;
        }).toList();
      });
    });

// Grouped by Date (for UI)
final groupedTransactionsProvider =
    Provider<AsyncValue<Map<DateTime, List<TransactionModel>>>>((ref) {
      final filteredAsync = ref.watch(filteredTransactionsProvider);

      return filteredAsync.whenData((transactions) {
        // Group by date
        final grouped = groupBy(
          transactions,
          (TransactionModel t) =>
              DateTime(t.date.year, t.date.month, t.date.day),
        );

        // Sort keys (dates) descending
        final sortedKeys = grouped.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        final Map<DateTime, List<TransactionModel>> sortedMap = {};
        for (var key in sortedKeys) {
          sortedMap[key] = grouped[key]!;
        }
        return sortedMap;
      });
    });

// Daily Total (for Header)
// Returns a map of Date -> NetAmount (Income - Expense)
final dailyTotalProvider = Provider<AsyncValue<Map<DateTime, int>>>((ref) {
  final groupedAsync = ref.watch(groupedTransactionsProvider);

  return groupedAsync.whenData((grouped) {
    final Map<DateTime, int> totals = {};
    grouped.forEach((date, txs) {
      int sum = 0;
      for (var tx in txs) {
        if (tx.type == TransactionType.income) {
          sum += tx.amount;
        } else {
          sum -= tx.amount;
        }
      }
      totals[date] = sum;
    });
    return totals;
  });
});

// Recent Titles for Autocomplete
final recentTitlesProvider = FutureProvider<List<String>>((ref) async {
  // refresh trigger via watching list provider if we want real-time updates when adding new ones
  ref.watch(transactionListProvider);
  final dbService = DatabaseService();
  return await dbService.getRecentTitles();
});
