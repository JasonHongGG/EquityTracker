import 'package:flutter/material.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';

class CategoryTypeSelector extends StatelessWidget {
  final TransactionType selectedType;
  final ValueChanged<TransactionType> onChanged;

  const CategoryTypeSelector({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TYPE',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: theme.hintColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 56,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? Colors.black26 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildTypeTab(TransactionType.expense, 'Exp'),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildTypeTab(TransactionType.income, 'Inc'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeTab(TransactionType type, String label) {
    final isSelected = selectedType == type;
    final color = type == TransactionType.income
        ? const Color(0xFF34C759)
        : const Color(0xFFFF3B30);

    return GestureDetector(
      onTap: () => onChanged(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: isSelected ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }
}
