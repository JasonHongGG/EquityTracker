import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_colors.dart';
import 'custom_day_picker.dart';

class DaySelector extends StatelessWidget {
  final int selectedDay;
  final int daysInMonth;
  final ValueChanged<int> onDayChanged;

  const DaySelector({
    super.key,
    required this.selectedDay,
    required this.daysInMonth,
    required this.onDayChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? Colors.white : AppColors.textPrimaryLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Prev
          _ArrowButton(
            icon: FontAwesomeIcons.chevronLeft,
            onTap: selectedDay > 1 ? () => _updateDay(selectedDay - 1) : null,
            color: color,
          ),

          // Day Text
          GestureDetector(
            onTap: () async {
              final newDay = await showCustomDayPicker(
                context: context,
                initialDay: selectedDay,
                daysInMonth: daysInMonth,
              );
              if (newDay != null) {
                _updateDay(newDay);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.transparent, // Hit test
              child: Text(
                selectedDay.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),

          // Next
          _ArrowButton(
            icon: FontAwesomeIcons.chevronRight,
            onTap: selectedDay < daysInMonth
                ? () => _updateDay(selectedDay + 1)
                : null,
            color: color,
          ),
        ],
      ),
    );
  }

  void _updateDay(int newDay) {
    HapticFeedback.lightImpact();
    onDayChanged(newDay);
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;

  const _ArrowButton({required this.icon, this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          icon,
          size: 12,
          color: onTap != null ? color : color.withOpacity(0.3),
        ),
      ),
    );
  }
}
