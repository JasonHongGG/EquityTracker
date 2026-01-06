import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// import '../theme/app_colors.dart'; removed

class MonthSelector extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSearch;
  final VoidCallback onClearSearch;
  final bool isSearching;
  final VoidCallback? onTitleTap;
  final bool enableSearch;

  const MonthSelector({
    super.key,
    required this.selectedDate,
    required this.onPrevious,
    required this.onNext,
    required this.onSearch,
    required this.onClearSearch,
    this.isSearching = false,
    this.onTitleTap,
    this.enableSearch = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Centered Date Navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: onPrevious,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.chevron_left,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onTitleTap,
                child: Text(
                  DateFormat('yyyy / MM').format(selectedDate),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: onNext,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.chevron_right,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),

          // Right-aligned Search/Clear Button
          if (enableSearch)
            Positioned(
              right: 0,
              child: IconButton(
                onPressed: isSearching ? onClearSearch : onSearch,
                icon: Icon(
                  isSearching ? Icons.close : Icons.search,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
