import 'package:flutter/material.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/core/theme/app_colors.dart';

class RecurringTransactionHeader extends StatelessWidget {
  final TransactionType type;
  final TextEditingController amountController;
  final TextEditingController titleController;
  final FocusNode titleFocusNode;
  final VoidCallback onAmountTap;

  const RecurringTransactionHeader({
    super.key,
    required this.type,
    required this.amountController,
    required this.titleController,
    required this.titleFocusNode,
    required this.onAmountTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txtColor = isDark ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          GestureDetector(
            onTap: onAmountTap,
            child: IntrinsicWidth(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: (type == TransactionType.income
                              ? AppColors.income
                              : AppColors.expense)
                          .withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text(
                      '\$',
                      style: TextStyle(
                        fontSize: 32,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      amountController.text.isEmpty
                          ? '0'
                          : amountController.text,
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: type == TransactionType.income
                            ? AppColors.income
                            : AppColors.expense,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: titleController,
            focusNode: titleFocusNode,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              color: txtColor,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'What is this for?',
              hintStyle: TextStyle(
                color: Colors.grey.withValues(alpha: 0.5),
              ),
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }
}
