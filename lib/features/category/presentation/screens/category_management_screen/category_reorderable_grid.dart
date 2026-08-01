import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';

import 'package:equity_tracker/features/category/presentation/providers/category_notifier.dart';
import 'package:equity_tracker/features/category/presentation/screens/category_management_screen/category_add_button.dart';
import 'package:equity_tracker/features/category/presentation/screens/category_management_screen/category_grid_item.dart';
import 'package:equity_tracker/features/category/data/category_model.dart';

class CategoryReorderableGrid extends ConsumerWidget {
  final List<CategoryModel> categories;
  final TransactionType type;
  final bool isEditMode;

  const CategoryReorderableGrid({
    super.key,
    required this.categories,
    required this.type,
    required this.isEditMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Add button is index 0
    final itemCount = categories.length + 1;

    return ReorderableGridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 0.6,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: itemCount,
      onReorder: (oldIndex, newIndex) {
        if (isEditMode) return; // Disable reorder in Edit Mode

        // Prevent moving the "Add" button (index 0)
        // AND prevent moving items TO index 0
        if (oldIndex == 0 || newIndex == 0) return;

        // Adjust indices for the category list (subtract 1 for Add button)
        final int catOldIndex = oldIndex - 1;
        final int catNewIndex = newIndex - 1;

        if (catOldIndex < 0 || catOldIndex >= categories.length) return;
        if (catNewIndex < 0 || catNewIndex >= categories.length) return;

        // Copy list to allow modification (categories might be unmodifiable)
        final List<CategoryModel> mutableCategories = List.from(categories);
        final item = mutableCategories.removeAt(catOldIndex);
        mutableCategories.insert(catNewIndex, item);

        // Update order field
        for (int i = 0; i < mutableCategories.length; i++) {
          mutableCategories[i] = mutableCategories[i].copyWith(order: i);
        }

        ref.read(categoryListProvider.notifier).updateOrder(mutableCategories);
      },
      dragWidgetBuilder: (index, child) {
        return Material(
          color: Colors.transparent,
          elevation: 0,
          child: Transform.scale(scale: 1.1, child: child),
        );
      },
      itemBuilder: (context, index) {
        if (index == 0) {
          return Container(
            key: const ValueKey('add_button_key'),
            child: CategoryAddButton(isEditMode: isEditMode),
          );
        }

        final category = categories[index - 1];
        return Container(
          key: ValueKey(category.id),
          child: CategoryGridItem(
            category: category,
            isEditMode: isEditMode,
          ),
        );
      },
    );
  }
}
