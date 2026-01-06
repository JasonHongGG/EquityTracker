import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class TrendLineChart extends StatefulWidget {
  final Map<int, double> incomeSpots; // Day -> Amount
  final Map<int, double> expenseSpots; // Day -> Amount
  final int daysInMonth;
  final Function(int day)? onDateSelected;

  const TrendLineChart({
    super.key,
    required this.incomeSpots,
    required this.expenseSpots,
    required this.daysInMonth,
    this.onDateSelected,
  });

  @override
  State<TrendLineChart> createState() => _TrendLineChartState();
}

class _TrendLineChartState extends State<TrendLineChart> {
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 5000, // Dynamic?
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 5, // Show ever 5th day
              getTitlesWidget: (value, meta) {
                final day = value.toInt();
                if (day < 1 || day > widget.daysInMonth)
                  return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    '$day',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 1,
        maxX: widget.daysInMonth.toDouble(),
        minY: 0,
        lineBarsData: [
          // Income Line
          LineChartBarData(
            spots: _generateSpots(widget.incomeSpots),
            isCurved: true,
            color: Colors.tealAccent.shade400,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Colors.tealAccent.shade400.withOpacity(0.2),
                  Colors.tealAccent.shade400.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Expense Line
          LineChartBarData(
            spots: _generateSpots(widget.expenseSpots),
            isCurved: true,
            color: Colors.redAccent.shade200,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Colors.redAccent.shade200.withOpacity(0.2),
                  Colors.redAccent.shade200.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            // tooltipBgColor: isDark ? AppColors.surfaceDark : Colors.white,
            getTooltipColor: (spot) =>
                isDark ? AppColors.surfaceDark : Colors.white,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final isIncome = spot.barIndex == 0;
                return LineTooltipItem(
                  '${isIncome ? '+' : '-'}\$${spot.y.toInt()}',
                  TextStyle(
                    color: isIncome ? Colors.teal : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
          touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
            if (response == null || response.lineBarSpots == null) {
              return;
            }
            if (event is FlTapUpEvent || event is FlPanUpdateEvent) {
              final spot = response.lineBarSpots!.first;
              final day = spot.x.toInt();
              if (touchedIndex != day) {
                setState(() {
                  touchedIndex = day;
                });
                if (widget.onDateSelected != null) {
                  widget.onDateSelected!(day);
                }
              }
            }
          },
          handleBuiltInTouches: true,
        ),
      ),
    );
  }

  List<FlSpot> _generateSpots(Map<int, double> data) {
    // Ensure we have spots for relevant days, or should we skip 0s?
    // Using 0 for days with no data to show the drop/rise
    final List<FlSpot> spots = [];
    for (int i = 1; i <= widget.daysInMonth; i++) {
      spots.add(FlSpot(i.toDouble(), data[i] ?? 0));
    }
    return spots;
  }
}
