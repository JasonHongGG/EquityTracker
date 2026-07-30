import 'package:flutter/material.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/core/theme/app_colors.dart';
import 'package:equity_tracker/core/widgets/scale_button.dart';

class TransactionTypeTabs extends StatelessWidget {
  final TransactionType selectedType;
  final ValueChanged<TransactionType> onChanged;

  const TransactionTypeTabs({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _buildTabItem(
            type: TransactionType.expense,
            label: 'Expense',
            isActive: selectedType == TransactionType.expense,
          ),
          _buildTabItem(
            type: TransactionType.income,
            label: 'Income',
            isActive: selectedType == TransactionType.income,
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required TransactionType type,
    required String label,
    required bool isActive,
  }) {
    return Expanded(
      child: ScaleButton(
        onPressed: () {
          if (!isActive) {
            onChanged(type);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isActive ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isActive
                  ? (type == TransactionType.income ? AppColors.income : AppColors.expense)
                  : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
