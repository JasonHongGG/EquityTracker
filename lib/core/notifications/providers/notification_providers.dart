import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/notifications/services/in_app_notification_service.dart';
import 'package:equity_tracker/core/notifications/services/system_notification_service.dart';
import 'package:equity_tracker/core/notifications/services/app_notification_service.dart';
import 'package:equity_tracker/core/providers/repository_providers.dart';

final inAppNotificationServiceProvider = Provider<InAppNotificationService>((ref) {
  return InAppNotificationServiceImpl();
});

final systemNotificationServiceProvider = Provider<SystemNotificationService>((ref) {
  throw UnimplementedError('systemNotificationServiceProvider must be overridden in main.dart');
});

final appNotificationServiceProvider = Provider<AppNotificationService>((ref) {
  return AppNotificationService(
    ref.read(systemNotificationServiceProvider),
    ref.read(categoryRepositoryProvider),
  );
});
