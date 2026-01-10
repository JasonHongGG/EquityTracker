import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

Future<DateTime?> showCustomMonthDayPicker({
  required BuildContext context,
  required DateTime initialDate,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (context) => CustomMonthDayPicker(initialDate: initialDate),
  );
}

class CustomMonthDayPicker extends StatefulWidget {
  final DateTime initialDate;

  const CustomMonthDayPicker({super.key, required this.initialDate});

  @override
  State<CustomMonthDayPicker> createState() => _CustomMonthDayPickerState();
}

class _CustomMonthDayPickerState extends State<CustomMonthDayPicker> {
  late int _selectedMonth;
  late int _selectedDay;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _dayController;

  final double itemHeight = 50.0;

  @override
  void initState() {
    super.initState();
    _selectedMonth = widget.initialDate.month;
    _selectedDay = widget.initialDate.day;

    _monthController = FixedExtentScrollController(
      initialItem: _selectedMonth - 1,
    );
    _dayController = FixedExtentScrollController(initialItem: _selectedDay - 1);
  }

  @override
  void dispose() {
    _monthController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  int _getDaysInMonth(int month) {
    // Leap year check not strictly needed for generic recurrence (often just assume 29 for Feb to allow selection)
    // But to be safe let's assume leap year to allow Feb 29 selection?
    // User wants to pick a date. If they pick Feb 29, it recurs on Feb 29 (or Feb 28 in non-leap).
    // Let's use 2024 (leap year) as dummy year to allow 29 days for Feb.
    return DateUtils.getDaysInMonth(2024, month);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;

    final backgroundColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final secondaryTextColor = isDark ? Colors.white38 : Colors.black38;
    final highlightColor = primaryColor.withOpacity(0.12);

    return Dialog(
      backgroundColor: backgroundColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Date',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 24),
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
                  Row(
                    children: [
                      // Month Wheel
                      Expanded(
                        flex: 4,
                        child: _buildWheel(
                          controller: _monthController,
                          itemCount: 12,
                          onChanged: (index) {
                            setState(() {
                              _selectedMonth = index + 1;
                              // Clamp day if needed (e.g. switch form Jan 31 to Feb -> Feb 29)
                              final maxDays = _getDaysInMonth(_selectedMonth);
                              if (_selectedDay > maxDays) {
                                _selectedDay = maxDays;
                                _dayController.jumpToItem(_selectedDay - 1);
                              }
                            });
                          },
                          builder: (context, index) {
                            final month = index + 1;
                            final isSelected = month == _selectedMonth;
                            // MMM format
                            final monthName = DateFormat(
                              'MMM',
                            ).format(DateTime(2024, month));
                            return Center(
                              child: Text(
                                monthName,
                                style: TextStyle(
                                  fontSize: isSelected ? 20 : 18,
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
                      const SizedBox(width: 8),
                      // Day Wheel
                      Expanded(
                        flex: 3,
                        child: _buildWheel(
                          controller: _dayController,
                          itemCount: 31, // Always show 31? Or dynamic?
                          // Dynamic behavior in ListWheelScrollView is jittery if itemCount changes.
                          // Strategy: Always show 31, but visually dim or auto-snap invalid ones?
                          // Or simply allow 1-31 and handle invalid in confirm.
                          // Actually, let's use the maxDays of CURRENTLY selected month.
                          // Note: setState rebuilds the widget, so itemCount updates.
                          // ListWheelScrollView doesn't animate changes well but it rebuilds.
                          // Let's try dynamic itemCount.
                          onChanged: (index) {
                            setState(() => _selectedDay = index + 1);
                          },
                          builder: (context, index) {
                            // If index >= maxDays, return empty? No, itemCount handles it.
                            final day = index + 1;
                            final isSelected = day == _selectedDay;
                            return Center(
                              child: Text(
                                '$day',
                                style: TextStyle(
                                  fontSize: isSelected ? 20 : 18,
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
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
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
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Validate day just in case
                      final maxDays = _getDaysInMonth(_selectedMonth);
                      var finalDay = _selectedDay;
                      if (finalDay > maxDays) finalDay = maxDays;

                      HapticFeedback.mediumImpact();
                      // Return a DateTime with dummy year 2024 to represent Month/Day
                      Navigator.pop(
                        context,
                        DateTime(2024, _selectedMonth, finalDay),
                      );
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
                      style: TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildWheel({
    required FixedExtentScrollController controller,
    required int itemCount,
    required ValueChanged<int> onChanged,
    required IndexedWidgetBuilder builder,
  }) {
    // For dynamic item count, simple rebuild works but keep an eye on controller bounds
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: itemHeight,
      perspective: 0.002,
      diameterRatio: 1.5,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: (index) {
        onChanged(index);
        HapticFeedback.selectionClick();
      },
      childDelegate: ListWheelChildBuilderDelegate(
        builder: builder,
        childCount: itemCount,
      ),
    );
  }
}
