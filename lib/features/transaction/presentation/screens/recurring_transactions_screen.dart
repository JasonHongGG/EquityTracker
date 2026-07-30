import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:equity_tracker/core/theme/app_colors.dart';
import 'package:equity_tracker/features/transaction/presentation/providers/recurring_transaction_notifier.dart';
import 'package:equity_tracker/features/transaction/presentation/screens/add_edit_recurring_transaction_screen.dart';
import 'package:equity_tracker/features/settings/presentation/screens/settings_screen.dart';
import 'package:equity_tracker/features/transaction/presentation/widgets/recurring_transactions_screen/recurring_transaction_empty_state.dart';
import 'package:equity_tracker/features/transaction/presentation/widgets/recurring_transactions_screen/recurring_transaction_item.dart';

class RecurringTransactionEntitysScreen extends ConsumerStatefulWidget {
  const RecurringTransactionEntitysScreen({super.key});

  @override
  ConsumerState<RecurringTransactionEntitysScreen> createState() =>
      _RecurringTransactionEntitysScreenState();
}

class _RecurringTransactionEntitysScreenState
    extends ConsumerState<RecurringTransactionEntitysScreen> {
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
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // AppBar Style Header with Settings logic preserved
          SliverAppBar(
            pinned: true,
            toolbarHeight: 65,
            leadingWidth: 65,
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
                          const AddEditRecurringTransactionEntityScreen(),
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
