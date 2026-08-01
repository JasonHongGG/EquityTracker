import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionDateSelector extends StatelessWidget {
  final DateTime date;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;
  final VoidCallback onPickDate;

  const TransactionDateSelector({
    super.key,
    required this.date,
    required this.onPreviousDay,
    required this.onNextDay,
    required this.onPickDate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txtColor = isDark ? Colors.white : Colors.black;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : Colors.grey[100],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_left_rounded, size: 28),
            color: Colors.grey,
            padding: EdgeInsets.zero,
            onPressed: onPreviousDay,
          ),
          GestureDetector(
            onTap: onPickDate,
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: txtColor,
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('yyyy/MM/dd EEEE').format(date),
                  style: TextStyle(
                    color: txtColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_right_rounded, size: 28),
            color: Colors.grey,
            padding: EdgeInsets.zero,
            onPressed: onNextDay,
          ),
        ],
      ),
    );
  }
}
