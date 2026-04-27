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
    if (kIsWeb) {
      debugPrint('🔔 FCM: Skipping on Web');
      return;
    }

    try {
      debugPrint('🔔 FCM: Starting initialization...');

      // Request permission
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('🔔 FCM: Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('🔔 FCM: Permission denied by user');
        return;
      }

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
      debugPrint('🔔 FCM: Notification channel created');

      await _localNotifications.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      debugPrint('🔔 FCM: Local notifications initialized');

      // Background handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Foreground messages → show as local notification + badge
      FirebaseMessaging.onMessage.listen((message) {
        debugPrint('🔔 FCM: Foreground message received');
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
              channelDescription: 'معاملات المساعد',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/launcher_icon',
            ),
          ),
        );
        incrementBadge();
      });

      // Get token with retry logic
      await _getAndSaveToken();

      // Refresh token
      _messaging.onTokenRefresh.listen((token) {
        debugPrint('🔔 FCM: Token refreshed');
        _saveToken(token);
      });

      debugPrint('🔔 FCM: Initialization complete');
    } catch (e, stackTrace) {
      debugPrint('🔔 FCM: Initialization error: $e');
      debugPrint('🔔 FCM: Stack trace: $stackTrace');
    }
  }

  Future<void> _getAndSaveToken() async {
    try {
      // Wait a bit for Firebase to be fully ready
      await Future.delayed(const Duration(seconds: 2));

      final token = await _messaging.getToken();
      if (token != null) {
        debugPrint('🔔 FCM Token: $token');
        await _saveToken(token);
      } else {
        debugPrint('🔔 FCM: Token is null, retrying in 5 seconds...');
        // Retry after 5 seconds
        await Future.delayed(const Duration(seconds: 5));
        final retryToken = await _messaging.getToken();
        if (retryToken != null) {
          debugPrint('🔔 FCM Token (retry): $retryToken');
          await _saveToken(retryToken);
        } else {
          debugPrint('🔔 FCM: Token still null after retry');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('🔔 FCM: Error getting token: $e');
      debugPrint('🔔 FCM: Stack trace: $stackTrace');
    }
  }

  Future<void> _saveToken(String token) async {
    try {
      debugPrint('🔔 FCM: Attempting to save token...');

      // Wait a bit to ensure Supabase is ready
      await Future.delayed(const Duration(seconds: 1));

      await Supabase.instance.client.from('fcm_tokens').upsert(
        {'token': token, 'device': 'manager'},
        onConflict: 'device',
      );
      debugPrint('🔔 FCM: Token saved successfully');
    } catch (e, stackTrace) {
      debugPrint('🔔 FCM: Error saving token: $e');
      debugPrint('🔔 FCM: Stack trace: $stackTrace');

      // Retry once after 5 seconds
      try {
        await Future.delayed(const Duration(seconds: 5));
        await Supabase.instance.client.from('fcm_tokens').upsert(
          {'token': token, 'device': 'manager'},
          onConflict: 'device',
        );
        debugPrint('🔔 FCM: Token saved successfully (retry)');
      } catch (retryError) {
        debugPrint('🔔 FCM: Retry failed: $retryError');
      }
    }
  }
}
