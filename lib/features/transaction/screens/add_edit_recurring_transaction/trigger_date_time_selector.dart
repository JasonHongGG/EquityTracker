import 'package:flutter/material.dart';
import 'package:equity_tracker/core/theme/app_colors.dart';

class TriggerDateTimeSelector extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const TriggerDateTimeSelector({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txtColor = isDark ? Colors.white : Colors.black;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
        decoration: BoxDecoration(
          color: isDark ? Colors.black26 : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 12),
            Icon(
              Icons.access_time_filled_rounded,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: txtColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_drop_down, color: txtColor),
          ],
        ),
      ),
    );
  }
}
