import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:equity_tracker/features/stats/domain/category_stat_entity.dart';

class CategoryPieChart extends StatefulWidget {
  final List<CategoryStatEntity> stats;
  final int totalAmount;

  const CategoryPieChart({
    super.key,
    required this.stats,
    required this.totalAmount,
  });

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.stats.isEmpty) {
      return const Center(child: Text('No data'));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Sort data: largest first (usually already sorted by UseCase)
    final sortedData = List<CategoryStatEntity>.from(widget.stats)
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    final sections = <PieChartSectionData>[];

    for (int i = 0; i < sortedData.length; i++) {
      final stat = sortedData[i];
      final isTouched = i == _touchedIndex;
      final fontSize = isTouched ? 16.0 : 12.0;
      final radius = isTouched ? 60.0 : 50.0;
      final percentage = (stat.percentage * 100);

      sections.add(
        PieChartSectionData(
          color: stat.category.color,
          value: stat.totalAmount.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            sections: sections,
            sectionsSpace: 2,
            centerSpaceRadius: 50,
            pieTouchData: PieTouchData(
              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                setState(() {
                  if (!event.isInterestedForInteractions ||
                      pieTouchResponse == null ||
                      pieTouchResponse.touchedSection == null) {
                    _touchedIndex = -1;
                    return;
                  }
                  _touchedIndex =
                      pieTouchResponse.touchedSection!.touchedSectionIndex;
                });
              },
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Total',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey : Colors.black54,
              ),
            ),
            Text(
              '\$${widget.totalAmount}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
