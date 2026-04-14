import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 FCM Background: ${message.notification?.title}');
}

class FcmService {
  static final FcmService instance = FcmService._();
  FcmService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

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

    // Foreground messages → show as local notification
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
