import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<int?> showCustomWheelPicker({
  required BuildContext context,
  required String title,
  required List<String> items,
  required int initialIndex,
}) {
  return showDialog<int>(
    context: context,
    builder: (context) => CustomWheelPicker(
      title: title,
      items: items,
      initialIndex: initialIndex,
    ),
  );
}

class CustomWheelPicker extends StatefulWidget {
  final String title;
  final List<String> items;
  final int initialIndex;

  const CustomWheelPicker({
    super.key,
    required this.title,
    required this.items,
    required this.initialIndex,
  });

  @override
  State<CustomWheelPicker> createState() => _CustomWheelPickerState();
}

class _CustomWheelPickerState extends State<CustomWheelPicker> {
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
              widget.title,
              style: TextStyle(
                // fontFamily: 'Outfit', // Assuming generic sans if unavailable
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
                  _buildWheel(
                    controller: _controller,
                    itemCount: widget.items.length,
                    onChanged: (index) =>
                        setState(() => _selectedIndex = index),
                    builder: (context, index) {
                      final isSelected = index == _selectedIndex;
                      return Center(
                        child: Text(
                          widget.items[index],
                          style: TextStyle(
                            fontSize: isSelected ? 20 : 18,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected ? textColor : secondaryTextColor,
                          ),
                        ),
                      );
                    },
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
                      Navigator.pop(context, _selectedIndex);
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
