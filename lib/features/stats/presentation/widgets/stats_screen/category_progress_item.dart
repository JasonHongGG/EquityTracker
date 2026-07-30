import 'package:flutter/material.dart';
import 'package:equity_tracker/features/category/domain/category_entity.dart';

class CategoryProgressItem extends StatelessWidget {
  final CategoryEntity category;
  final int amount;
  final double percent;
  final VoidCallback onTap;

  const CategoryProgressItem({
    super.key,
    required this.category,
    required this.amount,
    required this.percent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: category.color.withValues(alpha: 0.2),
        child: Icon(category.iconData, color: category.color, size: 20),
      ),
      title: Text(category.name),
      subtitle: LinearProgressIndicator(
        value: percent,
        backgroundColor: Colors.grey.withValues(alpha: 0.1),
        color: category.color,
        minHeight: 4,
        borderRadius: BorderRadius.circular(2),
      ),
      trailing: Text(
        '\$$amount',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
    );
  }
}
