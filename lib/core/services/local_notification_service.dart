import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:equity_tracker/features/transaction/data/transaction_model.dart';
import 'package:intl/intl.dart';

class LocalNotificationService {
  // Singleton pattern
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    // Initialization Settings for Android
    // "@mipmap/ic_launcher" must exist.
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Initialization Settings for iOS
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );
    
    _isInitialized = true;
    await requestPermissions();
  }

  Future<void> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.requestNotificationsPermission();
  }

  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    // Handle notification tapped logic here if needed
  }

  Future<void> showAutoTransactionNotification(TransactionModel transaction) async {
    // Use transaction ID as notification ID to ensure independence
    // If ID is null (which shouldn't happen after DB insert), fallback to hashcode
    final int notificationId = transaction.id ?? transaction.hashCode;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'recurring_transactions_channel', // id
      '自動記帳通知', // name
      channelDescription: '系統自動產生的記帳記錄會在此顯示', // description
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );
    
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();
        
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    final amountStr = NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(transaction.amount);

    final typeStr = transaction.type.isIncome ? '收入' : '支出';

    await _flutterLocalNotificationsPlugin.show(
      id: notificationId,
      title: '系統自動記帳：${transaction.title}',
      body: '已自動記錄 $amountStr 的$typeStr，備註：${transaction.note}',
      notificationDetails: platformChannelSpecifics,
      payload: transaction.id?.toString(),
    );
  }
}
