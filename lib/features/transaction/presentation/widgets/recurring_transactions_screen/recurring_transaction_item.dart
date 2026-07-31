import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:equity_tracker/core/enums/frequency.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/core/theme/app_colors.dart';
import 'package:equity_tracker/features/category/domain/category_entity.dart';
import 'package:equity_tracker/features/category/presentation/providers/category_notifier.dart';
import 'package:equity_tracker/features/transaction/domain/recurring_transaction_entity.dart';
import 'package:equity_tracker/features/transaction/presentation/providers/recurring_transaction_notifier.dart';
import 'package:equity_tracker/features/transaction/presentation/screens/add_edit_recurring_transaction_screen.dart';

class RecurringTransactionItem extends ConsumerWidget {
  final RecurringTransactionEntity transaction;

  const RecurringTransactionItem({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExpense = transaction.type == TransactionType.expense;
    final isDueSoon =
        transaction.nextDueDate.difference(DateTime.now()).inDays <= 3;

    final categoriesAsync = ref.watch(categoryListProvider);
    final category = categoriesAsync.asData?.value.firstWhere(
      (c) => c.id == transaction.categoryId,
      orElse: () => CategoryEntity(
        id: 'unknown',
        name: 'Unknown',
        iconCodePoint: FontAwesomeIcons.question.codePoint,
        colorValue: Colors.grey.toARGB32(),
        type: transaction.type,
        isSystem: false,
        isEnabled: true,
      ),
    );

    return Dismissible(
      key: Key(transaction.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          FontAwesomeIcons.trashCan,
          color: Colors.white,
          size: 20,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Recurring Rule?'),
            content: const Text(
              'This will stop future auto-generations. Past transactions will remain.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        ref
            .read(recurringTransactionListProvider.notifier)
            .deleteRecurringTransaction(transaction.id!);
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEditRecurringTransactionEntityScreen(
                transaction: transaction,
              ),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon Bubble
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: category?.color.withValues(alpha: 0.1) ??
                      Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  category?.iconData ?? FontAwesomeIcons.question,
                  color: category?.color ?? Colors.grey,
                  size: 18,
                ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white10
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            transaction.frequency.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black54,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Next: \${DateFormat('MM/dd').format(transaction.nextDueDate)}",
                          style: TextStyle(
                            fontSize: 12,
                            color: isDueSoon
                                ? Colors.orange
                                : (isDark ? Colors.white38 : Colors.black38),
                            fontWeight: isDueSoon
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "\${isExpense ? '-' : '+'}\$\${transaction.amount}",
                    style: TextStyle(
                      color: isExpense ? AppColors.expense : AppColors.income,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  if (!transaction.isEnabled)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Paused',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white30 : Colors.black26,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
