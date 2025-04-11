import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/models/log.dart';
import 'package:phone_system_app/models/client.dart';
import 'package:phone_system_app/models/user.dart';
import 'package:intl/intl.dart';
import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phone_system_app/views/pages/follow.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class TransactionNotificationService {
  static final TransactionNotificationService instance = 
      TransactionNotificationService._internal();
  
  factory TransactionNotificationService() => instance;
  
  TransactionNotificationService._internal();

  // Vibration pattern
  static final Int64List _vibrationPattern = 
      Int64List.fromList([0, 500, 200, 500]);
  
  // Service state
  bool _isInitialized = false;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  int _badgeCount = 0;
  
  // For handling notification taps
  static int? pendingClientId;
  
  // Channel IDs
  static const String MAIN_CHANNEL_ID = 'transactions_channel';
  static const String ASSISTANT_CHANNEL_ID = 'assistant_transactions_channel';
  
  // Completer for initialization
  final Completer<bool> _initCompleter = Completer<bool>();
  Future<bool> get isInitialized => _initCompleter.future;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      print('🔔 Starting notification service initialization');
      
      // Initialize timezone data first
      tz.initializeTimeZones();
      
      // Request permissions
      final permissionStatus = await _requestPermissions();
      if (!permissionStatus) {
        print('🔔 Warning: Notification permissions not granted');
      }
      
      // Create notification channels for Android
      if (Platform.isAndroid) {
        await _createAndroidNotificationChannels();
      }
      
      // Initialize platforms
      final initializationSettings = await _setupPlatformSettings();
      
      // Initialize plugin
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _handleNotificationResponse,
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );
      
      // Check if there are any pending client IDs from background taps
      _checkPendingClientId();
      
      _isInitialized = true;
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete(true);
      }
      
      print('🔔 Notification service initialized successfully');
    } catch (e) {
      print('🔔 Error initializing notification service: $e');
      _isInitialized = false;
      
      // If the completer is not completed yet, complete with false
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete(false);
      }
      
      // Retry initialization after a delay
      Future.delayed(Duration(seconds: 5), () => initialize());
    }
  }
  
  Future<bool> _requestPermissions() async {
    bool isGranted = false;
    
    try {
      if (Platform.isAndroid) {
        // For Android 13+ we need to request specific permissions
        final notificationStatus = await Permission.notification.status;
        
        if (notificationStatus.isDenied) {
          final result = await Permission.notification.request();
          isGranted = result.isGranted;
          
          if (result.isPermanentlyDenied) {
            // Suggest opening app settings
            print('🔔 Notification permission permanently denied. Please enable in settings.');
          }
        } else {
          isGranted = notificationStatus.isGranted;
        }
      } else if (Platform.isIOS) {
        // For iOS, permissions are requested during initialization
        isGranted = true;
      }
    } catch (e) {
      print('🔔 Error requesting permissions: $e');
      isGranted = false;
    }
    
    return isGranted;
  }
  
  Future<void> _createAndroidNotificationChannels() async {
    // Main transactions channel
    const AndroidNotificationChannel mainChannel = AndroidNotificationChannel(
      MAIN_CHANNEL_ID,
      'Transactions',
      description: 'Notifications for all transactions',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
      showBadge: true,
    );

    // Assistant-specific channel with custom sound
    final AndroidNotificationChannel assistantChannel = AndroidNotificationChannel(
      ASSISTANT_CHANNEL_ID,
      'Assistant Transactions',
      description: 'Priority notifications for assistant transactions',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
      showBadge: true,
      // Use system default sound if custom sound fails
      sound: const RawResourceAndroidNotificationSound('notification_sound'),
      vibrationPattern: _vibrationPattern,
    );

    // Create the channels
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(mainChannel);
      await androidPlugin.createNotificationChannel(assistantChannel);
      print('🔔 Android notification channels created');
    }
  }
  
  Future<InitializationSettings> _setupPlatformSettings() async {
    // Android settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: (int id, String? title, String? body, String? payload) async {
        // For older iOS versions (deprecated but needed for backward compatibility)
        print('🔔 Received local notification: $id, $title, $body, $payload');
      },
    );

    // Combined settings
    return InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
  }
  
  void _checkPendingClientId() {
    if (pendingClientId != null) {
      print('🔔 Found pending client ID: $pendingClientId');
      // Navigate to follow screen with the client ID
      Future.delayed(Duration(milliseconds: 500), () {
        Get.toNamed('/follow', arguments: {'clientId': pendingClientId});
        pendingClientId = null;
      });
    }
  }

  Future<void> _handleNotificationResponse(NotificationResponse response) async {
    print('🔔 Notification tapped: ${response.payload}');
    if (response.payload != null) {
      final clientId = int.tryParse(response.payload!);
      if (clientId != null) {
        await Get.toNamed('/follow', arguments: {'clientId': clientId});
      }
    }
  }

  Future<void> showTransactionNotification(LogWidthUser logWithUser) async {
    // Ensure initialized or wait for initialization
    if (!_isInitialized) {
      print('🔔 Waiting for notification service to initialize...');
      bool initialized = await isInitialized;
      if (!initialized) {
        print('🔔 Failed to initialize notification service');
        return;
      }
    }

    final Log log = logWithUser.log;
    final Client? client = logWithUser.client;
    final AppUser? user = logWithUser.user;

    // Check if transaction is from المساعد (assistant)
    final String userName = user?.name?.toLowerCase() ?? '';
    if (!userName.contains('المساعد')) {
      print('🔔 Skipping notification - not from المساعد');
      return;
    }

    try {
      // Increment badge count
      _badgeCount++;
      try {
        await AppBadgePlus.updateBadge(_badgeCount);
      } catch (e) {
        print('🔔 Badge update error: $e');
      }

      // Prepare notification content
      final String clientName = client?.name ?? 'غير محدد';
      final String transactionType = log.transactionType.name();
      final String amount = '${log.price} جنيه';
      final String date = DateFormat.yMMMd('ar').add_jm().format(log.createdAt!);

      // Create a unique ID for the notification
      final int notificationId = log.id.hashCode ^ DateTime.now().millisecondsSinceEpoch;

      // Build notification details based on platform
      final NotificationDetails platformDetails = await _buildNotificationDetails(
        log.transactionType,
        user?.name ?? 'المساعد',
        transactionType,
        clientName,
        amount,
        date,
      );

      // Show the notification
      await flutterLocalNotificationsPlugin.show(
        notificationId,
        'معاملة جديدة من المساعد',
        'تمت معاملة $transactionType للعميل $clientName بمبلغ $amount',
        platformDetails,
        payload: client?.id.toString(),
      );

      print('🔔 Notification sent successfully for transaction ID: ${log.id}');
    } catch (e) {
      print('🔔 Error showing notification: $e');
      // Retry with simpler notification as fallback
      await _retryWithSimpleNotification(log, client);
    }
  }

  Future<NotificationDetails> _buildNotificationDetails(
    TransactionType transactionType,
    String userName,
    String transactionType_str,
    String clientName,
    String amount,
    String date,
  ) async {
    // Android notification details
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      ASSISTANT_CHANNEL_ID,
      'Assistant Transactions',
      channelDescription: 'Notifications for assistant transactions',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      color: _getNotificationColor(transactionType),
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(
        'تمت معاملة بواسطة: $userName\n'
        'نوع المعاملة: $transactionType_str\n'
        'العميل: $clientName\n'
        'المبلغ: $amount\n'
        'التاريخ: $date',
        htmlFormatBigText: true,
        contentTitle: '<b>معاملة جديدة من المساعد</b>',
        htmlFormatContentTitle: true,
        summaryText: 'معاملة جديدة من المساعد',
      ),
      fullScreenIntent: true,
      ongoing: false,
      autoCancel: true,
      showWhen: true,
      when: DateTime.now().millisecondsSinceEpoch,
      sound: const RawResourceAndroidNotificationSound('notification_sound'),
      vibrationPattern: _vibrationPattern,
    );

    // iOS notification details
    final DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: _badgeCount,
      threadIdentifier: 'assistant_transactions',
      interruptionLevel: InterruptionLevel.timeSensitive,
      // Use system default sound if custom sound fails
      sound: 'notification_sound.aiff',
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );
  }

  Future<void> _retryWithSimpleNotification(Log log, Client? client) async {
    try {
      // Simple notification as fallback
      final simpleAndroidDetails = AndroidNotificationDetails(
        MAIN_CHANNEL_ID,
        'Transactions',
        channelDescription: 'Notifications for all transactions',
        importance: Importance.high,
        priority: Priority.high,
      );
      
      final simpleDarwinDetails = DarwinNotificationDetails();
      
      final simpleDetails = NotificationDetails(
        android: simpleAndroidDetails,
        iOS: simpleDarwinDetails,
      );
      
      final int fallbackId = log.id.hashCode;
      
      await flutterLocalNotificationsPlugin.show(
        fallbackId,
        'معاملة جديدة',
        'تمت معاملة ${log.transactionType.name()} بمبلغ ${log.price} جنيه',
        simpleDetails,
        payload: client?.id.toString(),
      );
      
      print('🔔 Simple fallback notification sent successfully');
    } catch (e) {
      print('🔔 Even simple notification failed: $e');
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
    try {
      await AppBadgePlus.updateBadge(0);
    } catch (e) {
      print('🔔 Error clearing badge: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    await clearBadge();
  }
  
  // Test notification method for debugging
  Future<void> sendTestNotification() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      // Simple test notification
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        ASSISTANT_CHANNEL_ID,
        'Assistant Transactions',
        channelDescription: 'Notifications for assistant transactions',
        importance: Importance.max,
        priority: Priority.high,
        sound: const RawResourceAndroidNotificationSound('notification_sound'),
        vibrationPattern: _vibrationPattern,
      );
      
      final DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'notification_sound.aiff',
      );
      
      final NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );
      
      await flutterLocalNotificationsPlugin.show(
        999,
        'اختبار الإشعارات',
        'هذا اختبار للتأكد من أن الإشعارات تعمل بشكل صحيح',
        platformDetails,
      );
      
      print('🔔 Test notification sent successfully');
    } catch (e) {
      print('🔔 Test notification failed: $e');
    }
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