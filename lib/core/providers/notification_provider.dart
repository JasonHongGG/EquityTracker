import 'dart:async';
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
  OverlayEntry? _overlayEntry;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final List<NotificationModel> _notifications = [];

  @override
  void build() {
    // No state exposed
  }

  void _ensureOverlayInitialized() {
    if (_overlayEntry != null) return;
    
    final context = globalNavigatorKey.currentContext;
    if (context == null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            elevation: 0,
            child: AnimatedList(
              key: _listKey,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              initialItemCount: _notifications.length,
              itemBuilder: (context, index, animation) {
                return _buildItem(_notifications[index], animation);
              },
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _buildItem(NotificationModel notification, Animation<double> animation) {
    return PremiumToastWidget(
      notification: notification,
      animation: animation,
      onDismiss: () => remove(notification.id),
    );
  }

  void show(
    String message, {
    NotificationType type = NotificationType.info,
    String? title,
    Duration duration = const Duration(seconds: 4),
  }) {
    _ensureOverlayInitialized();

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final notification = NotificationModel(
      id: id,
      message: message,
      type: type,
      title: title,
    );

    // Insert at the top (index 0)
    _notifications.insert(0, notification);
    _listKey.currentState?.insertItem(0, duration: const Duration(milliseconds: 400));

    // Auto dismiss
    Timer(duration, () {
      remove(id);
    });
  }

  void showSuccess(String message, {String? title}) => show(message, type: NotificationType.success, title: title);
  void showError(String message, {String? title}) => show(message, type: NotificationType.error, title: title);
  void showInfo(String message, {String? title}) => show(message, type: NotificationType.info, title: title);
  void showWarning(String message, {String? title}) => show(message, type: NotificationType.warning, title: title);

  void remove(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      final removedItem = _notifications.removeAt(index);
      _listKey.currentState?.removeItem(
        index,
        (context, animation) => _buildItem(removedItem, animation),
        duration: const Duration(milliseconds: 300),
      );
    }
    
    // Optional: if list is empty, we could remove the overlay to free resources
    // But keeping it around is fine too since it's transparent and shrink-wrapped to 0 height.
  }
}

final notificationControllerProvider = NotifierProvider<NotificationController, void>(() {
  return NotificationController();
});
