import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/domain/repositories/i_category_repository.dart';
import 'package:equity_tracker/domain/repositories/i_transaction_repository.dart';
import 'package:equity_tracker/data/repositories/category_repository_impl.dart';
import 'package:equity_tracker/data/repositories/transaction_repository_impl.dart';

final categoryRepositoryProvider = Provider<ICategoryRepository>((ref) {
  return CategoryRepositoryImpl();
});

final transactionRepositoryProvider = Provider<ITransactionRepository>((ref) {
  return TransactionRepositoryImpl();
});
