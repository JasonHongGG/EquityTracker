import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:equity_tracker/core/widgets/pickers/picker_dialog_shell.dart';

Future<DateTime?> showCustomDateTimePicker({
  required BuildContext context,
  required DateTime initialDate,
  bool showYear = false,
  bool showMonth = false,
  bool showDay = false,
  bool showTime = false,
  String title = 'Select Date & Time',
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (context) => _CustomDateTimePickerDialog(
      initialDate: initialDate,
      showYear: showYear,
      showMonth: showMonth,
      showDay: showDay,
      showTime: showTime,
      title: title,
    ),
  );
}

class _CustomDateTimePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final bool showYear;
  final bool showMonth;
  final bool showDay;
  final bool showTime;
  final String title;

  const _CustomDateTimePickerDialog({
    required this.initialDate,
    required this.showYear,
    required this.showMonth,
    required this.showDay,
    required this.showTime,
    required this.title,
  });

  @override
  State<_CustomDateTimePickerDialog> createState() => _CustomDateTimePickerDialogState();
}

class _CustomDateTimePickerDialogState extends State<_CustomDateTimePickerDialog> {
  late int _selectedYear;
  late int _selectedMonth;
  late int _selectedDay;
  late int _selectedHour;
  late int _selectedMinute;

  // Controllers
  late FixedExtentScrollController _yearController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _dayController;
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  final int minYear = 2000;
  final int maxYear = 2050;
  final double itemHeight = 50.0;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;
    _selectedMonth = widget.initialDate.month;
    _selectedDay = widget.initialDate.day;
    _selectedHour = widget.initialDate.hour;
    _selectedMinute = widget.initialDate.minute;

    _yearController = FixedExtentScrollController(initialItem: _selectedYear - minYear);
    _monthController = FixedExtentScrollController(initialItem: _selectedMonth - 1);
    _dayController = FixedExtentScrollController(initialItem: _selectedDay - 1);
    _hourController = FixedExtentScrollController(initialItem: _selectedHour);
    _minuteController = FixedExtentScrollController(initialItem: _selectedMinute);
  }

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    _dayController.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  int _getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  void _onMonthOrYearChanged() {
    // When month or year changes, we might need to clamp the selected day
    // e.g. from Jan 31 to Feb -> Feb 28
    if (!widget.showDay) return;
    
    final maxDays = _getDaysInMonth(_selectedYear, _selectedMonth);
    if (_selectedDay > maxDays) {
      setState(() {
        _selectedDay = maxDays;
      });
      // Animate the wheel to the new valid day
      _dayController.animateToItem(
        _selectedDay - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final secondaryTextColor = isDark ? Colors.white38 : Colors.black38;
    final highlightColor = theme.primaryColor.withOpacity(0.12);

    final List<Widget> wheels = [];
    final List<Widget> separators = [];

    // Construct the active wheels based on flags
    if (widget.showYear) {
      wheels.add(
        _buildExpandedWheel(
          controller: _yearController,
          itemCount: maxYear - minYear + 1,
          onChanged: (index) {
            setState(() => _selectedYear = minYear + index);
            _onMonthOrYearChanged();
          },
          builder: (context, index) {
            final year = minYear + index;
            return _buildWheelItem(year.toString(), year == _selectedYear, textColor, secondaryTextColor);
          },
        )
      );
    }

    if (widget.showMonth) {
      if (wheels.isNotEmpty) separators.add(_buildSeparator("/", textColor));
      wheels.add(
        _buildExpandedWheel(
          controller: _monthController,
          itemCount: 12,
          onChanged: (index) {
            setState(() => _selectedMonth = index + 1);
            _onMonthOrYearChanged();
          },
          builder: (context, index) {
            final month = index + 1;
            return _buildWheelItem(month.toString().padLeft(2, '0'), month == _selectedMonth, textColor, secondaryTextColor);
          },
        )
      );
    }

    if (widget.showDay) {
      if (wheels.isNotEmpty) separators.add(_buildSeparator("/", textColor));
      final daysInCurrentMonth = _getDaysInMonth(_selectedYear, _selectedMonth);
      wheels.add(
        _buildExpandedWheel(
          controller: _dayController,
          itemCount: daysInCurrentMonth,
          onChanged: (index) {
            setState(() => _selectedDay = index + 1);
          },
          builder: (context, index) {
            final day = index + 1;
            return _buildWheelItem(day.toString().padLeft(2, '0'), day == _selectedDay, textColor, secondaryTextColor);
          },
        )
      );
    }

    if (widget.showTime) {
      if (wheels.isNotEmpty) {
        // Add a bit more spacing if we have Date + Time mixed
        separators.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              "-",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 22,
                color: textColor.withOpacity(0.3),
              ),
            ),
          )
        );
      }
      
      wheels.add(
        _buildExpandedWheel(
          controller: _hourController,
          itemCount: 24,
          onChanged: (index) => setState(() => _selectedHour = index),
          builder: (context, index) {
            return _buildWheelItem(index.toString().padLeft(2, '0'), index == _selectedHour, textColor, secondaryTextColor);
          },
        )
      );

      separators.add(_buildSeparator(":", textColor));

      wheels.add(
        _buildExpandedWheel(
          controller: _minuteController,
          itemCount: 60,
          onChanged: (index) => setState(() => _selectedMinute = index),
          builder: (context, index) {
            return _buildWheelItem(index.toString().padLeft(2, '0'), index == _selectedMinute, textColor, secondaryTextColor);
          },
        )
      );
    }

    // Interleave wheels and separators
    final List<Widget> rowChildren = [];
    for (int i = 0; i < wheels.length; i++) {
      rowChildren.add(wheels[i]);
      if (i < separators.length) {
        rowChildren.add(separators[i]);
      }
    }

    return PickerDialogShell(
      title: widget.title,
      onCancel: () => Navigator.pop(context),
      onConfirm: () {
        final result = DateTime(
          widget.showYear ? _selectedYear : widget.initialDate.year,
          widget.showMonth ? _selectedMonth : widget.initialDate.month,
          widget.showDay ? _selectedDay : widget.initialDate.day,
          widget.showTime ? _selectedHour : widget.initialDate.hour,
          widget.showTime ? _selectedMinute : widget.initialDate.minute,
        );
        Navigator.pop(context, result);
      },
      child: SizedBox(
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

            // Wheels Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: rowChildren,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedWheel({
    required FixedExtentScrollController controller,
    required int itemCount,
    required ValueChanged<int> onChanged,
    required IndexedWidgetBuilder builder,
  }) {
    return Expanded(
      child: ListWheelScrollView.useDelegate(
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
      ),
    );
  }

  Widget _buildWheelItem(String text, bool isSelected, Color primary, Color secondary) {
    return Center(
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: isSelected ? 20 : 18,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? primary : secondary,
        ),
      ),
    );
  }

  Widget _buildSeparator(String char, Color textColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(
          char,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 22,
            fontWeight: FontWeight.w400,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
