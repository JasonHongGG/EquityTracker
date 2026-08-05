import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:equity_tracker/features/transaction/screens/transaction_list/transaction_list_screen.dart';
import 'package:equity_tracker/features/stats/screens/stats_screen.dart';
import 'package:equity_tracker/features/transaction/screens/recurring_transactions/recurring_transactions_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:equity_tracker/features/app/widgets/main_bottom_nav.dart';
import 'package:equity_tracker/core/widgets/scale_button.dart';
import 'package:equity_tracker/core/theme/app_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/transaction/providers/recurring_transaction_notifier.dart';
import 'package:equity_tracker/features/app_update/providers/update_notifier.dart';
import 'package:equity_tracker/features/app_update/widgets/update_dialog_helpers.dart';

import 'package:equity_tracker/core/services/local_notification_service.dart';

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
    const RecurringTransactionModelsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() async {
      await LocalNotificationService().init();
      ref.read(recurringTransactionListProvider.notifier).checkAndProcess();
      _checkUpdate();
    });
  }

  Future<void> _checkUpdate() async {
    // Check update in background, it won't block UI
    await ref.read(updateNotifierProvider.notifier).checkForUpdate();
    if (!mounted) return;
    
    final updateState = ref.read(updateNotifierProvider);
    if (updateState.hasUpdate && updateState.releaseInfo != null) {
      showUpdateDialog(context);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(recurringTransactionListProvider.notifier).checkAndProcess();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    ref.read(recurringTransactionListProvider.notifier).checkAndProcess();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: false, // Prevent the bottom nav bar from jumping up when keyboard appears
      extendBody: true, // Important for floating nav bar
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.backgroundGradientDark : null,
          color: isDark ? null : AppColors.backgroundLight,
        ),
        child: Stack(
          children: [
            _pages[_selectedIndex],
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
