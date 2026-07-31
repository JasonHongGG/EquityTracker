import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';

import 'package:equity_tracker/core/providers/repository_providers.dart';
import 'package:equity_tracker/features/category/domain/category_usecases.dart';
import 'package:equity_tracker/features/transaction/presentation/providers/transaction_notifier.dart';
import 'package:equity_tracker/features/category/data/category_model.dart';

// --- UseCase Providers ---
final getCategoriesUseCaseProvider = Provider<GetCategoriesUseCase>((ref) {
  return GetCategoriesUseCase(ref.read(categoryRepositoryProvider));
});

final addCategoryUseCaseProvider = Provider<AddCategoryUseCase>((ref) {
  return AddCategoryUseCase(ref.read(categoryRepositoryProvider));
});

final updateCategoryUseCaseProvider = Provider<UpdateCategoryUseCase>((ref) {
  return UpdateCategoryUseCase(ref.read(categoryRepositoryProvider));
});

final reorderCategoriesUseCaseProvider = Provider<ReorderCategoriesUseCase>((ref) {
  return ReorderCategoriesUseCase(ref.read(categoryRepositoryProvider));
});

final deleteCategoryUseCaseProvider = Provider<DeleteCategoryUseCase>((ref) {
  return DeleteCategoryUseCase(
    ref.read(categoryRepositoryProvider),
    ref.read(transactionRepositoryProvider),
  );
});

// --- UI Notifier ---
class CategoryList extends AsyncNotifier<List<CategoryModel>> {
  @override
  Future<List<CategoryModel>> build() async {
    return _fetchCategories();
  }

  Future<List<CategoryModel>> _fetchCategories() async {
    return await ref.read(getCategoriesUseCaseProvider).execute();
  }

  Future<void> addCategoryModel(CategoryModel category) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(addCategoryUseCaseProvider).execute(category);
      return _fetchCategories();
    });
  }

  Future<void> updateCategoryModel(CategoryModel category) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(updateCategoryUseCaseProvider).execute(category);
      return _fetchCategories();
    });
  }

  Future<void> deleteCategoryModel(String id, TransactionType type) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // Execute cross-domain business logic purely in UseCase layer
      await ref.read(deleteCategoryUseCaseProvider).execute(id, type);
      
      // Invalidate transaction provider so UI refreshes with new assignments
      ref.invalidate(transactionListProvider);
      
      return _fetchCategories();
    });
  }

  Future<void> updateOrder(List<CategoryModel> categories) async {
    state = AsyncValue.data(categories);
    await ref.read(reorderCategoriesUseCaseProvider).execute(categories);
  }
}

final categoryListProvider =
    AsyncNotifierProvider<CategoryList, List<CategoryModel>>(CategoryList.new);
