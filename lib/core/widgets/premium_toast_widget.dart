import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:equity_tracker/core/notifications/domain/models/in_app_notification.dart';

class PremiumToastWidget extends StatelessWidget {
  final InAppNotification notification;
  final Animation<double> animation;
  final VoidCallback onDismiss;

  const PremiumToastWidget({
    super.key,
    required this.notification,
    required this.animation,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Premium styling config based on type
    final Color iconColor = _getIconColor();
    final IconData iconData = _getIconData();
    final Color bgColor = isDark 
        ? iconColor.withValues(alpha: 0.15) 
        : iconColor.withValues(alpha: 0.1);
    final Color borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : iconColor.withValues(alpha: 0.3);

    // Spring animation for entrance
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.elasticOut,
      reverseCurve: Curves.easeInBack,
    );

    return SizeTransition(
      sizeFactor: curvedAnimation,
      child: FadeTransition(
        opacity: animation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Align(
            alignment: Alignment.topCenter,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: bgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(iconData, color: iconColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (notification.title != null) ...[
                              Text(
                                notification.title!,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                            Text(
                              notification.message,
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black87.withValues(alpha: 0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onDismiss,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getIconColor() {
    switch (notification.type) {
      case NotificationType.success:
        return const Color(0xFF10B981); // Emerald 500
      case NotificationType.error:
        return const Color(0xFFEF4444); // Red 500
      case NotificationType.warning:
        return const Color(0xFFF59E0B); // Amber 500
      case NotificationType.info:
        return const Color(0xFF3B82F6); // Blue 500
    }
  }

  IconData _getIconData() {
    switch (notification.type) {
      case NotificationType.success:
        return Icons.check_circle_rounded;
      case NotificationType.error:
        return Icons.error_rounded;
      case NotificationType.warning:
        return Icons.warning_rounded;
      case NotificationType.info:
        return Icons.info_outline_rounded;
    }
  }
}
