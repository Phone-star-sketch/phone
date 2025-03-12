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
import 'package:phone_system_app/views/pages/follow.dart';

class TransactionNotificationService {
  static final TransactionNotificationService instance = TransactionNotificationService._internal();
  factory TransactionNotificationService() => instance;
  TransactionNotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    final DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: (int id, String? title, String? body, String? payload) async {},
    );
    
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null) {
          // Handle notification tap here
          print('Notification tapped with payload: ${response.payload}');
        }
      },
    );
  }

  Future<void> showAssistantTransactionNotification(LogWidthUser logWithUser) async {
    final currentUser = SupabaseAuthentication.myUser;
    final isManager = currentUser?.role == UserRoles.manager.index || 
                     currentUser?.role == UserRoles.admin.index;
    
    final isAssistantTransaction = logWithUser.user?.name?.toLowerCase().contains('المساعد') ?? false;
    
    if (!isManager || !isAssistantTransaction) return;
    
    final platformChannelSpecifics = await _createStyledNotificationDetails(
      logWithUser.log,
      logWithUser.client,
      logWithUser.log.transactionType.name(),
      "${logWithUser.log.price} جنيه"
    );
    
    await flutterLocalNotificationsPlugin.show(
      logWithUser.log.id.hashCode,
      'معاملة جديدة من المساعد',
      'تمت معاملة ${logWithUser.log.transactionType.name()} لـ ${logWithUser.client?.name ?? "غير محدد"} بمبلغ ${logWithUser.log.price} جنيه',
      platformChannelSpecifics,
      payload: logWithUser.client!.id.toString(),
    );
  }

  Future<NotificationDetails> _createStyledNotificationDetails(Log log, Client? client, String transactionTypeName, String amount) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'assistant_transactions',
      'معاملات المساعد',
      channelDescription: 'إشعارات لمعاملات المساعد',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(
        'تمت معاملة ${transactionTypeName} لـ ${client?.name ?? "غير محدد"}\n'
        'المبلغ: ${amount}\n'
        'التاريخ: ${DateFormat.yMMMd('ar').add_jm().format(log.createdAt!)}',
        htmlFormatBigText: true,
        contentTitle: '<b>معاملة جديدة من المساعد</b>',
        htmlFormatContentTitle: true,
      ),
      color: _getNotificationColor(log.transactionType),
    );

    final DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      subtitle: 'معاملة ${log.transactionType.name()}',
    );

    return NotificationDetails(android: androidDetails, iOS: iOSDetails);
  }

  Color _getNotificationColor(TransactionType type) {
    switch (type) {
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
}
