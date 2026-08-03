import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:equity_tracker/core/widgets/pickers/picker_dialog_shell.dart';

Future<int?> showCustomWheelPicker({
  required BuildContext context,
  required String title,
  required List<String> items,
  required int initialIndex,
}) {
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _CustomWheelPickerDialog(
      title: title,
      items: items,
      initialIndex: initialIndex,
    ),
  );
}

class _CustomWheelPickerDialog extends StatefulWidget {
  final String title;
  final List<String> items;
  final int initialIndex;

  const _CustomWheelPickerDialog({
    required this.title,
    required this.items,
    required this.initialIndex,
  });

  @override
  State<_CustomWheelPickerDialog> createState() => _CustomWheelPickerDialogState();
}

class _CustomWheelPickerDialogState extends State<_CustomWheelPickerDialog> {
  late int _selectedIndex;
  late FixedExtentScrollController _controller;
  final double itemHeight = 50.0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _controller = FixedExtentScrollController(initialItem: _selectedIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final secondaryTextColor = isDark ? Colors.white38 : Colors.black38;
    final highlightColor = theme.primaryColor.withValues(alpha: 0.12);

    return PickerBottomSheetShell(
      title: widget.title,
      onConfirm: () => Navigator.pop(context, _selectedIndex % widget.items.length),
      child: Stack(
        children: [
          // Selection Highlight (The "Pill")
          Center(
            child: Container(
              height: itemHeight,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
                  width: 1,
                ),
              ),
            ),
          ),
            
            // Wheel
            ListWheelScrollView.useDelegate(
              controller: _controller,
              itemExtent: itemHeight,
              perspective: 0.002,
              diameterRatio: 1.5,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (index) {
                setState(() => _selectedIndex = index);
                HapticFeedback.selectionClick();
              },
              childDelegate: ListWheelChildLoopingListDelegate(
                children: List.generate(
                  widget.items.length,
                  (index) {
                    final isSelected = index == (_selectedIndex % widget.items.length);
                    return Center(
                      child: Text(
                        widget.items[index],
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: isSelected ? 24 : 18,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                          color: isSelected ? textColor : secondaryTextColor.withValues(alpha: 0.4),
                          letterSpacing: 1.0,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
