import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/features/category/providers/category_notifier.dart';
import 'package:equity_tracker/features/category/screens/category_management_screen/category_type_toggle.dart';
import 'package:equity_tracker/features/category/screens/category_management_screen/category_reorderable_grid.dart';

class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  ConsumerState<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState
    extends ConsumerState<CategoryManagementScreen> {
  TransactionType _selectedType = TransactionType.expense;
  bool _isEditMode = false;

  @override
  Widget build(BuildContext context) {
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
            onPressed: () {
              setState(() {
                _isEditMode = !_isEditMode;
              });
            },
            icon: Icon(
              _isEditMode ? Icons.check : Icons.edit,
              color: theme.primaryColor,
            ),
            tooltip: _isEditMode ? 'Done' : 'Edit',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          CategoryTypeToggle(
            selectedType: _selectedType,
            onChanged: (type) {
              setState(() {
                _selectedType = type;
              });
            },
          ),
          Expanded(
            child: categoriesAsync.when(
              data: (categories) {
                final filteredCats = categories
                    .where((c) => c.type == _selectedType)
                    .toList();

                return CategoryReorderableGrid(
                  categories: filteredCats,
                  type: _selectedType,
                  isEditMode: _isEditMode,
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
