import 'package:flutter/material.dart';
import 'package:equity_tracker/features/category/data/category_model.dart';
import 'package:equity_tracker/core/utils/currency_formatter.dart';

class CategoryProgressItem extends StatelessWidget {
  final CategoryModel category;
  final int amount;
  final double percent;
  final VoidCallback onTap;
  final String currencySymbol;

  const CategoryProgressItem({
    super.key,
    required this.category,
    required this.amount,
    required this.percent,
    required this.onTap,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: category.color.withValues(alpha: 0.2),
        child: Icon(category.iconData, color: category.color, size: 20),
      ),
      title: Text(category.name),
      subtitle: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: percent),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.grey.withValues(alpha: 0.1),
            color: category.color,
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          );
        },
      ),
      trailing: Text(
        CurrencyFormatter.format(amount, currencySymbol),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
    );
  }
}
