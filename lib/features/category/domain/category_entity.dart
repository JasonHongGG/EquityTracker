import 'package:flutter/material.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';

class CategoryEntity {
  final String id;
  final String name;
  final int iconCodePoint;
  final String? iconFontFamily;
  final String? iconFontPackage;
  final int colorValue; // ARGB int
  final TransactionType type;
  final bool isSystem;
  final bool isEnabled;
  final int order;

  IconData get iconData => IconData(
    iconCodePoint,
    fontFamily: iconFontFamily,
    fontPackage: iconFontPackage,
  );

  Color get color => Color(colorValue);

  const CategoryEntity({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    this.iconFontFamily,
    this.iconFontPackage,
    required this.colorValue,
    required this.type,
    this.isSystem = false,
    this.isEnabled = true,
    this.order = 0,
  });

  CategoryEntity copyWith({
    String? id,
    String? name,
    int? iconCodePoint,
    String? iconFontFamily,
    String? iconFontPackage,
    int? colorValue,
    TransactionType? type,
    bool? isSystem,
    bool? isEnabled,
    int? order,
  }) {
    return CategoryEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      iconFontFamily: iconFontFamily ?? this.iconFontFamily,
      iconFontPackage: iconFontPackage ?? this.iconFontPackage,
      colorValue: colorValue ?? this.colorValue,
      type: type ?? this.type,
      isSystem: isSystem ?? this.isSystem,
      isEnabled: isEnabled ?? this.isEnabled,
      order: order ?? this.order,
    );
  }
}
