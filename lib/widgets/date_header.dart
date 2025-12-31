import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';

class DateHeader extends StatelessWidget {
  final DateTime date;
  final int totalAmount;

  const DateHeader({super.key, required this.date, required this.totalAmount});

  @override
  Widget build(BuildContext context) {
    Color totalColor = AppColors.textSecondaryDark;
    if (totalAmount > 0) totalColor = AppColors.income;
    if (totalAmount < 0) totalColor = AppColors.expense;

    final dateStr = DateFormat('MM/dd').format(date);
    final weekdayStr = _getWeekdayString(date.weekday);
    final isToday =
        DateTime.now().difference(date).inDays == 0 &&
        DateTime.now().day == date.day;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                isToday ? 'Today' : weekdayStr,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                dateStr,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          Text(
            '\$$totalAmount',
            style: TextStyle(
              color: totalColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  String _getWeekdayString(int weekday) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (weekday >= 1 && weekday <= 7) {
      return weekdays[weekday - 1];
    }
    return '';
  }
}
