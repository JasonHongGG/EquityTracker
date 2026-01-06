import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import 'gradient_card.dart';

class DashboardHeaderDelegate extends SliverPersistentHeaderDelegate {
  final int totalBalance;
  final int totalIncome;
  final int totalExpense;
  final int monthlyBalance;
  final int monthlyIncome;
  final int monthlyExpense;
  final double topPadding;
  final DateTime selectedDate;
  final bool isMonthlyView;
  final VoidCallback onToggleView;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback? onDateTap;

  final bool isPrivacyMode;

  DashboardHeaderDelegate({
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpense,
    required this.monthlyBalance,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.topPadding,
    required this.selectedDate,
    required this.isMonthlyView,
    required this.onToggleView,
    required this.onPreviousMonth,
    required this.onNextMonth,
    this.onDateTap,
    this.isPrivacyMode = false,
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
    return _DashboardHeaderContent(
      shrinkOffset: shrinkOffset,
      maxExtent: maxExtent,
      minExtent: minExtent,
      delegate: this,
    );
  }

  @override
  bool shouldRebuild(DashboardHeaderDelegate oldDelegate) {
    return oldDelegate.totalBalance != totalBalance ||
        oldDelegate.monthlyBalance != monthlyBalance ||
        oldDelegate.isMonthlyView != isMonthlyView ||
        oldDelegate.selectedDate != selectedDate ||
        oldDelegate.topPadding != topPadding ||
        oldDelegate.totalIncome != totalIncome ||
        oldDelegate.monthlyIncome != monthlyIncome ||
        oldDelegate.isPrivacyMode != isPrivacyMode;
  }
}

class _DashboardHeaderContent extends StatefulWidget {
  final double shrinkOffset;
  final double maxExtent;
  final double minExtent;
  final DashboardHeaderDelegate delegate;

  const _DashboardHeaderContent({
    required this.shrinkOffset,
    required this.maxExtent,
    required this.minExtent,
    required this.delegate,
  });

  @override
  State<_DashboardHeaderContent> createState() =>
      _DashboardHeaderContentState();
}

class _DashboardHeaderContentState extends State<_DashboardHeaderContent> {
  bool _isRevealed = false;

  @override
  void didUpdateWidget(covariant _DashboardHeaderContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset reveal state if privacy mode changes to enabled?
    // Or keep it. Let's keep it simple.
  }

  String _formatCurrency(int amount) {
    if (widget.delegate.isPrivacyMode && !_isRevealed) {
      return '****';
    }
    return '\$$amount';
  }

  @override
  Widget build(BuildContext context) {
    final delegate = widget.delegate;

    // 0.0 -> Expanded, 1.0 -> Collapsed
    final progress =
        (widget.shrinkOffset / (widget.maxExtent - widget.minExtent)).clamp(
          0.0,
          1.0,
        );

    // Animation Values
    final double topMargin = lerpDouble(12.0, 0, progress)!;
    final double sideMargin = lerpDouble(20, 0, progress)!;
    final double bottomMargin = lerpDouble(20, 0, progress)!;
    final double radius = lerpDouble(30, 0, progress)!;

    final double expandedOpacity = (1.0 - (progress * 4.0)).clamp(0.0, 1.0);
    final double collapsedOpacity = ((progress - 0.7) * 3.3).clamp(0.0, 1.0);

    final isCollapsed = progress > 0.5;
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final overlayStyle = isDarkTheme
        ? SystemUiOverlayStyle.light
        : (isCollapsed ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.dark);

    final Color? cardColor = isDarkTheme
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final Gradient? cardGradient = isDarkTheme ? null : null;
    final Color textColor = isDarkTheme
        ? Colors.white
        : AppColors.textPrimaryLight;
    final Color subTextColor = isDarkTheme
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final Color iconBgTint = isDarkTheme ? Colors.white : Colors.black;

    final int currentBalance = delegate.isMonthlyView
        ? delegate.monthlyBalance
        : delegate.totalBalance;
    final int currentIncome = delegate.isMonthlyView
        ? delegate.monthlyIncome
        : delegate.totalIncome;
    final int currentExpense = delegate.isMonthlyView
        ? delegate.monthlyExpense
        : delegate.totalExpense;
    final String labelTitle = delegate.isMonthlyView
        ? 'Monthly Balance'
        : 'Total Balance';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // === 1. MOVING CARD CONTAINER (Background + Expanded Content) ===
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
                    if (expandedOpacity > 0)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Opacity(
                          opacity: expandedOpacity,
                          child: GestureDetector(
                            onTap: () {
                              if (delegate.isPrivacyMode) {
                                setState(() {
                                  _isRevealed = !_isRevealed;
                                });
                              }
                            },
                            onHorizontalDragEnd: (details) {
                              if (details.primaryVelocity!.abs() > 300) {
                                delegate.onToggleView();
                              }
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                16,
                                24,
                                16,
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder:
                                    (
                                      Widget child,
                                      Animation<double> animation,
                                    ) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      );
                                    },
                                child: Row(
                                  key: ValueKey<bool>(delegate.isMonthlyView),
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Left Side: Balance
                                    Expanded(
                                      flex: 5,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            labelTitle,
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
                                              _formatCurrency(currentBalance),
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          _buildExpandedSummaryItem(
                                            context: context,
                                            label: 'Income',
                                            displayAmount: _formatCurrency(
                                              currentIncome,
                                            ),
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
                                            displayAmount: _formatCurrency(
                                              currentExpense,
                                            ),
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
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // === 2. COLLAPSED CONTENT (Pinned to Top) ===
            if (collapsedOpacity > 0)
              Positioned(
                top: delegate.topPadding,
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
                              onPressed: delegate.onPreviousMonth,
                              iconSize: 20,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                Icons.chevron_left,
                                color: textColor.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(width: 2),
                            GestureDetector(
                              onTap: delegate.onDateTap,
                              child: Text(
                                DateFormat(
                                  'yyyy / MM',
                                ).format(delegate.selectedDate),
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                            IconButton(
                              onPressed: delegate.onNextMonth,
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

                        // Right: Compact Stats (Animated)
                        GestureDetector(
                          onTap: () {
                            if (delegate.isPrivacyMode) {
                              setState(() {
                                _isRevealed = !_isRevealed;
                              });
                            }
                          },
                          onHorizontalDragEnd: (details) {
                            if (details.primaryVelocity!.abs() > 300) {
                              delegate.onToggleView();
                            }
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatCurrency(currentBalance),
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
                                    _formatCurrency(currentIncome),
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
                                    _formatCurrency(currentExpense),
                                    style: TextStyle(
                                      color: textColor.withOpacity(0.7),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
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
    );
  }

  Widget _buildExpandedSummaryItem({
    required BuildContext context,
    required String label,
    required String displayAmount,
    required Color color,
    required IconData icon,
    required Color textColor,
    required Color subTextColor,
    required Color iconBgTint,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
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
                  displayAmount,
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
}
