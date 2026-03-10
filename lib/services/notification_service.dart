import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/models/log.dart';
import 'package:phone_system_app/models/client.dart';
import 'package:intl/intl.dart';
import 'package:phone_system_app/views/pages/follow.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'dart:io';
import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class TransactionNotificationService {
  static final TransactionNotificationService instance =
      TransactionNotificationService._internal();
  factory TransactionNotificationService() => instance;
  TransactionNotificationService._internal();

  bool _isInitialized = false;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  int _badgeCount = 0;

  static int? pendingClientId;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request notification permissions
    await _requestPermissions();

    // Initialize timezone data
    tz.initializeTimeZones();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'transactions_channel',
      'Transactions',
      description: 'Notifications for all transactions',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
      showBadge: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification:
          (int id, String? title, String? body, String? payload) async {},
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null) {
          final clientId = int.tryParse(response.payload!);
          if (clientId != null) {
            await Get.toNamed('/follow', arguments: {'clientId': clientId});
          }
        }
      },
    );

    _isInitialized = true;
    debugPrint('🔔 Notification service initialized');
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      debugPrint('🔔 Notification permission status: $status');
    }
  }

  Future<void> showTransactionNotification(LogWidthUser logWithUser) async {
    if (!_isInitialized) await initialize();

    // Check if the transaction is from المساعد
    final String userName = logWithUser.user?.name?.toLowerCase() ?? '';
    if (!userName.contains('المساعد')) {
      return; // Skip notifications for non-assistant transactions
    }

    final Log log = logWithUser.log;
    final Client? client = logWithUser.client;

    _badgeCount++;
    await AppBadgePlus.updateBadge(_badgeCount);

    final String clientName = client?.name ?? 'غير محدد';
    final String transactionType = log.transactionType.name();
    final String amount = '${log.price} جنيه';

    // Create a unique notification ID based on log ID
    final int notificationId = log.id.hashCode;

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'transactions_channel',
      'Transactions',
      channelDescription: 'Notifications for all transactions',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      color: _getNotificationColor(log.transactionType),
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(
        'تمت معاملة بواسطة: $userName\n'
        'نوع المعاملة: $transactionType\n'
        'العميل: $clientName\n'
        'المبلغ: $amount\n'
        'التاريخ: ${DateFormat.yMMMd('ar').add_jm().format(log.createdAt!)}',
        htmlFormatBigText: true,
        contentTitle: '<b>معاملة جديدة</b>',
        htmlFormatContentTitle: true,
      ),
    );

    final DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: _badgeCount,
      threadIdentifier: 'transactions',
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      notificationId,
      'معاملة جديدة',
      'تمت معاملة $transactionType بمبلغ $amount',
      platformDetails,
      payload: client?.id.toString(),
    );

    debugPrint('🔔 Notification sent for transaction ID: ${log.id}');
  }

  Future<void> showBasicNotification({
    required String title,
    required String body,
    int? id,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    _badgeCount++;
    await AppBadgePlus.updateBadge(_badgeCount);

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'transactions_channel',
      'Transactions',
      channelDescription: 'Notifications for all transactions',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      styleInformation: BigTextStyleInformation(
        body,
        htmlFormatBigText: true,
        contentTitle: '<b>$title</b>',
        htmlFormatContentTitle: true,
      ),
    );

    final DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: _badgeCount,
      threadIdentifier: 'transactions',
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    // Use timestamp to create unique notification IDs if not provided
    final notificationId = id ?? DateTime.now().millisecondsSinceEpoch.hashCode;

    await flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
      platformDetails,
      payload: payload,
    );

    debugPrint('🔔 Basic notification sent: $title');
  }

  Color _getNotificationColor(TransactionType type) {
    switch (type) {
      case TransactionType.deposit:
      case TransactionType.income:
        return Colors.green;
      case TransactionType.expense:
        return Colors.red;
      case TransactionType.transfer:
        return Colors.blue;
      default:
        return Colors.purple;
    }
  }

  Future<void> clearBadge() async {
    _badgeCount = 0;
    await AppBadgePlus.updateBadge(0);
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    await clearBadge();
  }
}

// This needs to be a top-level function
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  // Handle notification tap in background
  if (response.payload != null) {
    final clientId = int.tryParse(response.payload!);
    if (clientId != null) {
      TransactionNotificationService.pendingClientId = clientId;
    }
  }
  debugPrint('Notification tapped in background: ${response.payload}');
}
