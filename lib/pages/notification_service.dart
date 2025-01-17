import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/launcher_icon');
    
    const InitializationSettings settings = 
        InitializationSettings(android: androidSettings);

    await notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) async {
        // Handle notification tap
      },
    );
  }

  Future<void> scheduleBiDailyNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'phone_system_reminders',
      'System Reminders',
      channelDescription: 'Bi-daily system check reminders',
      importance: Importance.high,
      priority: Priority.high,
      enableLights: true,
      enableVibration: true,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
    );

    const NotificationDetails notificationDetails = 
        NotificationDetails(android: androidDetails);

    await notificationsPlugin.zonedSchedule(
      0,
      'نظام إدارة الهواتف',
      'حان وقت التحقق من النظام',
      _getNextNotificationTime(),
      notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  tz.TZDateTime _getNextNotificationTime() {
    tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      10, // Schedule for 10 AM
      0,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 2));
    }

    return scheduledDate;
  }
}