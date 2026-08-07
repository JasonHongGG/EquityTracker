import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class RecurringTransactionEmptyState extends StatelessWidget {
  const RecurringTransactionEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 100.0, bottom: 100.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                FontAwesomeIcons.repeat,
                size: 64,
                color: isDark ? Colors.white10 : Colors.black12,
              ),
              const SizedBox(height: 16),
              Text(
                'No recurring transactions',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: isDark ? Colors.white30 : Colors.black26,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap + to add one',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: isDark ? Colors.white30 : Colors.black26,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
