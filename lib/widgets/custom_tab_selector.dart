import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CustomTabSelector extends StatelessWidget {
  final TabController controller;
  final List<String> tabs;

  const CustomTabSelector({
    super.key,
    required this.controller,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? Colors.grey.withOpacity(0.1)
        : Colors.grey.shade200;

    final indicatorColor = isDark ? AppColors.surfaceDark : Colors.white;

    final selectedLabelColor = isDark ? Colors.white : Colors.black;

    final unselectedLabelColor = isDark
        ? Colors.white.withOpacity(0.5)
        : Colors.black.withOpacity(0.5);

    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
        child: TabBar(
          controller: controller,
          tabs: tabs.map((t) => Tab(text: t)).toList(),
          indicator: BoxDecoration(
            color: indicatorColor,
            borderRadius: BorderRadius.circular(21),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: selectedLabelColor,
          unselectedLabelColor: unselectedLabelColor,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontFamily: 'Outfit',
            fontSize: 14,
          ),
          // Remove ripple constraints
          overlayColor: WidgetStateProperty.resolveWith<Color?>((
            Set<WidgetState> states,
          ) {
            return states.contains(WidgetState.focused)
                ? null
                : Colors.transparent;
          }),
        ),
      ),
    );
  }
}
