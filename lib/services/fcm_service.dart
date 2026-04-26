import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 FCM Background: ${message.notification?.title}');
  // Increment badge on background notification
  try {
    await AppBadgePlus.updateBadge(1);
  } catch (e) {
    debugPrint('🔔 Background badge error: $e');
  }
}

class FcmService {
  static final FcmService instance = FcmService._();
  FcmService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  int _badgeCount = 0;

  int get badgeCount => _badgeCount;

  Future<void> incrementBadge() async {
    _badgeCount++;
    if (!kIsWeb) {
      try {
        await AppBadgePlus.updateBadge(_badgeCount);
      } catch (e) {
        debugPrint('🔔 Badge error: $e');
      }
    }
  }

  Future<void> clearBadge() async {
    _badgeCount = 0;
    if (!kIsWeb) {
      try {
        await AppBadgePlus.updateBadge(0);
      } catch (e) {
        debugPrint('🔔 Badge clear error: $e');
      }
    }
  }

  Future<void> initialize() async {
    if (kIsWeb) return;

    // Request permission
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // Create notification channel for foreground messages
    const channel = AndroidNotificationChannel(
      'fcm_channel',
      'FCM Notifications',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    // Background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Foreground messages → show as local notification + badge
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'fcm_channel',
            'FCM Notifications',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
      incrementBadge();
    });

    // Get token and save it
    final token = await _messaging.getToken();
    if (token != null) {
      debugPrint('🔔 FCM Token: $token');
      await _saveToken(token);
    }

    // Refresh token
    _messaging.onTokenRefresh.listen(_saveToken);
  }

  Future<void> _saveToken(String token) async {
    try {
      await Supabase.instance.client.from('fcm_tokens').upsert(
        {'token': token, 'device': 'manager'},
        onConflict: 'device',
      );
      debugPrint('🔔 FCM token saved');
    } catch (e) {
      debugPrint('🔔 Error saving token: $e');
    }
  }
}
