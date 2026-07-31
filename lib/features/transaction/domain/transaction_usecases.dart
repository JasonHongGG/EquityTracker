
import 'package:equity_tracker/features/transaction/data/transaction_repository.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/features/transaction/data/transaction_model.dart';

class FilterTransactionsUseCase {
  List<TransactionModel> execute({
    required List<TransactionModel> transactions,
    TransactionType? type,
    List<String> categoryIds = const [],
    DateTime? startDate,
    DateTime? endDate,
    DateTime? selectedMonth,
    String? searchQuery,
  }) {
    return transactions.where((t) {
      // 1. Type Filter
      if (type != null && t.type != type) {
        return false;
      }

      // 2. Category Filter
      if (categoryIds.isNotEmpty && !categoryIds.contains(t.categoryId)) {
        return false;
      }

      // 3. Date Range Filter
      if (startDate != null && t.date.isBefore(startDate)) {
        return false;
      }
      if (endDate != null && t.date.isAfter(endDate.add(const Duration(days: 1)))) {
        return false;
      }

      // 4. Monthly Filter
      if (startDate == null && endDate == null && selectedMonth != null) {
        if (t.date.year != selectedMonth.year || t.date.month != selectedMonth.month) {
          return false;
        }
      }

      // 5. Search Query Filter
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final titleMatch = t.title?.toLowerCase().contains(query) ?? false;
        final noteMatch = t.note?.toLowerCase().contains(query) ?? false;
        if (!titleMatch && !noteMatch) {
          return false;
        }
      }

      return true;
    }).toList();
  }
}

class GroupTransactionsByDateUseCase {
  Map<DateTime, List<TransactionModel>> execute(List<TransactionModel> transactions) {
    final Map<DateTime, List<TransactionModel>> grouped = {};
    for (var tx in transactions) {
      final date = DateTime(tx.date.year, tx.date.month, tx.date.day);
      grouped.putIfAbsent(date, () => []).add(tx);
    }
    return grouped;
  }
}

class CalculateMonthlyTotalsUseCase {
  Map<TransactionType, int> execute(List<TransactionModel> transactions) {
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
  }
}
