import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/features/category/data/category_model.dart';
import 'package:equity_tracker/features/category/providers/category_notifier.dart';

class AddCategoryState {
  final TransactionType type;
  final String name;
  final int iconCodePoint;
  final String? iconFontFamily;
  final String? iconFontPackage;
  final Color color;
  final bool isSaving;
  final String? error;

  AddCategoryState({
    required this.type,
    this.name = '',
    this.iconCodePoint = 0xe52d, // Default: FastFood
    this.iconFontFamily = 'MaterialIcons',
    this.iconFontPackage,
    this.color = const Color(0xFFFF9500),
    this.isSaving = false,
    this.error,
  });

  AddCategoryState copyWith({
    TransactionType? type,
    String? name,
    int? iconCodePoint,
    String? iconFontFamily,
    String? iconFontPackage,
    Color? color,
    bool? isSaving,
    String? error,
  }) {
    return AddCategoryState(
      type: type ?? this.type,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      iconFontFamily: iconFontFamily ?? this.iconFontFamily,
      iconFontPackage: iconFontPackage ?? this.iconFontPackage,
      color: color ?? this.color,
      isSaving: isSaving ?? this.isSaving,
      error: error, // Error is cleared if not provided explicitly? Wait, if we pass null it clears. Actually it's better to clear it, but let's just make it nullable.
    );
  }
}

class AddCategoryController extends Notifier<AddCategoryState> {
  CategoryModel? _categoryToEdit;

  @override
  AddCategoryState build() {
    return AddCategoryState(
      type: TransactionType.expense,
    );
  }

  void init(CategoryModel? category, TransactionType? initialType) {
    _categoryToEdit = category;
    if (category != null) {
      state = AddCategoryState(
        type: category.type,
        name: category.name,
        iconCodePoint: category.iconCodePoint,
        iconFontFamily: category.iconFontFamily,
        iconFontPackage: category.iconFontPackage,
        color: category.color,
      );
    } else {
      state = AddCategoryState(
        type: initialType ?? TransactionType.expense,
      );
    }
  }

  void updateType(TransactionType type) {
    state = state.copyWith(type: type);
  }

  void updateName(String name) {
    state = state.copyWith(name: name);
  }

  void updateColor(Color color) {
    state = state.copyWith(color: color);
  }

  void updateIcon(int codePoint, String? family, String? pkg) {
    state = state.copyWith(
      iconCodePoint: codePoint,
      iconFontFamily: family,
      iconFontPackage: pkg,
    );
  }

  Future<bool> saveCategory(String nameText) async {
    final name = nameText.trim();
    if (name.isEmpty) {
      state = state.copyWith(error: 'Please enter a category name');
      return false;
    }

    state = state.copyWith(isSaving: true, error: null);

    final id = _categoryToEdit?.id ?? const Uuid().v4();

    final category = CategoryModel(
      id: id,
      name: name,
      iconCodePoint: state.iconCodePoint,
      iconFontFamily: state.iconFontFamily,
      iconFontPackage: state.iconFontPackage,
      colorValue: state.color.value,
      type: state.type,
      isSystem: _categoryToEdit?.isSystem ?? false,
      isEnabled: true,
    );

    try {
      if (_categoryToEdit != null) {
        await ref.read(categoryListProvider.notifier).updateCategoryModel(category);
      } else {
        await ref.read(categoryListProvider.notifier).addCategoryModel(category);
      }
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }
}

final addCategoryControllerProvider = NotifierProvider<AddCategoryController, AddCategoryState>(
  AddCategoryController.new,
);
