import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import '../models/transaction_model.dart';
import '../models/transaction_type.dart';
import '../services/database_service.dart';

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
      await DatabaseService().insertTransaction(transaction);
      // Wait a bit or just refetch. SQLite is fast.
      return _fetchAll();
    });
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await DatabaseService().updateTransaction(transaction);
      return _fetchAll();
    });
  }

  Future<void> deleteTransaction(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await DatabaseService().deleteTransaction(id);
      return _fetchAll();
    });
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

          // 4. Search Query (Note)
          if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
            if (t.note == null ||
                !t.note!.toLowerCase().contains(
                  filter.searchQuery!.toLowerCase(),
                )) {
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
        final grouped = groupBy(transactions, (TransactionModel t) => t.date);

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
