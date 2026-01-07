import 'package:flutter/material.dart';
import 'transaction_type.dart';

class Category {
  final String id;
  final String name;
  final int iconCodePoint;
  final String? iconFontFamily;
  final String? iconFontPackage;
  final int colorValue; // ARGB int
  final TransactionType type;
  final bool isSystem;
  final bool isEnabled;
  final int order; // For drag & drop reordering

  const Category({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    this.iconFontFamily,
    this.iconFontPackage,
    required this.colorValue,
    required this.type,
    required this.isSystem,
    required this.isEnabled,
    this.order = 0,
  });

  IconData get iconData => IconData(
    iconCodePoint,
    fontFamily: iconFontFamily,
    fontPackage: iconFontPackage,
  );

  Color get color => Color(colorValue);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': iconCodePoint,
      'iconFontFamily': iconFontFamily,
      'iconFontPackage': iconFontPackage,
      'colorValue': colorValue,
      'type': type.toJson(),
      'isSystem': isSystem ? 1 : 0,
      'isEnabled': isEnabled ? 1 : 0,
      'sortOrder': order,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      iconCodePoint: map['iconCodePoint'] as int,
      iconFontFamily: map['iconFontFamily'] as String?,
      iconFontPackage: map['iconFontPackage'] as String?,
      colorValue: map['colorValue'] as int,
      type: TransactionType.fromJson(map['type'] as String),
      isSystem: (map['isSystem'] as int) == 1,
      isEnabled: (map['isEnabled'] as int) == 1,
      order: (map['sortOrder'] as int?) ?? 0,
    );
  }

  Category copyWith({
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
    return Category(
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
