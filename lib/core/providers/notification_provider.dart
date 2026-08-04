import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/router/global_navigator.dart';
import 'package:equity_tracker/core/widgets/premium_toast_widget.dart';

enum NotificationType { success, error, info, warning }

class NotificationModel {
  final String id;
  final String message;
  final NotificationType type;
  final String? title;

  NotificationModel({
    required this.id,
    required this.message,
    required this.type,
    this.title,
  });
}

class NotificationController extends Notifier<void> {
  @override
  void build() {}

  void show(
    String message, {
    NotificationType type = NotificationType.info,
    String? title,
    Duration duration = const Duration(seconds: 4),
  }) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final notification = NotificationModel(
      id: id,
      message: message,
      type: type,
      title: title,
    );

    // Remove current snackbar to avoid queue delays
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        content: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            // Using internal PremiumToastWidget but providing static animation value
            // since SnackBar handles its own slide animation, we can just use the widget's appearance
            return PremiumToastWidget(
              notification: notification,
              animation: const AlwaysStoppedAnimation(1.0),
              onDismiss: () {
                scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
              },
            );
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 0),
        behavior: SnackBarBehavior.floating,
        padding: EdgeInsets.zero,
        duration: duration,
        // Make it appear at top
        dismissDirection: DismissDirection.up,
      ),
    );
  }

  void showSuccess(String message, {String? title}) => show(message, type: NotificationType.success, title: title);
  void showError(String message, {String? title}) => show(message, type: NotificationType.error, title: title);
  void showInfo(String message, {String? title}) => show(message, type: NotificationType.info, title: title);
  void showWarning(String message, {String? title}) => show(message, type: NotificationType.warning, title: title);
}

final notificationControllerProvider = NotifierProvider<NotificationController, void>(() {
  return NotificationController();
});
