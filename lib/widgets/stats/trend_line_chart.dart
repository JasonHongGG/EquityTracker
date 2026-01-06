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

    // Define Colors
    final incomeColor = const Color(0xFF34C759); // iOS Green
    final expenseColor = Colors.redAccent.shade200;

    // 1. Calculate Max Y to determine interval
    double maxY = 0;
    if (widget.incomeSpots.isNotEmpty) {
      final maxIncome = widget.incomeSpots.values.reduce(
        (a, b) => a > b ? a : b,
      );
      if (maxIncome > maxY) maxY = maxIncome;
    }
    if (widget.expenseSpots.isNotEmpty) {
      final maxExpense = widget.expenseSpots.values.reduce(
        (a, b) => a > b ? a : b,
      );
      if (maxExpense > maxY) maxY = maxExpense;
    }

    // Default to at least 1000 if empty or small
    if (maxY < 1000) maxY = 1000;

    // 2. Determine Interval based on maxY
    double interval = 5000;
    if (maxY <= 1000) {
      interval = 200;
      // Ensure we have at least 5 lines
    } else if (maxY <= 3000) {
      interval = 500;
    } else if (maxY <= 6000) {
      interval = 1000;
    } else if (maxY <= 10000) {
      interval = 2500;
    } else {
      interval = 5000;
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: isDark
                  ? Colors.white10
                  : Colors.grey.withValues(alpha: 0.1),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          // Add right titles to balance the chart horizontally
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(
              showTitles: false,
              reservedSize: 24, // Balance the left axis
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 5,
              getTitlesWidget: (value, meta) {
                final day = value.toInt();
                final maxDay = widget.daysInMonth;

                // 1. Basic Range Check
                if (day < 1 || day > maxDay) return const SizedBox.shrink();

                // 2. Show 1 as Origin
                if (day == 1) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '1',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }

                // 3. Strict Interval Check: Hide if not a multiple of 5
                if (day % 5 != 0) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    '$day',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32, // Tightened to shift chart left
              interval: interval,
              getTitlesWidget: (value, meta) {
                // Strict modulus check using calculated interval
                if (value != 0 && value % interval != 0) {
                  return const SizedBox.shrink();
                }

                String text = value.toInt().toString();
                if (value >= 1000) {
                  text = '${(value / 1000).toStringAsFixed(1)}k'.replaceAll(
                    '.0k',
                    'k',
                  );
                }
                return Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      right: 2.0,
                    ), // Reduced spacing
                    child: Text(
                      text,
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                        fontSize: 11, // Slightly larger
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                );
              },
            ),
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
            color: incomeColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  incomeColor.withValues(alpha: 0.2),
                  incomeColor.withValues(alpha: 0.0),
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
            color: expenseColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  expenseColor.withValues(alpha: 0.2),
                  expenseColor.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) =>
                isDark ? AppColors.surfaceDark : Colors.white,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final isIncome = spot.barIndex == 0;
                return LineTooltipItem(
                  '${isIncome ? '+' : '-'}\$${spot.y.toInt()}',
                  TextStyle(
                    color: isIncome ? incomeColor : expenseColor,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
          touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
            if (response == null || response.lineBarSpots == null) {
              // Don't clear selection on drag end instantly?
              // Let's keep it simple
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
