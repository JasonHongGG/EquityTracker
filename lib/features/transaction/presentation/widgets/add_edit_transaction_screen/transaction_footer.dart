import 'package:flutter/material.dart';
import 'package:equity_tracker/core/theme/app_colors.dart';
import 'package:equity_tracker/core/widgets/scale_button.dart';

class TransactionFooter extends StatelessWidget {
  final TextEditingController noteController;
  final VoidCallback onSave;

  const TransactionFooter({
    super.key,
    required this.noteController,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : Colors.white;
    final txtColor = isDark ? Colors.white : Colors.black;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
        color: surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.backgroundDark : Colors.grey[100],
              borderRadius: BorderRadius.circular(15),
            ),
            child: TextField(
              controller: noteController,
              style: TextStyle(color: txtColor),
              decoration: const InputDecoration(
                hintText: 'Add note...',
                border: InputBorder.none,
                icon: Icon(
                  Icons.edit,
                  size: 16,
                  color: Colors.grey,
                ),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ScaleButton(
              onPressed: onSave,
              child: Container(
                height: 50,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Save',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
