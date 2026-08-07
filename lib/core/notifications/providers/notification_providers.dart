import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/notifications/services/in_app_notification_service.dart';
import 'package:equity_tracker/core/notifications/services/system_notification_service.dart';

final inAppNotificationServiceProvider = Provider<InAppNotificationService>((ref) {
  return InAppNotificationServiceImpl();
});

final systemNotificationServiceProvider = Provider<SystemNotificationService>((ref) {
  final service = SystemNotificationServiceImpl();
  // Initialize on creation (or can be done manually in main.dart)
  service.init();
  return service;
});
