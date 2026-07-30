import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/screens/splash_screen.dart';
import 'package:equity_tracker/core/screens/home_screen.dart';
import 'package:equity_tracker/features/settings/presentation/screens/settings_screen.dart';
import 'package:equity_tracker/features/transaction/presentation/screens/add_edit_transaction_screen.dart';
import 'package:equity_tracker/features/transaction/presentation/screens/recurring_transactions_screen.dart';
import 'package:equity_tracker/features/transaction/presentation/screens/add_edit_recurring_transaction_screen.dart';
import 'package:equity_tracker/features/category/presentation/screens/category_management_screen.dart';
import 'package:equity_tracker/features/category/presentation/screens/add_category_screen.dart';
import 'package:equity_tracker/features/transaction/domain/transaction_entity.dart';
import 'package:equity_tracker/features/category/domain/category_entity.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/features/transaction/domain/recurring_transaction_entity.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/add-transaction',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final transaction = extra?['transaction'] as TransactionEntity?;
          final initialDate = extra?['initialDate'] as DateTime?;
          return AddEditTransactionScreen(
            transaction: transaction,
            initialDate: initialDate,
          );
        },
      ),
      GoRoute(
        path: '/recurring-transactions',
        builder: (context, state) => const RecurringTransactionEntitysScreen(),
      ),
      GoRoute(
        path: '/add-recurring-transaction',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final transaction = extra?['transaction'] as RecurringTransactionEntity?;
          return AddEditRecurringTransactionEntityScreen(
            transaction: transaction,
          );
        },
      ),
      GoRoute(
        path: '/manage-categories',
        builder: (context, state) => const CategoryManagementScreen(),
      ),
      GoRoute(
        path: '/add-category',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final categoryToEdit = extra?['categoryToEdit'] as CategoryEntity?;
          final initialType = extra?['initialType'] as TransactionType?;
          return AddCategoryScreen(
            categoryToEdit: categoryToEdit,
            initialType: initialType,
          );
        },
      ),
    ],
  );
});
