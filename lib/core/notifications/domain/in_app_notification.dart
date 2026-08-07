enum NotificationType { success, error, info, warning }

class InAppNotification {
  final String id;
  final String message;
  final NotificationType type;
  final String? title;

  InAppNotification({
    required this.id,
    required this.message,
    required this.type,
    this.title,
  });
}
