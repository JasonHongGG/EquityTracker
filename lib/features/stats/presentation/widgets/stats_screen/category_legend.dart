import 'package:flutter/material.dart';
import 'package:equity_tracker/features/stats/domain/category_stat.dart';

class CategoryLegend extends StatelessWidget {
  final List<CategoryStat> stats;

  const CategoryLegend({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: stats.map((stat) {
        final cat = stat.category;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cat.color,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              cat.name,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
