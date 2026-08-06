import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:equity_tracker/core/theme/app_colors.dart';
import 'package:equity_tracker/features/transaction/providers/recurring_transaction_notifier.dart';
import 'package:equity_tracker/features/transaction/screens/add_edit_recurring_transaction/add_edit_recurring_transaction_screen.dart';
import 'package:equity_tracker/features/settings/screens/settings_screen.dart';
import 'package:equity_tracker/features/transaction/screens/recurring_transactions/recurring_transaction_empty_state.dart';
import 'package:equity_tracker/features/transaction/screens/recurring_transactions/recurring_transaction_item.dart';

class RecurringTransactionModelsScreen extends ConsumerStatefulWidget {
  const RecurringTransactionModelsScreen({super.key});

  @override
  ConsumerState<RecurringTransactionModelsScreen> createState() =>
      _RecurringTransactionModelsScreenState();
}

class _RecurringTransactionModelsScreenState
    extends ConsumerState<RecurringTransactionModelsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recurringTransactionListProvider.notifier).checkAndProcess();
    });
  }

  @override
  Widget build(BuildContext context) {
    final recurringListAsync = ref.watch(recurringTransactionListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // AppBar Style Header with Settings logic preserved
          SliverAppBar(
            pinned: true,
            backgroundColor: isDark
                ? AppColors.backgroundDark
                : AppColors.backgroundLight,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.settings_outlined,
                color: isDark ? Colors.white70 : Colors.black54,
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
            title: Text(
              'Recurring',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
            ),
            centerTitle: true,
            actions: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.add, color: Theme.of(context).primaryColor, size: 28),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const AddEditRecurringTransactionModelScreen(),
                        ),
                      );
                    },
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ],
          ),

          // List Content
          recurringListAsync.when(
            data: (transactions) {
              if (transactions.isEmpty) {
                return const RecurringTransactionEmptyState();
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final transaction = transactions[index];
                    return RecurringTransactionItem(transaction: transaction);
                  }, childCount: transactions.length),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, s) =>
                SliverFillRemaining(child: Center(child: Text('Error: \$e'))),
          ),
        ],
      ),
    );
  }
}
