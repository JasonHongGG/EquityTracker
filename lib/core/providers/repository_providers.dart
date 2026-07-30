import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/category/domain/i_category_repository.dart';
import 'package:equity_tracker/features/transaction/domain/i_transaction_repository.dart';
import 'package:equity_tracker/features/category/data/category_repository_impl.dart';
import 'package:equity_tracker/features/transaction/data/transaction_repository_impl.dart';

final categoryRepositoryProvider = Provider<ICategoryRepository>((ref) {
  return CategoryRepositoryImpl();
});

final transactionRepositoryProvider = Provider<ITransactionRepository>((ref) {
  return TransactionRepositoryImpl();
});
