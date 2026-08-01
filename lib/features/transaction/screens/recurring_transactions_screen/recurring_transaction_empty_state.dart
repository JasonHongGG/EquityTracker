import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class RecurringTransactionEmptyState extends StatelessWidget {
  const RecurringTransactionEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FontAwesomeIcons.repeat,
              size: 64,
              color: isDark ? Colors.white10 : Colors.black12,
            ),
            const SizedBox(height: 16),
            Text(
              'No recurring transactions',
              style: TextStyle(
                color: isDark ? Colors.white30 : Colors.black26,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add one',
              style: TextStyle(
                color: isDark ? Colors.white30 : Colors.black26,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
