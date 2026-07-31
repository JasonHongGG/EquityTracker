import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/category/domain/i_category_repository.dart';
import 'package:equity_tracker/features/transaction/domain/i_transaction_repository.dart';
import 'package:equity_tracker/features/category/data/category_repository_impl.dart';
import 'package:equity_tracker/features/category/data/category_local_data_source.dart';
import 'package:equity_tracker/features/transaction/data/transaction_local_data_source.dart';
import 'package:equity_tracker/features/transaction/data/transaction_repository_impl.dart';
import 'package:equity_tracker/features/settings/domain/i_settings_repository.dart';
import 'package:equity_tracker/features/settings/data/settings_repository_impl.dart';
import 'package:equity_tracker/features/settings/data/notion_api_client.dart';
import 'package:equity_tracker/features/settings/domain/import_data_usecase.dart';

final categoryLocalDataSourceProvider = Provider<ICategoryLocalDataSource>((ref) {
  return CategoryLocalDataSourceImpl();
});

final transactionLocalDataSourceProvider = Provider<ITransactionLocalDataSource>((ref) {
  return TransactionLocalDataSourceImpl();
});

final notionApiClientProvider = Provider<NotionApiClient>((ref) {
  return NotionApiClient();
});

final categoryRepositoryProvider = Provider<ICategoryRepository>((ref) {
  final dataSource = ref.watch(categoryLocalDataSourceProvider);
  return CategoryRepositoryImpl(dataSource);
});

final transactionRepositoryProvider = Provider<ITransactionRepository>((ref) {
  final dataSource = ref.watch(transactionLocalDataSourceProvider);
  return TransactionRepositoryImpl(dataSource);
});

final settingsRepositoryProvider = Provider<ISettingsRepository>((ref) {
  return SettingsRepositoryImpl();
});

final importDataUseCaseProvider = Provider<ImportDataUseCase>((ref) {
  return ImportDataUseCase(
    ref.watch(transactionRepositoryProvider),
    ref.watch(categoryRepositoryProvider),
  );
});
