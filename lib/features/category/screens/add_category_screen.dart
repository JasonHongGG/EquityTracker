import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/core/notifications/providers/notification_providers.dart';
import 'package:equity_tracker/features/category/screens/add_category_screen/category_type_selector.dart';
import 'package:equity_tracker/features/category/screens/add_category_screen/category_color_picker.dart';
import 'package:equity_tracker/features/category/screens/add_category_screen/category_icon_picker.dart';
import 'package:equity_tracker/features/category/screens/add_category_screen/category_preview.dart';
import 'package:equity_tracker/features/category/screens/add_category_screen/category_name_input.dart';
import 'package:equity_tracker/features/category/data/category_model.dart';
import 'package:equity_tracker/features/category/controllers/add_category_controller.dart';

class AddCategoryScreen extends ConsumerStatefulWidget {
  final TransactionType? initialType;
  final CategoryModel? categoryToEdit;

  const AddCategoryScreen({super.key, this.initialType, this.categoryToEdit});

  @override
  ConsumerState<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends ConsumerState<AddCategoryScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.categoryToEdit?.name ?? '';
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(addCategoryControllerProvider.notifier).init(widget.categoryToEdit, widget.initialType);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final success = await ref.read(addCategoryControllerProvider.notifier).saveCategory(_nameController.text);
    if (success && mounted) {
      ref.read(inAppNotificationServiceProvider).showSuccess('Category saved');
      Navigator.pop(context);
    } else if (mounted) {
      final error = ref.read(addCategoryControllerProvider).error;
      if (error != null) {
        ref.read(inAppNotificationServiceProvider).showError(error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(addCategoryControllerProvider);
    final controller = ref.read(addCategoryControllerProvider.notifier);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F111A) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.categoryToEdit != null ? 'Edit Category' : 'New Category',
          style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.check_rounded, size: 28),
            tooltip: 'Save Category',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CategoryPreview(
              color: state.color,
              iconCode: state.iconCodePoint,
              fontFamily: state.iconFontFamily,
              fontPackage: state.iconFontPackage,
            ),
            const SizedBox(height: 16),
            
            // 2. Form Container
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: CategoryTypeSelector(
                            selectedType: state.type,
                            onChanged: controller.updateType,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 3,
                          child: CategoryNameInput(controller: _nameController),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  CategoryColorPicker(
                    selectedColor: state.color,
                    onChanged: controller.updateColor,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  CategoryIconPicker(
                    selectedIconCode: state.iconCodePoint,
                    selectedColor: state.color,
                    onChanged: controller.updateIcon,
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
