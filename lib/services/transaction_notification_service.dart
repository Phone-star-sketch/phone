import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/models/log.dart';
import 'package:phone_system_app/models/client.dart';
import 'package:phone_system_app/models/user.dart';
import 'package:phone_system_app/utils/string_utils.dart';
import 'package:phone_system_app/services/backend/auth.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:phone_system_app/views/pages/follow.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
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
    print('🔔 Notification service initialized');
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      print('🔔 Notification permission status: $status');
    }
  }

  Future<void> showTransactionNotification(LogWidthUser logWithUser) async {
    if (!_isInitialized) await initialize();

    final Log log = logWithUser.log;
    final Client? client = logWithUser.client;
    final AppUser? user = logWithUser.user;

    // Increment badge count
    _badgeCount++;
    await AppBadgePlus.updateBadge(_badgeCount);

    final String clientName = client?.name ?? 'غير محدد';
    final String transactionType = log.transactionType.name();
    final String amount = '${log.price} جنيه';

    // Create a unique notification ID based on log ID and timestamp
    final int notificationId =
        (log.id.toString() + DateTime.now().millisecondsSinceEpoch.toString())
            .hashCode;

    // Create notification details with high priority
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'transactions_channel',
      'Transactions',
      channelDescription: 'Notifications for all transactions',
      importance: Importance.max, // Changed to max for better reliability
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      color: _getNotificationColor(log.transactionType),
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(
        'تمت معاملة بواسطة: ${user?.name ?? "المساعد"}\n'
        'نوع المعاملة: $transactionType\n'
        'العميل: $clientName\n'
        'المبلغ: $amount\n'
        'التاريخ: ${DateFormat.yMMMd('ar').add_jm().format(log.createdAt!)}',
        htmlFormatBigText: true,
        contentTitle: '<b>معاملة جديدة من المساعد</b>',
        htmlFormatContentTitle: true,
      ),
      fullScreenIntent:
          true, // Show as full screen intent for important notifications
      ongoing: false, // Don't make it ongoing
      autoCancel: true, // Auto cancel when tapped
      showWhen: true, // Show timestamp
      when: DateTime.now().millisecondsSinceEpoch,
    );

    final DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: _badgeCount,
      threadIdentifier: 'transactions',
      interruptionLevel:
          InterruptionLevel.timeSensitive, // High priority for iOS
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    try {
      await flutterLocalNotificationsPlugin.show(
        notificationId,
        'معاملة جديدة من المساعد',
        'تمت معاملة $transactionType بمبلغ $amount',
        platformDetails,
        payload: client?.id.toString(),
      );

      print('🔔 Notification sent for transaction ID: ${log.id}');
    } catch (e) {
      print('🔔 Error showing notification: $e');
      // Retry once if failed
      try {
        await flutterLocalNotificationsPlugin.show(
          notificationId,
          'معاملة جديدة من المساعد',
          'تمت معاملة $transactionType بمبلغ $amount',
          platformDetails,
          payload: client?.id.toString(),
        );
      } catch (e) {
        print('🔔 Failed to show notification after retry: $e');
      }
    }
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
  print('Notification tapped in background: ${response.payload}');
}
