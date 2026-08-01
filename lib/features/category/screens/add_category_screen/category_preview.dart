import 'package:flutter/material.dart';

class CategoryPreview extends StatelessWidget {
  final Color color;
  final int iconCode;
  final String? fontFamily;
  final String? fontPackage;

  const CategoryPreview({
    super.key,
    required this.color,
    required this.iconCode,
    this.fontFamily,
    this.fontPackage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        IconData(
          iconCode,
          fontFamily: fontFamily,
          fontPackage: fontPackage,
        ),
        color: Colors.white,
        size: 32,
      ),
    );
  }
}
