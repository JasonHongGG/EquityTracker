import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/core/theme/app_colors.dart';

class SegmentedTypeTab extends StatefulWidget {
  final TransactionType selectedType;
  final ValueChanged<TransactionType> onChanged;

  const SegmentedTypeTab({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  @override
  State<SegmentedTypeTab> createState() => _SegmentedTypeTabState();
}

class _SegmentedTypeTabState extends State<SegmentedTypeTab> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Alignment> _alignmentAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _setupAnimation();
    if (widget.selectedType == TransactionType.income) {
      _controller.value = 1.0;
    } else {
      _controller.value = 0.0;
    }
  }

  void _setupAnimation() {
    _alignmentAnimation = AlignmentTween(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void didUpdateWidget(SegmentedTypeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedType != widget.selectedType) {
      if (widget.selectedType == TransactionType.income) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap(TransactionType type) {
    if (widget.selectedType != type) {
      HapticFeedback.lightImpact();
      widget.onChanged(type);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          // Sliding Pill
          AnimatedBuilder(
            animation: _alignmentAnimation,
            builder: (context, child) {
              return Align(
                alignment: _alignmentAnimation.value,
                child: FractionallySizedBox(
                  widthFactor: 0.5,
                  heightFactor: 1.0,
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF333333) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          // Texts
          Row(
            children: [
              _buildTabItem(
                type: TransactionType.expense,
                label: 'Expense',
              ),
              _buildTabItem(
                type: TransactionType.income,
                label: 'Income',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required TransactionType type,
    required String label,
  }) {
    final isActive = widget.selectedType == type;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _handleTap(type),
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14,
              color: isActive
                  ? (type == TransactionType.income ? AppColors.income : AppColors.expense)
                  : Colors.grey,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}
