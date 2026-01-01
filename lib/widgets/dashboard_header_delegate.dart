import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import 'gradient_card.dart';

class DashboardHeaderDelegate extends SliverPersistentHeaderDelegate {
  final int balance;
  final int income;
  final int expense;
  final double topPadding;
  final DateTime selectedDate;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback? onDateTap;

  DashboardHeaderDelegate({
    required this.balance,
    required this.income,
    required this.expense,
    required this.topPadding,
    required this.selectedDate,
    required this.onPreviousMonth,
    required this.onNextMonth,
    this.onDateTap,
  });

  @override
  double get minExtent => kToolbarHeight + topPadding;

  @override
  double get maxExtent => 220.0;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // 0.0 -> Expanded, 1.0 -> Collapsed
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);

    // Animation Values
    final double topMargin = lerpDouble(12.0, 0, progress)!;
    final double sideMargin = lerpDouble(20, 0, progress)!;
    final double bottomMargin = lerpDouble(
      20,
      0,
      progress,
    )!; // Smooth transition
    final double radius = lerpDouble(30, 0, progress)!;

    // Fade out expanded content
    // End earlier (0.3) so it doesn't fight for space as height gets tiny
    final double expandedOpacity = (1.0 - (progress * 4.0)).clamp(0.0, 1.0);

    // Fade in collapsed content
    final double collapsedOpacity = ((progress - 0.7) * 3.3).clamp(0.0, 1.0);

    // Status bar style
    final isCollapsed = progress > 0.5;
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final overlayStyle = isDarkTheme
        ? SystemUiOverlayStyle.light
        : (isCollapsed
              ? SystemUiOverlayStyle.dark
              : SystemUiOverlayStyle.dark); // collapsed(white card)->dark icons

    // Theme Colors
    final Color? cardColor = isDarkTheme
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final Gradient? cardGradient = isDarkTheme
        ? null
        : null; // Use solid colors for better contrast control
    final Color textColor = isDarkTheme
        ? Colors.white
        : AppColors.textPrimaryLight;
    final Color subTextColor = isDarkTheme
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final Color iconBgTint = isDarkTheme ? Colors.white : Colors.black;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // === 1. MOVING CARD CONTAINER (Background + Expanded Content) ===
            // We group them so they move perfectly together without relative math errors.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  sideMargin,
                  topMargin,
                  sideMargin,
                  bottomMargin,
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background
                    GradientCard(
                      borderRadius: radius,
                      gradient: cardGradient,
                      color: cardColor,
                      padding: EdgeInsets.zero,
                      child: Container(),
                    ),

                    // === EXPANDED STATE CONTENT ===
                    // This moves WITH the card (respecting topMargin)
                    if (expandedOpacity > 0)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        bottom: 0, // Match card bottom padding
                        child: Opacity(
                          opacity: expandedOpacity,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Left Side: Total Balance
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total Balance',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(color: subTextColor),
                                      ),
                                      const SizedBox(height: 8),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          '\$$balance',
                                          style: Theme.of(context)
                                              .textTheme
                                              .displayMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: textColor,
                                                letterSpacing: -1.0,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 16),

                                // Right Side: Income & Expense Column
                                Expanded(
                                  flex: 4,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildExpandedSummaryItem(
                                        context: context,
                                        label: 'Income',
                                        amount: income,
                                        color: AppColors.income,
                                        icon: Icons.arrow_downward,
                                        textColor: textColor,
                                        subTextColor: subTextColor,
                                        iconBgTint: iconBgTint,
                                      ),
                                      const SizedBox(height: 12),
                                      _buildExpandedSummaryItem(
                                        context: context,
                                        label: 'Expense',
                                        amount: expense,
                                        color: AppColors.expense,
                                        icon: Icons.arrow_upward,
                                        textColor: textColor,
                                        subTextColor: subTextColor,
                                        iconBgTint: iconBgTint,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // === 2. COLLAPSED CONTENT (Pinned to Top) ===
            if (collapsedOpacity > 0)
              Positioned(
                top: topPadding,
                left: 0,
                right: 0,
                height: kToolbarHeight,
                child: Opacity(
                  opacity: collapsedOpacity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left: Compact Month Selector
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: onPreviousMonth,
                              iconSize: 20,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                Icons.chevron_left,
                                color: textColor.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: onDateTap,
                              child: Text(
                                DateFormat('yyyy/MM').format(selectedDate),
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: onNextMonth,
                              iconSize: 20,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                Icons.chevron_right,
                                color: textColor.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),

                        // Right: Compact Stats
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$$balance',
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                fontFamily: 'Outfit',
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.arrow_downward,
                                  color: AppColors.income,
                                  size: 12,
                                ),
                                Text(
                                  '\$$income',
                                  style: TextStyle(
                                    color: textColor.withOpacity(0.7),
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_upward,
                                  color: AppColors.expense,
                                  size: 12,
                                ),
                                Text(
                                  '\$$expense',
                                  style: TextStyle(
                                    color: textColor.withOpacity(0.7),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedSummaryItem({
    required BuildContext context,
    required String label,
    required int amount,
    required Color color,
    required IconData icon,
    required Color textColor,
    required Color subTextColor,
    required Color iconBgTint,
  }) {
    // Simplified Minimalist Design
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(
              0.15,
            ), // Use color itself for tint, cleaner
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: subTextColor,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '\$$amount',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool shouldRebuild(DashboardHeaderDelegate oldDelegate) {
    return oldDelegate.balance != balance ||
        oldDelegate.income != income ||
        oldDelegate.expense != expense ||
        oldDelegate.topPadding != topPadding ||
        oldDelegate.selectedDate != selectedDate;
  }
}
