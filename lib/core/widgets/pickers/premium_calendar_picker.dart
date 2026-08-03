import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'picker_dialog_shell.dart';

Future<DateTime?> showPremiumCalendarPicker({
  required BuildContext context,
  required DateTime initialDate,
  String title = 'Select Date',
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _PremiumCalendarPickerDialog(
      initialDate: initialDate,
      title: title,
    ),
  );
}

class _PremiumCalendarPickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final String title;

  const _PremiumCalendarPickerDialog({
    required this.initialDate,
    required this.title,
  });

  @override
  State<_PremiumCalendarPickerDialog> createState() => _PremiumCalendarPickerDialogState();
}

class _PremiumCalendarPickerDialogState extends State<_PremiumCalendarPickerDialog> {
  late DateTime _selectedDate;
  late PageController _pageController;
  late DateTime _currentMonth;

  // Assume Page 500 is the initial month, allowing infinite scrolling in both directions
  final int _initialPage = 500;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _currentMonth = DateTime(widget.initialDate.year, widget.initialDate.month);
    _pageController = PageController(initialPage: _initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _getMonthFromPage(int page) {
    final offset = page - _initialPage;
    return DateTime(widget.initialDate.year, widget.initialDate.month + offset);
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentMonth = _getMonthFromPage(page);
    });
    HapticFeedback.selectionClick();
  }

  void _goToPreviousMonth() {
    _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _goToNextMonth() {
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    return PickerBottomSheetShell(
      title: widget.title,
      contentHeight: 380, // Taller for the calendar
      useShaderMask: false, // Calendar does not need vertical fading
      onConfirm: () => Navigator.pop(context, _selectedDate),
      child: Column(
        children: [
          _buildMonthHeader(context),
          const SizedBox(height: 16),
          _buildWeekdaysHeader(context),
          const SizedBox(height: 8),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final monthDate = _getMonthFromPage(index);
                return _buildMonthGrid(context, monthDate);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: _goToPreviousMonth,
          icon: const Icon(Icons.chevron_left_rounded),
          color: textColor,
          splashRadius: 24,
        ),
        Text(
          DateFormat('MMMM yyyy').format(_currentMonth),
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor,
            letterSpacing: 0.5,
          ),
        ),
        IconButton(
          onPressed: _goToNextMonth,
          icon: const Icon(Icons.chevron_right_rounded),
          color: textColor,
          splashRadius: 24,
        ),
      ],
    );
  }

  Widget _buildWeekdaysHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white54 : Colors.black54;
    final weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekdays.map((day) {
        return SizedBox(
          width: 40,
          child: Center(
            child: Text(
              day,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMonthGrid(BuildContext context, DateTime monthDate) {
    final daysInMonth = DateTime(monthDate.year, monthDate.month + 1, 0).day;
    final firstDayOffset = DateTime(monthDate.year, monthDate.month, 1).weekday % 7;
    final previousMonthDays = DateTime(monthDate.year, monthDate.month, 0).day;

    final List<Widget> cells = [];

    // Previous month filler days
    for (int i = 0; i < firstDayOffset; i++) {
      final day = previousMonthDays - firstDayOffset + i + 1;
      cells.add(_buildDayCell(
        context,
        day: day,
        date: DateTime(monthDate.year, monthDate.month - 1, day),
        isCurrentMonth: false,
      ));
    }

    // Current month days
    for (int i = 1; i <= daysInMonth; i++) {
      cells.add(_buildDayCell(
        context,
        day: i,
        date: DateTime(monthDate.year, monthDate.month, i),
        isCurrentMonth: true,
      ));
    }

    // Next month filler days (to fill 42 cells)
    final remainingCells = 42 - cells.length;
    for (int i = 1; i <= remainingCells; i++) {
      cells.add(_buildDayCell(
        context,
        day: i,
        date: DateTime(monthDate.year, monthDate.month + 1, i),
        isCurrentMonth: false,
      ));
    }

    // Chunk cells into rows of 7
    final List<Widget> rows = [];
    for (int i = 0; i < cells.length; i += 7) {
      final end = (i + 7 < cells.length) ? i + 7 : cells.length;
      final rowCells = cells.sublist(i, end);
      rows.add(
        Expanded(
          child: Row(
            children: rowCells.map((cell) => Expanded(child: cell)).toList(),
          ),
        ),
      );
    }

    return Column(
      children: rows,
    );
  }

  Widget _buildDayCell(
    BuildContext context, {
    required int day,
    required DateTime date,
    required bool isCurrentMonth,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isSelected = date.year == _selectedDate.year &&
        date.month == _selectedDate.month &&
        date.day == _selectedDate.day;

    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;

    Color textColor;
    if (isSelected) {
      textColor = Colors.white;
    } else if (!isCurrentMonth) {
      textColor = isDark ? Colors.white24 : Colors.black26;
    } else {
      textColor = isDark ? Colors.white : Colors.black87;
    }

    // Modern glowing/frosted background for selection
    BoxDecoration decoration;
    if (isSelected) {
      decoration = BoxDecoration(
        color: theme.primaryColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      );
    } else if (isToday) {
      decoration = BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.5), width: 1.5),
      );
    } else {
      decoration = BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.transparent,
      );
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedDate = date;
          // If tapped outside current month, auto-switch page
          if (date.isBefore(DateTime(_currentMonth.year, _currentMonth.month, 1))) {
            _goToPreviousMonth();
          } else if (date.isAfter(DateTime(_currentMonth.year, _currentMonth.month + 1, 0))) {
            _goToNextMonth();
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: decoration,
        child: Center(
          child: Text(
            day.toString(),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16,
              fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
