import 'package:flutter/material.dart';
import 'package:equity_tracker/features/settings/widgets/common/settings_tile.dart';

class SettingsDropdownTile<T> extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final T value;
  final List<T> items;
  final String Function(T) itemLabelBuilder;
  final void Function(T) onChanged;

  const SettingsDropdownTile({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    required this.value,
    required this.items,
    required this.itemLabelBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopupMenuButton<T>(
      initialValue: value,
      onSelected: onChanged,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: isDark ? const Color(0xFF1E2130) : Colors.white,
      elevation: 8,
      offset: const Offset(0, 50),
      position: PopupMenuPosition.under,
      itemBuilder: (context) {
        return items.map((item) {
          final isSelected = item == value;
          return PopupMenuItem<T>(
            value: item,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    itemLabelBuilder(item),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected 
                          ? Colors.blue 
                          : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check, color: Colors.blue, size: 18),
              ],
            ),
          );
        }).toList();
      },
      child: SettingsTile(
        icon: icon,
        iconColor: iconColor,
        title: title,
        subtitle: subtitle,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              itemLabelBuilder(value),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 20,
              color: isDark ? Colors.white30 : Colors.black26,
            ),
          ],
        ),
      ),
    );
  }
}
