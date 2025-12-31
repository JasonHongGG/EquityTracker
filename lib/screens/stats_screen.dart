import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../models/transaction_type.dart';
import '../theme/app_colors.dart';
import '../widgets/gradient_card.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(filteredTransactionsProvider);
    final categoriesAsync = ref.watch(categoryListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Analysis')),
      body: transactionsAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) return const Center(child: Text('No Data'));

          // 1. Calculate Expense by Category
          final Map<String, int> categoryTotals = {};
          int totalExpense = 0;

          for (var t in transactions) {
            if (t.type == TransactionType.expense) {
              categoryTotals[t.categoryId] =
                  (categoryTotals[t.categoryId] ?? 0) + t.amount;
              totalExpense += t.amount;
            }
          }

          // 2. Prepare Pie Chart Data
          final categories = categoriesAsync.asData?.value ?? [];
          final pieSections = <PieChartSectionData>[];

          List<MapEntry<String, int>> sortedEntries =
              categoryTotals.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));

          for (int i = 0; i < sortedEntries.length; i++) {
            final entry = sortedEntries[i];
            final isTouched = i == _touchedIndex;
            final fontSize = isTouched ? 16.0 : 12.0;
            final radius = isTouched ? 60.0 : 50.0;
            final cat = categories.firstWhere(
              (c) => c.id == entry.key,
              orElse: () => categories.first,
            );

            pieSections.add(
              PieChartSectionData(
                color: cat.color,
                value: entry.value.toDouble(),
                title:
                    '${(entry.value / totalExpense * 100).toStringAsFixed(0)}%',
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

          // 3. Daily Net Line Chart
          final Map<DateTime, int> dailyNet = {};
          for (var t in transactions) {
            // Cumulative or daily? Daily net.
            if (t.type == TransactionType.income) {
              dailyNet[t.date] = (dailyNet[t.date] ?? 0) + t.amount;
            } else {
              dailyNet[t.date] = (dailyNet[t.date] ?? 0) - t.amount;
            }
          }
          final sortedDates = dailyNet.keys.toList()..sort();
          final flSpots = <FlSpot>[];
          if (sortedDates.isNotEmpty) {
            // Create smooth curve, simplified
            for (int i = 0; i < sortedDates.length; i++) {
              flSpots.add(
                FlSpot(i.toDouble(), dailyNet[sortedDates[i]]!.toDouble()),
              );
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pie Chart Card
                GradientCard(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  child: Column(
                    children: [
                      const Text(
                        'Expense Structure',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 200,
                        child: totalExpense > 0
                            ? PieChart(
                                PieChartData(
                                  sections: pieSections,
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 40,
                                  pieTouchData: PieTouchData(
                                    touchCallback:
                                        (FlTouchEvent event, pieTouchResponse) {
                                          setState(() {
                                            if (!event
                                                    .isInterestedForInteractions ||
                                                pieTouchResponse == null ||
                                                pieTouchResponse
                                                        .touchedSection ==
                                                    null) {
                                              _touchedIndex = -1;
                                              return;
                                            }
                                            _touchedIndex = pieTouchResponse
                                                .touchedSection!
                                                .touchedSectionIndex;
                                          });
                                        },
                                  ),
                                ),
                              )
                            : const Center(child: Text('No expenses recorded')),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Line Chart Card
                GradientCard(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  child: Column(
                    children: [
                      const Text(
                        'Daily Trend',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 200,
                        child: flSpots.isNotEmpty
                            ? LineChart(
                                LineChartData(
                                  gridData: const FlGridData(show: false),
                                  titlesData: const FlTitlesData(show: false),
                                  borderData: FlBorderData(show: false),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: flSpots,
                                      isCurved: true,
                                      color: AppColors.primary,
                                      barWidth: 4,
                                      isStrokeCapRound: true,
                                      dotData: const FlDotData(show: false),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.primary.withValues(
                                              alpha: 0.3,
                                            ),
                                            AppColors.primary.withValues(
                                              alpha: 0.0,
                                            ),
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
                                          AppColors.surfaceDark,
                                      getTooltipItems: (touchedSpots) {
                                        return touchedSpots.map((spot) {
                                          return LineTooltipItem(
                                            '\$${spot.y.toInt()}',
                                            const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          );
                                        }).toList();
                                      },
                                    ),
                                  ),
                                ),
                              )
                            : const Center(child: Text('No activity data')),
                      ),
                    ],
                  ),
                ),

                // Top Expenses List (Mini)
                const SizedBox(height: 20),
                const Text(
                  'Top Expenses',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                // Just map top 3 categories
                ...sortedEntries.take(3).map((e) {
                  final cat = categories.firstWhere(
                    (c) => c.id == e.key,
                    orElse: () => categories.first,
                  );
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: cat.color.withValues(alpha: 0.2),
                          child: Icon(cat.iconData, color: cat.color, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Text(cat.name),
                        const Spacer(),
                        Text(
                          '\$${e.value}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
