import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<int?> showCustomDayPicker({
  required BuildContext context,
  required int initialDay,
  required int daysInMonth,
}) {
  return showDialog<int>(
    context: context,
    builder: (context) =>
        CustomDayPicker(initialDay: initialDay, daysInMonth: daysInMonth),
  );
}

class CustomDayPicker extends StatefulWidget {
  final int initialDay;
  final int daysInMonth;

  const CustomDayPicker({
    super.key,
    required this.initialDay,
    required this.daysInMonth,
  });

  @override
  State<CustomDayPicker> createState() => _CustomDayPickerState();
}

class _CustomDayPickerState extends State<CustomDayPicker> {
  late int _selectedDay;
  late FixedExtentScrollController _dayController;
  final double itemHeight = 50.0;

  @override
  void initState() {
    super.initState();
    // Ensure initialDay is valid
    _selectedDay = widget.initialDay.clamp(1, widget.daysInMonth);

    _dayController = FixedExtentScrollController(initialItem: _selectedDay - 1);
  }

  @override
  void dispose() {
    _dayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;

    // Premium Colors
    final backgroundColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final secondaryTextColor = isDark ? Colors.white38 : Colors.black38;
    final highlightColor = primaryColor.withOpacity(0.12);

    return Dialog(
      backgroundColor: backgroundColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Text(
              'Select Day',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 24),

            // Picker Area
            SizedBox(
              height: 150,
              child: Stack(
                children: [
                  // Selection Highlight
                  Center(
                    child: Container(
                      height: itemHeight,
                      decoration: BoxDecoration(
                        color: highlightColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  // Day Wheel
                  Center(
                    child: ListWheelScrollView.useDelegate(
                      controller: _dayController,
                      itemExtent: itemHeight,
                      perspective: 0.002,
                      diameterRatio: 1.5,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (index) {
                        setState(() {
                          _selectedDay = index + 1;
                        });
                        HapticFeedback.selectionClick();
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: widget.daysInMonth,
                        builder: (context, index) {
                          final day = index + 1;
                          final isSelected = day == _selectedDay;
                          final dayStr = day.toString().padLeft(2, '0');

                          return Center(
                            child: Text(
                              dayStr,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: isSelected ? 24 : 20,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? textColor
                                    : secondaryTextColor,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Actions
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      foregroundColor: secondaryTextColor.withOpacity(0.6),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(context, _selectedDay);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Confirm',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
