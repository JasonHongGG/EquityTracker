import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() async {
  final plugin = FlutterLocalNotificationsPlugin();
  
  await plugin.initialize(
    settings: const InitializationSettings(),
  );

  await plugin.show(
    id: 0,
    title: 'Title',
    body: 'Body',
    notificationDetails: const NotificationDetails(),
    payload: 'Payload',
  );
}
