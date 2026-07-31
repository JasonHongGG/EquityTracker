import 'package:flutter/material.dart';
import 'package:equity_tracker/features/settings/presentation/constants/update_ui_constants.dart';

class UpdateStatusDialog extends StatelessWidget {
  final String message;
  final bool isError;

  const UpdateStatusDialog({
    super.key,
    required this.message,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: UpdateDialogStyle.shape,
      backgroundColor: theme.canvasColor,
      surfaceTintColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(maxWidth: UpdateDialogStyle.maxWidth),
        padding: UpdateDialogStyle.padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isError)
              StatusIcon(
                icon: Icons.error_rounded,
                color: Colors.redAccent,
                backgroundColor: Colors.redAccent.withOpacity(0.1),
              )
            else
              Container(
                width: 64,
                height: 64,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C2C3E)
                      : const Color(0xFFF0F2F5),
                  shape: BoxShape.circle,
                ),
                child: const CircularProgressIndicator(strokeWidth: 3),
              ),
            const SizedBox(height: 24),
            Text(
              isError ? '檢查失敗' : '檢查中',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                fontFamily: 'Outfit',
                height: 1.5,
              ),
            ),
            if (isError) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    '關閉',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
