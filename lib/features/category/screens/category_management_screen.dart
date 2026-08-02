import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/category/providers/category_notifier.dart';
import 'package:equity_tracker/features/category/screens/category_management_screen/category_type_toggle.dart';
import 'package:equity_tracker/features/category/screens/category_management_screen/category_reorderable_grid.dart';
import 'package:equity_tracker/features/category/controllers/category_management_controller.dart';

class CategoryManagementScreen extends ConsumerWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(categoryManagementControllerProvider);
    final controller = ref.read(categoryManagementControllerProvider.notifier);
    
    final categoriesAsync = ref.watch(categoryListProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F111A)
          : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Manage Categories',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: controller.toggleEditMode,
            icon: Icon(
              state.isEditMode ? Icons.check : Icons.edit,
              color: theme.primaryColor,
            ),
            tooltip: state.isEditMode ? 'Done' : 'Edit',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          CategoryTypeToggle(
            selectedType: state.selectedType,
            onChanged: controller.updateType,
          ),
          Expanded(
            child: categoriesAsync.when(
              data: (categories) {
                final filteredCats = categories
                    .where((c) => c.type == state.selectedType)
                    .toList();

                return CategoryReorderableGrid(
                  categories: filteredCats,
                  type: state.selectedType,
                  isEditMode: state.isEditMode,
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: \$e')),
            ),
          ),
        ],
      ),
    );
  }
}
