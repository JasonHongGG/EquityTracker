import 'package:equity_tracker/features/category/domain/category_entity.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';

class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.iconCodePoint,
    super.iconFontFamily,
    super.iconFontPackage,
    required super.colorValue,
    required super.type,
    super.isSystem = false,
    super.isEnabled = true,
    super.order = 0,
  });

  factory CategoryModel.fromEntity(CategoryEntity entity) {
    return CategoryModel(
      id: entity.id,
      name: entity.name,
      iconCodePoint: entity.iconCodePoint,
      iconFontFamily: entity.iconFontFamily,
      iconFontPackage: entity.iconFontPackage,
      colorValue: entity.colorValue,
      type: entity.type,
      isSystem: entity.isSystem,
      isEnabled: entity.isEnabled,
      order: entity.order,
    );
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'],
      name: map['name'],
      iconCodePoint: map['iconCodePoint'],
      iconFontFamily: map['iconFontFamily'],
      iconFontPackage: map['iconFontPackage'],
      colorValue: map['colorValue'],
      type: TransactionType.values.byName(map['type']),
      isSystem: map['isSystem'] == 1,
      isEnabled: map['isEnabled'] == 1,
      order: map['sortOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': iconCodePoint,
      'iconFontFamily': iconFontFamily,
      'iconFontPackage': iconFontPackage,
      'colorValue': colorValue,
      'type': type.name,
      'isSystem': isSystem ? 1 : 0,
      'isEnabled': isEnabled ? 1 : 0,
      'sortOrder': order,
    };
  }
}
