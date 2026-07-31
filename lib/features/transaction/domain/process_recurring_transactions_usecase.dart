import 'package:flutter/material.dart';
import 'package:equity_tracker/features/transaction/domain/i_transaction_repository.dart';
import 'package:equity_tracker/features/transaction/domain/transaction_entity.dart';
import 'package:equity_tracker/core/enums/frequency.dart';

class ProcessRecurringTransactionsUseCase {
  final ITransactionRepository _repository;

  ProcessRecurringTransactionsUseCase(this._repository);

  Future<bool> execute() async {
    bool generatedAny = false;
    final recurringList = await _repository.getEnabledRecurringTransactions();
    final now = DateTime.now();

    for (var recurring in recurringList) {
      DateTime nextDue = recurring.nextDueDate;
      final int hour = nextDue.hour;
      final int minute = nextDue.minute;
      int iterations = 0;

      while ((nextDue.isBefore(now) || nextDue.isAtSameMomentAs(now)) && iterations < 50) {
        generatedAny = true;
        iterations++;

        final newTransaction = TransactionEntity(
          title: recurring.title,
          type: recurring.type,
          amount: recurring.amount,
          categoryId: recurring.categoryId,
          date: nextDue,
          createdAt: DateTime.now(),
          note: 'Auto-generated: ${recurring.note ?? recurring.frequency.label}',
        );

        await _repository.insertTransaction(newTransaction);
        DateTime lastGenerated = nextDue;

        switch (recurring.frequency) {
          case Frequency.daily:
            nextDue = nextDue.add(const Duration(days: 1));
            break;
          case Frequency.weekly:
            nextDue = nextDue.add(const Duration(days: 7));
            break;
          case Frequency.monthly:
            var newMonth = nextDue.month + 1;
            var newYear = nextDue.year;
            if (newMonth > 12) {
              newMonth = 1;
              newYear++;
            }
            int targetDay = nextDue.day;
            int daysInNewMonth = DateUtils.getDaysInMonth(newYear, newMonth);
            int actualDay = targetDay > daysInNewMonth ? daysInNewMonth : targetDay;
            nextDue = DateTime(newYear, newMonth, actualDay, hour, minute);
            break;
          case Frequency.yearly:
            var newYear = nextDue.year + 1;
            int targetDay = nextDue.day;
            int daysInNewMonth = DateUtils.getDaysInMonth(newYear, nextDue.month);
            int actualDay = targetDay > daysInNewMonth ? daysInNewMonth : targetDay;
            nextDue = DateTime(newYear, nextDue.month, actualDay, hour, minute);
            break;
        }

        await _repository.updateRecurringTransaction(
          recurring.copyWith(
            lastGeneratedDate: lastGenerated,
            nextDueDate: nextDue,
          ),
        );
      }
    }

    return generatedAny;
  }
}
