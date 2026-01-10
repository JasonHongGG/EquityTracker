import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../providers/recurring_transaction_provider.dart';
import '../providers/category_provider.dart';
import '../models/category_model.dart';
import '../models/transaction_type.dart';
import '../theme/app_colors.dart';
import 'add_edit_recurring_transaction_screen.dart';
import 'settings_screen.dart';

class RecurringTransactionsScreen extends ConsumerStatefulWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  ConsumerState<RecurringTransactionsScreen> createState() =>
      _RecurringTransactionsScreenState();
}

class _RecurringTransactionsScreenState
    extends ConsumerState<RecurringTransactionsScreen> {
  @override
  void initState() {
    super.initState();
    // Check for due transactions when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recurringTransactionListProvider.notifier).checkAndProcess();
    });
  }

  @override
  Widget build(BuildContext context) {
    final recurringListAsync = ref.watch(recurringTransactionListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // AppBar Style Header with Settings logic preserved (but centered title)
          SliverAppBar(
            pinned: true,
            toolbarHeight: 65,
            leadingWidth: 65, // allocate space for padding
            backgroundColor: isDark
                ? AppColors.backgroundDark
                : AppColors.backgroundLight,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: IconButton(
                icon: Icon(
                  FontAwesomeIcons.gear,
                  color: isDark ? Colors.white70 : Colors.black54,
                  size: 20,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ),
            title: Text(
              'Recurring',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.add, color: AppColors.primary, size: 28),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const AddEditRecurringTransactionScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
            ],
          ),

          // List Content
          recurringListAsync.when(
            data: (transactions) {
              if (transactions.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          FontAwesomeIcons.repeat,
                          size: 64,
                          color: isDark ? Colors.white10 : Colors.black12,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No recurring transactions',
                          style: TextStyle(
                            color: isDark ? Colors.white30 : Colors.black26,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to add one',
                          style: TextStyle(
                            color: isDark ? Colors.white30 : Colors.black26,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final transaction = transactions[index];
                    final isExpense =
                        transaction.type == TransactionType.expense;
                    final isDueSoon =
                        transaction.nextDueDate
                            .difference(DateTime.now())
                            .inDays <=
                        3;

                    // Fetch category details
                    final categoriesAsync = ref.watch(categoryListProvider);
                    final category = categoriesAsync.asData?.value.firstWhere(
                      (c) => c.id == transaction.categoryId,
                      orElse: () => Category(
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
                              builder: (context) =>
                                  AddEditRecurringTransactionScreen(
                                    transaction: transaction,
                                  ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceDark
                                : Colors.white,
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
                                  color:
                                      category?.color.withValues(alpha: 0.1) ??
                                      Colors.grey.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  category?.iconData ??
                                      FontAwesomeIcons.question,
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
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
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
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            transaction.frequency.label,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? Colors.white70
                                                  : Colors.black54,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Next: ${DateFormat('MM/dd').format(transaction.nextDueDate)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDueSoon
                                                ? Colors.orange
                                                : (isDark
                                                      ? Colors.white38
                                                      : Colors.black38),
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
                                    '${isExpense ? '-' : '+'}\$${transaction.amount}',
                                    style: TextStyle(
                                      color: isExpense
                                          ? AppColors.expense
                                          : AppColors.income,
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
                                          color: isDark
                                              ? Colors.white30
                                              : Colors.black26,
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
                  }, childCount: transactions.length),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, s) =>
                SliverFillRemaining(child: Center(child: Text('Error: $e'))),
          ),
        ],
      ),
    );
  }
}
