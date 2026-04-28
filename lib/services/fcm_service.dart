import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 FCM Background: ${message.notification?.title}');
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

      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('🔔 FCM: Permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('🔔 FCM: Permission denied');
        return;
      }

      // Create notification channel
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

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Foreground messages
      FirebaseMessaging.onMessage.listen((message) {
        debugPrint('🔔 FCM Foreground: ${message.notification?.title}');
        final notification = message.notification;
        if (notification == null) return;

        _localNotifications.show(
          notification.hashCode,
          notification.title ?? 'Phone System',
          notification.body ?? 'معاملة جديدة',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'fcm_channel',
              'FCM Notifications',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/launcher_icon',
              playSound: true,
              enableVibration: true,
            ),
          ),
        );
        incrementBadge();
      });

      // ✅ Handle notification taps (when app is in background/terminated)
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        debugPrint('🔔 FCM: Notification tapped (background)');
        // Badge will be cleared when user opens Follow page
      });

      // ✅ Check if app was opened from a notification (terminated state)
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('🔔 FCM: App opened from notification (terminated)');
        // Badge will be cleared when user opens Follow page
      }

      // ✅ الخطوة الأساسية: احفظ التوكن عند كل فتح للتطبيق
      await _getAndSaveToken();

      // ✅ تحديث تلقائي لو Firebase جدد التوكن
      _messaging.onTokenRefresh.listen((token) {
        debugPrint('🔔 FCM: Token refreshed — saving new token');
        _saveToken(token);
      });

      debugPrint('🔔 FCM: Initialization complete ✅');
    } catch (e, st) {
      debugPrint('🔔 FCM: Init error: $e\n$st');
    }
  }

  Future<void> _getAndSaveToken() async {
    try {
      debugPrint('🔔 FCM: Starting automatic token registration...');

      // Wait a bit for Firebase to initialize fully
      await Future.delayed(const Duration(seconds: 2));

      final token = await _messaging.getToken();
      if (token != null) {
        debugPrint(
            '🔔 FCM: ✅ Token obtained automatically: ${token.substring(0, 20)}...');
        await _saveToken(token);
        debugPrint(
            '🔔 FCM: ✅ Token saved automatically - no button press needed!');
      } else {
        debugPrint('🔔 FCM: ⚠️ Token null on first try - retrying in 5s...');
        await Future.delayed(const Duration(seconds: 5));
        final retryToken = await _messaging.getToken();
        if (retryToken != null) {
          debugPrint(
              '🔔 FCM: ✅ Token obtained on retry: ${retryToken.substring(0, 20)}...');
          await _saveToken(retryToken);
          debugPrint(
              '🔔 FCM: ✅ Token saved on retry - automatic registration complete!');
        } else {
          debugPrint(
              '🔔 FCM: ❌ Token still null after retry - check Firebase setup');
        }
      }
    } catch (e, st) {
      debugPrint('🔔 FCM: ❌ Error in automatic token registration: $e\n$st');
    }
  }

  Future<void> _saveToken(String token) async {
    try {
      debugPrint('🔔 FCM: Saving token to Supabase database...');
      await Future.delayed(const Duration(seconds: 1));

      await Supabase.instance.client.from('fcm_tokens').upsert(
        {'token': token, 'device': 'manager'},
        onConflict: 'device',
      );
      debugPrint(
          '🔔 FCM: ✅✅✅ Token saved successfully! Notifications will work now.');
    } catch (e) {
      debugPrint('🔔 FCM: ⚠️ Save failed: $e — retrying in 5s');
      try {
        await Future.delayed(const Duration(seconds: 5));
        await Supabase.instance.client.from('fcm_tokens').upsert(
          {'token': token, 'device': 'manager'},
          onConflict: 'device',
        );
        debugPrint('🔔 FCM: ✅ Token saved on retry - notifications ready!');
      } catch (retryError) {
        debugPrint('🔔 FCM: ❌ Retry also failed: $retryError');
      }
    }
  }

  /// استدعيها يدوياً لو احتجت تعمل force refresh للتوكن
  Future<void> forceRefreshToken() async {
    try {
      debugPrint('🔔 FCM: Force refreshing token...');
      await _messaging.deleteToken();
      debugPrint('🔔 FCM: Old token deleted');
      await Future.delayed(const Duration(seconds: 2));
      final newToken = await _messaging.getToken();
      if (newToken != null) {
        await _saveToken(newToken);
        debugPrint('🔔 FCM: New token registered ✅');
      }
    } catch (e) {
      debugPrint('🔔 FCM: Force refresh error: $e');
    }
  }

  /// Test method to manually trigger token registration
  Future<String> testTokenRegistration() async {
    try {
      debugPrint('🧪 FCM TEST: Starting manual token registration test...');

      // Check Firebase initialization
      debugPrint('🧪 FCM TEST: Checking Firebase...');

      // Check Supabase initialization
      try {
        final _ = Supabase.instance.client;
        debugPrint('🧪 FCM TEST: ✅ Supabase initialized');
      } catch (e) {
        return '❌ Supabase not initialized: $e';
      }

      // Get token
      debugPrint('🧪 FCM TEST: Getting FCM token...');
      final token = await _messaging.getToken();

      if (token == null) {
        return '❌ FCM token is null';
      }

      debugPrint('🧪 FCM TEST: ✅ Token obtained: ${token.substring(0, 30)}...');

      // Try to save
      debugPrint('🧪 FCM TEST: Attempting to save to database...');
      await Supabase.instance.client.from('fcm_tokens').upsert(
        {'token': token, 'device': 'manager'},
        onConflict: 'device',
      );

      debugPrint('🧪 FCM TEST: ✅ Token saved successfully!');

      // Verify it was saved
      final result = await Supabase.instance.client
          .from('fcm_tokens')
          .select()
          .eq('device', 'manager')
          .single();

      debugPrint('🧪 FCM TEST: ✅ Verification: $result');

      return '✅ Success! Token: ${token.substring(0, 30)}...';
    } catch (e, st) {
      debugPrint('🧪 FCM TEST: ❌ Error: $e');
      debugPrint('🧪 FCM TEST: Stack: $st');
      return '❌ Error: $e';
    }
  }
}
