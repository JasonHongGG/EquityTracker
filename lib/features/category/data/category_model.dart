
import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/features/category/data/category_model.dart';

import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final int iconCodePoint;
  final String? iconFontFamily;
  final String? iconFontPackage;
  final int colorValue;
  final TransactionType type;
  final bool isSystem;
  final bool isEnabled;
  final int order;

  const CategoryModel({
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
  Color get color => Color(colorValue);
  
  IconData get iconData => IconData(
        iconCodePoint,
        fontFamily: iconFontFamily,
        fontPackage: iconFontPackage,
      );
}
