import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/features/category/presentation/providers/category_notifier.dart';
import 'package:equity_tracker/core/widgets/toast_notification.dart';
import 'package:equity_tracker/features/category/presentation/widgets/add_category_screen/category_type_selector.dart';
import 'package:equity_tracker/features/category/presentation/widgets/add_category_screen/category_color_picker.dart';
import 'package:equity_tracker/features/category/presentation/widgets/add_category_screen/category_icon_picker.dart';
import 'package:equity_tracker/features/category/presentation/widgets/add_category_screen/category_preview.dart';
import 'package:equity_tracker/features/category/presentation/widgets/add_category_screen/category_name_input.dart';
import 'package:equity_tracker/features/category/data/category_model.dart';

class AddCategoryScreen extends ConsumerStatefulWidget {
  final TransactionType? initialType;
  final CategoryModel? categoryToEdit;

  const AddCategoryScreen({super.key, this.initialType, this.categoryToEdit});

  @override
  ConsumerState<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends ConsumerState<AddCategoryScreen> {
  late TransactionType _selectedType;
  final TextEditingController _nameController = TextEditingController();

  int _selectedIconCode = 0xe52d; // Default: FastFood
  String? _selectedFontFamily = 'MaterialIcons';
  String? _selectedFontPackage;
  Color _selectedColor = const Color(0xFFFF9500); // Default Orange

  @override
  void initState() {
    super.initState();
    if (widget.categoryToEdit != null) {
      final c = widget.categoryToEdit!;
      _selectedType = c.type;
      _nameController.text = c.name;
      _selectedIconCode = c.iconCodePoint;
      _selectedFontFamily = c.iconFontFamily;
      _selectedFontPackage = c.iconFontPackage;
      _selectedColor = c.color;
    } else {
      _selectedType = widget.initialType ?? TransactionType.expense;
    }
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ToastService.showError(context, 'Please enter a category name');
      return;
    }

    final id = widget.categoryToEdit?.id ?? const Uuid().v4();

    final category = CategoryModel(
      id: id,
      name: name,
      iconCodePoint: _selectedIconCode,
      iconFontFamily: _selectedFontFamily,
      iconFontPackage: _selectedFontPackage,
      colorValue: _selectedColor.value,
      type: _selectedType,
      isSystem: widget.categoryToEdit?.isSystem ?? false,
      isEnabled: true,
    );

    if (widget.categoryToEdit != null) {
      ref.read(categoryListProvider.notifier).updateCategoryModel(category);
    } else {
      ref.read(categoryListProvider.notifier).addCategoryModel(category);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
              color: _selectedColor,
              iconCode: _selectedIconCode,
              fontFamily: _selectedFontFamily,
              fontPackage: _selectedFontPackage,
            ),
            const SizedBox(height: 16),
            
            // 2. Form Container
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
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
                            selectedType: _selectedType,
                            onChanged: (type) => setState(() => _selectedType = type),
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
                    selectedColor: _selectedColor,
                    onChanged: (color) => setState(() => _selectedColor = color),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  CategoryIconPicker(
                    selectedIconCode: _selectedIconCode,
                    selectedColor: _selectedColor,
                    onChanged: (codePoint, family, pkg) => setState(() {
                      _selectedIconCode = codePoint;
                      _selectedFontFamily = family;
                      _selectedFontPackage = pkg;
                    }),
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
