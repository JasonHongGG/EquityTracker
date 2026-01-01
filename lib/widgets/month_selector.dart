import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// import '../theme/app_colors.dart'; removed

class MonthSelector extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback? onTitleTap;

  const MonthSelector({
    super.key,
    required this.selectedDate,
    required this.onPrevious,
    required this.onNext,
    this.onTitleTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: onPrevious,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              Icons.chevron_left,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: onTitleTap,
            child: Text(
              DateFormat('MMMM yyyy').format(selectedDate),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: onNext,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              Icons.chevron_right,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
