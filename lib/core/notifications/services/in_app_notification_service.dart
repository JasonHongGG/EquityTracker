import 'package:flutter/material.dart';
import 'package:equity_tracker/core/router/global_navigator.dart';
import 'package:equity_tracker/core/widgets/premium_toast_widget.dart';
import 'package:equity_tracker/core/notifications/domain/in_app_notification.dart';

abstract class InAppNotificationService {
  void showSuccess(String message, {String? title});
  void showError(String message, {String? title});
  void showInfo(String message, {String? title});
  void showWarning(String message, {String? title});
}

class InAppNotificationServiceImpl implements InAppNotificationService {
  void _show(
    String message, {
    NotificationType type = NotificationType.info,
    String? title,
    Duration duration = const Duration(seconds: 4),
  }) {
    final overlay = globalNavigatorKey.currentState?.overlay;
    if (overlay == null) return;

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final notification = InAppNotification(
      id: id,
      message: message,
      type: type,
      title: title,
    );

    OverlayEntry? entry;
    
    void removeEntry() {
      if (entry != null && entry!.mounted) {
        entry!.remove();
        entry = null;
      }
    }

    entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: MediaQuery.paddingOf(context).top + 16,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            elevation: 0,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return PremiumToastWidget(
                  notification: notification,
                  animation: AlwaysStoppedAnimation(value),
                  onDismiss: removeEntry,
                );
              },
            ),
          ),
        );
      },
    );

    overlay.insert(entry!);

    // Auto dismiss
    Future.delayed(duration, () {
      removeEntry();
    });
  }

  @override
  void showSuccess(String message, {String? title}) => _show(message, type: NotificationType.success, title: title);
  @override
  void showError(String message, {String? title}) => _show(message, type: NotificationType.error, title: title);
  @override
  void showInfo(String message, {String? title}) => _show(message, type: NotificationType.info, title: title);
  @override
  void showWarning(String message, {String? title}) => _show(message, type: NotificationType.warning, title: title);
}
