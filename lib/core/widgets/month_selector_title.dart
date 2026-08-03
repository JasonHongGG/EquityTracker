import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonthSelectorTitle extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback? onTitleTap;

  const MonthSelectorTitle({
    super.key,
    required this.selectedDate,
    required this.onPrevious,
    required this.onNext,
    this.onTitleTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: onPrevious,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          visualDensity: VisualDensity.compact,
          icon: Icon(
            Icons.chevron_left,
            color: isDark ? Colors.white70 : Colors.black54,
            size: 24,
          ),
        ),
        const SizedBox(width: 2),
        GestureDetector(
          onTap: onTitleTap,
          child: Text(
            DateFormat('yy / MM').format(selectedDate),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
          ),
        ),
        const SizedBox(width: 2),
        IconButton(
          onPressed: onNext,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          visualDensity: VisualDensity.compact,
          icon: Icon(
            Icons.chevron_right,
            color: isDark ? Colors.white70 : Colors.black54,
            size: 24,
          ),
        ),
      ],
    );
  }
}
