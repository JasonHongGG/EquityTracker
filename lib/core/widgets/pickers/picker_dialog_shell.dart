import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PickerDialogShell extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const PickerDialogShell({
    super.key,
    required this.title,
    required this.child,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;

    // Premium Colors
    final backgroundColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final secondaryTextColor = isDark ? Colors.white38 : Colors.black38;

    return Dialog(
      backgroundColor: backgroundColor,
      surfaceTintColor: Colors.transparent, // Remove M3 tint
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        width: 340, // Fixed width for consistent look
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 24),

            // Content Area (Wheels)
            child,

            const SizedBox(height: 32),

            // Actions
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      onCancel();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      foregroundColor: secondaryTextColor.withValues(alpha: 0.6),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      onConfirm();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Confirm',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
