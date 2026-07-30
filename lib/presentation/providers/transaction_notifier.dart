import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:equity_tracker/domain/entities/transaction_entity.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/presentation/providers/repository_providers.dart';

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
class TransactionList extends AsyncNotifier<List<TransactionEntity>> {
  @override
  Future<List<TransactionEntity>> build() async {
    return _fetchAll();
  }

  Future<List<TransactionEntity>> _fetchAll() async {
    return await ref.read(transactionRepositoryProvider).getAllTransactions();
  }

  Future<void> addTransaction(TransactionEntity transaction) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(transactionRepositoryProvider).insertTransaction(transaction);
      // NOTE: Cloud sync logic can be re-added here if needed
      return _fetchAll();
    });
  }

  Future<void> updateTransaction(TransactionEntity transaction) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(transactionRepositoryProvider).updateTransaction(transaction);
      return _fetchAll();
    });
  }

  Future<void> deleteTransaction(int id, [String? notionId]) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(transactionRepositoryProvider).deleteTransaction(id);
      return _fetchAll();
    });
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchAll());
  }
}

final transactionListProvider =
    AsyncNotifierProvider<TransactionList, List<TransactionEntity>>(
      TransactionList.new,
    );
    
final transactionNotifierProvider = transactionListProvider; // Alias for backward compatibility if needed

// --- Derived Providers ---

final filteredTransactionsProvider =
    Provider<AsyncValue<List<TransactionEntity>>>((ref) {
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

          // 3. Date Range Filter
          if (filter.startDate != null &&
              t.date.isBefore(filter.startDate!)) {
            return false;
          }
          if (filter.endDate != null &&
              t.date.isAfter(filter.endDate!.add(const Duration(days: 1)))) {
            return false;
          }

          // 4. Monthly Filter
          if (filter.startDate == null && filter.endDate == null) {
            if (t.date.year != selectedMonth.year ||
                t.date.month != selectedMonth.month) {
              return false;
            }
          }

          // 5. Search Query Filter
          if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
            final query = filter.searchQuery!.toLowerCase();
            final titleMatch = t.title?.toLowerCase().contains(query) ?? false;
            final noteMatch = t.note?.toLowerCase().contains(query) ?? false;
            if (!titleMatch && !noteMatch) {
              return false;
            }
          }

          return true;
        }).toList();
      });
    });

final monthlyTotalsProvider = Provider<AsyncValue<Map<TransactionType, int>>>((ref) {
  final filteredAsync = ref.watch(filteredTransactionsProvider);

  return filteredAsync.whenData((transactions) {
    int totalIncome = 0;
    int totalExpense = 0;

    for (var t in transactions) {
      if (t.type == TransactionType.income) {
        totalIncome += t.amount;
      } else {
        totalExpense += t.amount;
      }
    }

    return {
      TransactionType.income: totalIncome,
      TransactionType.expense: totalExpense,
    };
  });
});

// Helper providers for UI grouping
final groupedTransactionsProvider = Provider<AsyncValue<Map<DateTime, List<TransactionEntity>>>>((ref) {
  final filteredAsync = ref.watch(filteredTransactionsProvider);
  
  return filteredAsync.whenData((transactions) {
    final Map<DateTime, List<TransactionEntity>> grouped = {};
    for (var tx in transactions) {
      final date = DateTime(tx.date.year, tx.date.month, tx.date.day);
      grouped.putIfAbsent(date, () => []).add(tx);
    }
    return grouped;
  });
});

final dailyTotalProvider = Provider.family<AsyncValue<int>, DateTime>((ref, date) {
  final groupedAsync = ref.watch(groupedTransactionsProvider);
  return groupedAsync.whenData((grouped) {
    final transactions = grouped[date] ?? [];
    int total = 0;
    for (var tx in transactions) {
      if (tx.type.name == 'income') {
        total += tx.amount;
      } else {
        total -= tx.amount;
      }
    }
    return total;
  });
});

final recentTitlesProvider = Provider<List<String>>((ref) {
  final transactions = ref.watch(transactionListProvider).value ?? [];
  final titles = transactions.map((t) => t.title ?? '').where((t) => t.isNotEmpty).toSet().toList();
  return titles.take(10).toList();
});
