import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/category/data/category_repository.dart';
import 'package:equity_tracker/features/transaction/data/transaction_repository.dart';
import 'package:equity_tracker/features/category/data/category_repository_impl.dart';
import 'package:equity_tracker/features/category/data/category_local_data_source.dart';
import 'package:equity_tracker/features/transaction/data/transaction_local_data_source.dart';
import 'package:equity_tracker/features/transaction/data/transaction_repository_impl.dart';
import 'package:equity_tracker/features/settings/data/settings_repository.dart';
import 'package:equity_tracker/features/settings/data/settings_repository_impl.dart';
import 'package:equity_tracker/features/notion_sync/data/notion_api_client.dart';
import 'package:equity_tracker/features/data_management/domain/import_data_usecase.dart';


final notionApiClientProvider = Provider<NotionApiClient>((ref) {
  return NotionApiClient();
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

final importDataUseCaseProvider = Provider<ImportDataUseCase>((ref) {
  return ImportDataUseCase(
    ref.watch(transactionRepositoryProvider),
    ref.watch(categoryRepositoryProvider),
  );
});
