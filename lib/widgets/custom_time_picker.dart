import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<TimeOfDay?> showCustomTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) {
  return showDialog<TimeOfDay>(
    context: context,
    builder: (context) => CustomTimePicker(initialTime: initialTime),
  );
}

class CustomTimePicker extends StatefulWidget {
  final TimeOfDay initialTime;

  const CustomTimePicker({super.key, required this.initialTime});

  @override
  State<CustomTimePicker> createState() => _CustomTimePickerState();
}

class _CustomTimePickerState extends State<CustomTimePicker> {
  late int _selectedHour;
  late int _selectedMinute;
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  final double itemHeight = 50.0;

  @override
  void initState() {
    super.initState();
    _selectedHour = widget.initialTime.hour;
    _selectedMinute = widget.initialTime.minute;
    _hourController = FixedExtentScrollController(initialItem: _selectedHour);
    _minuteController = FixedExtentScrollController(
      initialItem: _selectedMinute,
    );
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
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
              "Select Time",
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
                      // Hour Wheel
                      Expanded(
                        child: _buildWheel(
                          controller: _hourController,
                          itemCount: 24,
                          onChanged: (index) =>
                              setState(() => _selectedHour = index),
                          builder: (context, index) {
                            final isSelected = index == _selectedHour;
                            return Center(
                              child: Text(
                                index.toString().padLeft(2, '0'),
                                style: TextStyle(
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
                      // Separator
                      Text(
                        ":",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      // Minute Wheel
                      Expanded(
                        child: _buildWheel(
                          controller: _minuteController,
                          itemCount: 60,
                          onChanged: (index) =>
                              setState(() => _selectedMinute = index),
                          builder: (context, index) {
                            final isSelected = index == _selectedMinute;
                            return Center(
                              child: Text(
                                index.toString().padLeft(2, '0'),
                                style: TextStyle(
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
                      HapticFeedback.mediumImpact();
                      Navigator.pop(
                        context,
                        TimeOfDay(hour: _selectedHour, minute: _selectedMinute),
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
