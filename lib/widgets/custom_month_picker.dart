import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<DateTime?> showCustomMonthPicker({
  required BuildContext context,
  required DateTime initialDate,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (context) => CustomMonthPicker(initialDate: initialDate),
  );
}

class CustomMonthPicker extends StatefulWidget {
  final DateTime initialDate;

  const CustomMonthPicker({super.key, required this.initialDate});

  @override
  State<CustomMonthPicker> createState() => _CustomMonthPickerState();
}

class _CustomMonthPickerState extends State<CustomMonthPicker> {
  late int _selectedYear;
  late int _selectedMonth;
  late FixedExtentScrollController _yearController;
  late FixedExtentScrollController _monthController;

  // Configuration
  final int minYear = 2000;
  final int maxYear = 2050;
  final double itemHeight = 50.0;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;
    _selectedMonth = widget.initialDate.month;

    _yearController = FixedExtentScrollController(
      initialItem: _selectedYear - minYear,
    );
    _monthController = FixedExtentScrollController(
      initialItem: _selectedMonth - 1,
    );
  }

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
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
      surfaceTintColor: Colors.transparent, // Remove M3 pink tint
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        width: 340, // Fixed width for consistent look
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Text(
              'Select Date',
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
              height: 150, // 3 items visible (50px each)
              child: Stack(
                children: [
                  // Selection Highlight (The "Pill")
                  Center(
                    child: Container(
                      height: itemHeight,
                      decoration: BoxDecoration(
                        color: highlightColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  // Separator
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        "/",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 22,
                          fontWeight: FontWeight.w400,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),

                  // Wheels
                  Row(
                    children: [
                      // Year Wheel (Left)
                      Expanded(
                        child: _buildWheel(
                          controller: _yearController,
                          itemCount: maxYear - minYear + 1,
                          onChanged: (index) {
                            setState(() {
                              _selectedYear = minYear + index;
                            });
                          },
                          builder: (context, index) {
                            final year = minYear + index;
                            final isSelected = year == _selectedYear;
                            return Center(
                              child: Text(
                                year.toString(),
                                style: _getItemStyle(
                                  isSelected,
                                  textColor,
                                  secondaryTextColor,
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Month Wheel (Right)
                      Expanded(
                        child: _buildWheel(
                          controller: _monthController,
                          itemCount: 12,
                          onChanged: (index) {
                            setState(() {
                              _selectedMonth = index + 1;
                            });
                          },
                          builder: (context, index) {
                            final isSelected = (index + 1) == _selectedMonth;
                            final monthStr = (index + 1).toString().padLeft(
                              2,
                              '0',
                            );
                            return Center(
                              child: Text(
                                monthStr,
                                style: _getItemStyle(
                                  isSelected,
                                  textColor,
                                  secondaryTextColor,
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
                      foregroundColor: secondaryTextColor.withOpacity(
                        0.6,
                      ), // Darker grey
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
                      Navigator.pop(
                        context,
                        DateTime(_selectedYear, _selectedMonth),
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

  TextStyle _getItemStyle(bool isSelected, Color primary, Color secondary) {
    return TextStyle(
      fontFamily: 'Outfit',
      fontSize: isSelected ? 20 : 18,
      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      color: isSelected ? primary : secondary,
    );
  }
}
