import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class NotificationController extends Notifier<List<NotificationModel>> {
  @override
  List<NotificationModel> build() {
    return [];
  }

  void show(
    String message, {
    NotificationType type = NotificationType.info,
    String? title,
    Duration duration = const Duration(seconds: 4),
  }) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final notification = NotificationModel(
      id: id,
      message: message,
      type: type,
      title: title,
    );

    // Add to the beginning of the list
    state = [notification, ...state];

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
    state = state.where((n) => n.id != id).toList();
  }
}

final notificationControllerProvider = NotifierProvider<NotificationController, List<NotificationModel>>(() {
  return NotificationController();
});
