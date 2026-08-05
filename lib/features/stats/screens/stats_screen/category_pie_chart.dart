import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:equity_tracker/features/stats/domain/category_stat.dart';
import 'package:equity_tracker/core/utils/currency_formatter.dart';

class CategoryPieChart extends StatefulWidget {
  final List<CategoryStat> stats;
  final int totalAmount;
  final String currencySymbol;

  const CategoryPieChart({
    super.key,
    required this.stats,
    required this.totalAmount,
    required this.currencySymbol,
  });

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Sort data: largest first (usually already sorted by UseCase)
    final sortedData = List<CategoryStat>.from(widget.stats)
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    final sections = <PieChartSectionData>[];

    if (sortedData.isEmpty) {
      sections.add(
        PieChartSectionData(
          color: isDark ? Colors.grey.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2),
          value: 1,
          title: '',
          radius: 45.0,
        ),
      );
    } else {
      for (int i = 0; i < sortedData.length; i++) {
        final stat = sortedData[i];
        final isTouched = i == _touchedIndex;
        final radius = isTouched ? 55.0 : 45.0; // Slightly smaller to look cleaner

        sections.add(
          PieChartSectionData(
            color: stat.category.color,
            value: stat.totalAmount.toDouble(),
            title: '', // CLEAN DONUT: No messy text on slices!
            radius: radius,
          ),
        );
      }
    }

    // Determine what to show in the center
    Widget centerWidget;
    if (_touchedIndex == -1 || _touchedIndex >= sortedData.length) {
      // Default State: Show Total
      centerWidget = Column(
        key: const ValueKey('total'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Total',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey : Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(widget.totalAmount, widget.currencySymbol),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      );
    } else {
      // Touched State: Show Category Info
      final touchedStat = sortedData[_touchedIndex];
      final percentage = touchedStat.percentage * 100;
      
      centerWidget = Column(
        key: ValueKey('touched_$_touchedIndex'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: touchedStat.category.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  touchedStat.category.name,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(touchedStat.totalAmount, widget.currencySymbol),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 13,
              color: touchedStat.category.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            sections: sections,
            sectionsSpace: 1.5, // Tighter space for elegance
            centerSpaceRadius: 65, // Larger center hole
            pieTouchData: PieTouchData(
              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                setState(() {
                  if (!event.isInterestedForInteractions ||
                      pieTouchResponse == null ||
                      pieTouchResponse.touchedSection == null) {
                    _touchedIndex = -1;
                    return;
                  }
                  _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                });
              },
            ),
          ),
        ),
        // Interactive Center with fade animation
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeIn,
          switchOutCurve: Curves.easeOut,
          child: centerWidget,
        ),
      ],
    );
  }
}
