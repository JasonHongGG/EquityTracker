import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'transaction_list_screen.dart';
import 'stats_screen.dart';
import 'recurring_transactions_screen.dart';
import 'add_edit_transaction_screen.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/scale_button.dart';
import '../theme/app_colors.dart';

import '../models/recurring_transaction_model.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/recurring_transaction_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    const TransactionListScreen(),
    const StatsScreen(),
    const RecurringTransactionsScreen(),
  ];

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initial check
    Future.microtask(() => _checkRecurringTransactions());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkRecurringTransactions();
    }
  }

  Future<void> _checkRecurringTransactions() async {
    // Check for due recurring transactions.
    await ref.read(recurringTransactionListProvider.notifier).checkAndProcess();

    // Always schedule next trigger based on current list
    // This handling ensures that even if no transaction was generated "now",
    // we still look ahead to schedule the "next" one.
    final listAsync = ref.read(recurringTransactionListProvider);
    if (listAsync.hasValue) {
      _scheduleNextTrigger(listAsync.value!);
    }
  }

  /// Schedules a timer for the next upcoming recurring transaction.
  void _scheduleNextTrigger(List<RecurringTransaction> transactions) {
    _timer?.cancel();

    final enabled = transactions.where((t) => t.isEnabled).toList();
    if (enabled.isEmpty) return;

    // Find the earliest due date
    // Sort by date to find the soonest one
    enabled.sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
    final earliest = enabled.first;

    final now = DateTime.now();
    final difference = earliest.nextDueDate.difference(now);

    if (difference.isNegative) {
      // It's already due (or overdue)
      // Process immediately
      _checkRecurringTransactions();
    } else {
      // Schedule for the future
      // We add 1 second buffer to ensure we are safely past the second mark
      _timer = Timer(difference + const Duration(seconds: 1), () {
        _checkRecurringTransactions();
      });
      print('Scheduled next check in: ${difference.inSeconds} seconds');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Check on tab switch just in case
    _checkRecurringTransactions();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for changes in recurring transactions (e.g. user adds new one)
    // to reschedule the next trigger immediately.
    ref.listen(recurringTransactionListProvider, (previous, next) {
      next.whenData(_scheduleNextTrigger);
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true, // Important for floating nav bar
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.backgroundGradientDark : null,
          color: isDark ? null : AppColors.backgroundLight,
        ),
        child: Stack(
          children: [
            _pages[_selectedIndex],
            // Floating Action Button for Add
            if (_selectedIndex == 0)
              Positioned(
                bottom: 100,
                right: 20,
                child: ScaleButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddEditTransactionScreen(),
                      ),
                    );
                  },
                  child: Container(
                    height: 60,
                    width: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        FontAwesomeIcons.plus,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: CustomBottomNavBar(
                selectedIndex: _selectedIndex,
                onItemTapped: _onItemTapped,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
