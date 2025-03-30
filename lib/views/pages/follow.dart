import 'dart:async';
import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/controllers/account_client_info_data.dart';
import 'package:phone_system_app/controllers/client_bottom_sheet_controller.dart';
import 'package:phone_system_app/controllers/money_display_loading.dart';
import 'package:phone_system_app/models/client.dart';
import 'package:phone_system_app/models/log.dart';
import 'package:phone_system_app/models/user.dart';
import 'package:phone_system_app/services/backend/auth.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';
import 'package:phone_system_app/services/notification_service.dart';
import 'package:phone_system_app/utils/string_utils.dart';
import 'package:phone_system_app/views/bottom_sheet_dialogs/show_client_info_sheet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class LogWidthUser {
  Log log;
  AppUser? user;
  Client? client;
  LogWidthUser({required this.log}) {
    user = SupabaseAuthentication.allUser!.firstWhereOrNull(
      (element) => element.id == log.createdBy,
    );

    if (log.clientId != null) {
      client = AccountClientInfo.to.clinets.firstWhereOrNull(
        (element) => element.id == log.clientId,
      );
    }
  }
}

class LogNotification {
  final LogWidthUser logWithUser;
  final bool isRead;
  final DateTime createdAt;

  LogNotification({
    required this.logWithUser,
    this.isRead = false,
    required this.createdAt,
  });

  bool get isRecent => createdAt.isAfter(
        DateTime.now().subtract(const Duration(minutes: 5)),
      );
}

class FollowController extends GetxController {
  RxList<LogWidthUser> logs = <LogWidthUser>[].obs;
  RealtimeChannel? _subscription;
  RxString connectionStatus = 'غير متصل'.obs;
  RxString lastUpdateTime = ''.obs;
  RxList<LogNotification> notifications = <LogNotification>[].obs;

  @override
  void onInit() async {
    super.onInit();
    await TransactionNotificationService.instance.initialize();
    await _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      // First ensure clients are loaded
      await AccountClientInfo.to.fetchClients();

      // Then fetch logs
      await updateLogs();

      // Finally setup real-time
      _setupRealtime();
    } catch (e) {
      print('Error initializing data: $e');
    }
  }

  // Helper methods for log handling
  Log _createLogFromPayload(Map<String, dynamic> record) {
    return Log(
      id: record['id'].toString(),
      accountId: record['account_id'].toString(),
      createdBy: record['created_by'].toString(),
      price: double.parse(record['price'].toString()),
      transactionType: TransactionType
          .values[int.parse(record['transaction_type'].toString())],
      createdAt: DateTime.parse(record['created_at'].toString()),
      systemType: record['system_type'].toString(),
      clientId: record['client_id']?.toString(),
      phoneId: record['phone_id']?.toString(),
    );
  }

  String _getClientNameFromLog(Log log) {
    if (log.clientId == null) return "غير محدد";

    final client = AccountClientInfo.to.clinets.firstWhereOrNull(
      (element) => element.id == log.clientId,
    );

    return client?.name ?? "غير محدد";
  }

  String _getClientNameById(String clientId) {
    final client = AccountClientInfo.to.clinets.firstWhereOrNull(
      (element) => element.id == clientId,
    );

    return client?.name ?? "غير محدد";
  }

  void _setupRealtime() {
    try {
      final client = Supabase.instance.client;
      connectionStatus.value = 'جاري الاتصال...';

      _subscription = client
          .channel('logs-channel')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'logs',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'account_id',
              value: AccountClientInfo.to.currentAccount.id,
            ),
            callback: (payload) async {
              print(
                  '🔴 Realtime update received: ${payload.eventType} at ${DateTime.now()}');
              lastUpdateTime.value = DateFormat.jm('ar').format(DateTime.now());

              switch (payload.eventType) {
                case PostgresChangeEvent.insert:
                  if (payload.newRecord != null) {
                    final log = _createLogFromPayload(payload.newRecord!);
                    final logWithUser = LogWidthUser(log: log);
                    final clientName = _getClientNameFromLog(log);

                    // Add to notifications list immediately
                    notifications.insert(
                      0,
                      LogNotification(
                        logWithUser: logWithUser,
                        createdAt: log.createdAt!,
                      ),
                    );

                    // Add to logs list immediately
                    logs.insert(0, logWithUser);

                    // Check if it's an assistant transaction and show notification
                    final userName =
                        logWithUser.user?.name?.toLowerCase() ?? '';
                    if (userName.contains('المساعد')) {
                      await TransactionNotificationService.instance
                          .showTransactionNotification(logWithUser);
                    }
                  }
                  break;

                case PostgresChangeEvent.update:
                  if (payload.oldRecord != null && payload.newRecord != null) {
                    final log = _createLogFromPayload(payload.newRecord!);
                    final logWithUser = LogWidthUser(log: log);
                    final userName =
                        logWithUser.user?.name?.toLowerCase() ?? '';

                    if (userName.contains('المساعد')) {
                      final clientName = _getClientNameFromLog(log);
                      final oldPrice =
                          double.parse(payload.oldRecord!['price'].toString());
                      final newPrice =
                          double.parse(payload.newRecord!['price'].toString());

                      await TransactionNotificationService.instance
                          .showBasicNotification(
                        title: 'تحديث معاملة',
                        body:
                            'تم تعديل قيمة المعاملة للعميل $clientName من $oldPrice إلى $newPrice جنيه',
                        id: log.id.hashCode,
                        payload: log.clientId?.toString(),
                      );
                    }

                    // Update logs list immediately
                    final index =
                        logs.indexWhere((item) => item.log.id == log.id);
                    if (index != -1) {
                      logs[index] = logWithUser;
                    }
                  }
                  break;

                case PostgresChangeEvent.delete:
                  if (payload.oldRecord != null) {
                    final logId = payload.oldRecord!['id'].toString();
                    final clientId =
                        payload.oldRecord!['client_id']?.toString();

                    // Remove from logs list immediately
                    logs.removeWhere((item) => item.log.id == logId);
                    notifications.removeWhere(
                        (item) => item.logWithUser.log.id == logId);

                    final userName = logs
                            .firstWhereOrNull((item) => item.log.id == logId)
                            ?.user
                            ?.name
                            ?.toLowerCase() ??
                        '';

                    if (userName.contains('المساعد')) {
                      final clientName = clientId != null
                          ? _getClientNameById(clientId)
                          : "غير محدد";
                      final deletedPrice =
                          double.parse(payload.oldRecord!['price'].toString());

                      await TransactionNotificationService.instance
                          .showBasicNotification(
                        title: 'حذف معاملة',
                        body:
                            'تم حذف معاملة للعميل $clientName بقيمة $deletedPrice جنيه',
                        id: DateTime.now().millisecondsSinceEpoch,
                        payload: clientId,
                      );
                    }
                  }
                  break;
                case PostgresChangeEvent.all:
                  break;
              }

              // Fetch updated clients data in background
              await AccountClientInfo.to.fetchClients();
            },
          )
          .subscribe((status, error) {
        if (error != null) {
          connectionStatus.value = 'خطأ في الاتصال';
          print('🔴 Realtime error: $error');
        } else {
          connectionStatus.value = 'متصل';
          print('🔴 Realtime status: $status');
        }
      });
    } catch (e) {
      connectionStatus.value = 'فشل الاتصال';
      print('🔴 Error setting up realtime: $e');
    }
  }

  @override
  void onClose() {
    _subscription?.unsubscribe();
    super.onClose();
  }

  Future<void> updateLogs() async {
    Loaders.to.followLoading.value = true;

    try {
      final l = <Log>[];
      final dataAdd =
          await BackendServices.instance.logRepository.getLogsByMatchMapQuery({
        Log.accountIdColumnName: AccountClientInfo.to.currentAccount.id,
      }, 200);

      l.addAll(dataAdd);

      logs.value = l
          .map(
            (e) => LogWidthUser(log: e),
          )
          .toList();

      // Create notifications for new logs
      notifications.value = logs
          .map((log) => LogNotification(
                logWithUser: log,
                createdAt: log.log.createdAt!,
              ))
          .toList();

      // Sort notifications by date
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print("Real-time update: Found ${logs.length} logs");

      // Process notifications for new transactions
      await processNewTransactionsForNotifications();

      Loaders.to.followLoading.value = false;
    } catch (e) {
      print("Real-time update error: $e");
      Get.snackbar("مشكلة اثناء التحميل", e.toString());
      Loaders.to.followLoading.value = false;
    }
  }

  // Add notification processing method
  Future<void> processNewTransactionsForNotifications() async {
    await TransactionNotificationService.instance.initialize();

    final recentLogs = logs.where((logWithUser) {
      final isRecent = logWithUser.log.createdAt
              ?.isAfter(DateTime.now().subtract(const Duration(minutes: 5))) ??
          false;
      final userName = logWithUser.user?.name?.toLowerCase() ?? '';
      final isAssistant = userName.contains('المساعد');
      return isRecent && isAssistant;
    }).toList();

    for (final logWithUser in recentLogs) {
      await TransactionNotificationService.instance
          .showTransactionNotification(logWithUser);
    }
  }

  Future<void> insertDummyLog() async {
    final dummyLog = Log(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      accountId: AccountClientInfo.to.currentAccount.id,
      createdBy: SupabaseAuthentication.myUser!.id,
      price: Random().nextInt(1000).toDouble(),
      transactionType: TransactionType.deposit,
      createdAt: DateTime.now(),
      systemType: '0',
      clientId: AccountClientInfo.to.clinets.first.id,
      phoneId: '0',
    );

    await BackendServices.instance.logRepository.create(dummyLog);
    await updateLogs();
  }

  // Add function to clear all notifications
  Future<void> clearAllNotifications() async {
    await TransactionNotificationService.instance.cancelAllNotifications();
    notifications.clear();
  }
}

class Follow extends StatelessWidget {
  final controller = Get.put(FollowController());

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Obx(() {
        final list = controller.logs;
        // Sort logs by creation date, most recent first
        list.sort((a, b) => b.log.createdAt!.compareTo(a.log.createdAt!));

        // Count unread notifications for each tab
        final managerUnread = list.where((log) {
          final userName = log.user?.name?.toLowerCase() ?? '';
          final isManager =
              userName.contains('كابتن') || userName.contains('اسلام النني');
          final isRecent = log.log.createdAt?.isAfter(
                  DateTime.now().subtract(const Duration(minutes: 5))) ??
              false;
          return isManager && isRecent;
        }).length;

        final assistantUnread = list.where((log) {
          final userName = log.user?.name?.toLowerCase() ?? '';
          final isAssistant = userName.contains('المساعد');
          final isRecent = log.log.createdAt?.isAfter(
                  DateTime.now().subtract(const Duration(minutes: 5))) ??
              false;
          return isAssistant && isRecent;
        }).length;

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          "سجل بأخر الاحداث و التعاملات",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (SupabaseAuthentication.myUser!.role ==
                              UserRoles.admin.index)
                            IconButton(
                              onPressed: () => controller.insertDummyLog(),
                              icon: Icon(Icons.add_circle, size: 20),
                              tooltip: 'إضافة معاملة تجريبية',
                              color: Colors.blue,
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                            ),
                          SizedBox(width: 4),
                          Icon(
                            controller.connectionStatus.value == 'متصل'
                                ? Icons.wifi
                                : Icons.wifi_off,
                            color: controller.connectionStatus.value == 'متصل'
                                ? Colors.green
                                : Colors.red,
                            size: 20,
                          ),
                          SizedBox(width: 4),
                          Text(
                            controller.connectionStatus.value,
                            style:
                                TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (controller.lastUpdateTime.value.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'آخر تحديث: ${controller.lastUpdateTime.value}',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
            TabBar(
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('المدير'),
                      if (managerUnread > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$managerUnread',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('المساعد'),
                      if (assistantUnread > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$assistantUnread',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
            ),
            (Loaders.to.followLoading.value)
                ? Container(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Center(
                      child: CustomIndicator(
                        title: "",
                      ),
                    ),
                  )
                : Expanded(
                    child: TabBarView(
                      children: [
                        // Manager View
                        _buildManagerView(list, context),
                        // Assistant View
                        _buildAssistantView(list, context),
                      ],
                    ),
                  ),
          ],
        );
      }),
    );
  }

  Widget _buildManagerView(List<LogWidthUser> list, BuildContext context) {
    final managerNotifications = controller.notifications.where((notification) {
      final userName = notification.logWithUser.user?.name?.toLowerCase() ?? '';
      return userName.contains('كابتن') || userName.contains('اسلام النني');
    }).toList();

    return NotificationListView(
      notifications: managerNotifications,
      onTapNotification: (notification) async {
        if (notification.logWithUser.client != null) {
          final client = notification.logWithUser.client;
          final controller = Get.put(ClientBottomSheetController());
          controller.setClient(client!);
          await showClientInfoSheet(context, client);
          Get.delete<ClientBottomSheetController>(force: true);
        }
      },
      showAdminControls: true,
    );
  }

  Widget _buildAssistantView(List<LogWidthUser> list, BuildContext context) {
    final assistantNotifications =
        controller.notifications.where((notification) {
      final userName = notification.logWithUser.user?.name?.toLowerCase() ?? '';
      return userName.contains('المساعد');
    }).toList();

    return NotificationListView(
      notifications: assistantNotifications,
      onTapNotification: (notification) async {
        if (notification.logWithUser.client != null) {
          final client = notification.logWithUser.client;
          final controller = Get.put(ClientBottomSheetController());
          controller.setClient(client!);
          await showClientInfoSheet(context, client);
          Get.delete<ClientBottomSheetController>(force: true);
        }
      },
      showAdminControls: false,
    );
  }
}

class NotificationListView extends StatelessWidget {
  final List<LogNotification> notifications;
  final Function(LogNotification) onTapNotification;
  final bool showAdminControls;

  const NotificationListView({
    Key? key,
    required this.notifications,
    required this.onTapNotification,
    this.showAdminControls = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: notifications.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return Stack(
          children: [
            Card(
              margin: EdgeInsets.all(8),
              child: InkWell(
                onTap: () => onTapNotification(notification),
                child: LogWithUserCardWidget(
                  logWidthUser: notification.logWithUser,
                  showAdminControls: showAdminControls,
                ),
              ),
            ),
            if (notification.isRecent)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'جديد',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class LogWithUserCardWidget extends StatefulWidget {
  final LogWidthUser logWidthUser;
  final bool showAdminControls;

  const LogWithUserCardWidget({
    Key? key,
    required this.logWidthUser,
    this.showAdminControls = true,
  }) : super(key: key);

  @override
  _LogWithUserCardWidgetState createState() => _LogWithUserCardWidgetState();
}

class _LogWithUserCardWidgetState extends State<LogWithUserCardWidget>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _gradientAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _gradientAnimation = ColorTween(
      begin: Colors.blue.shade50,
      end: Colors.purple.shade50,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
    if (isHovered) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Client? currentClient = widget.logWidthUser.client;
    final Log currentLog = widget.logWidthUser.log;
    final AppUser? user = widget.logWidthUser.user;

    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _gradientAnimation.value!,
                    _gradientAnimation.value!.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _gradientAnimation.value!.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "تمت العملية بواسطة : ",
                          style: TextStyle(fontSize: 15, color: Colors.black87),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "${(user != null) ? user.name : "غير محدد"}",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "الخاصة بالعميل : ",
                          style: TextStyle(fontSize: 15, color: Colors.black87),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          (currentClient != null)
                              ? currentClient.name!
                              : "تم حذف العميل",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade50,
                            Colors.purple.shade50,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: Icon(
                                    currentLog.transactionType.icon(),
                                    color: currentLog.transactionType.color(),
                                    key: ValueKey(currentLog.transactionType),
                                  ),
                                ),
                                const VerticalDivider(),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        currentLog.transactionType.name(),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        fullExpressionArabicDate(
                                            currentLog.createdAt!),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Column(
                                children: [
                                  const Text(
                                    "المبلغ",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    "${currentLog.price} جنيه",
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black54),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 10),
                              Visibility(
                                visible: widget.showAdminControls &&
                                    (SupabaseAuthentication.myUser!.role ==
                                            UserRoles.admin.index ||
                                        SupabaseAuthentication.myUser!.role ==
                                            UserRoles.manager.index),
                                child: Column(
                                  children: [
                                    IconButton(
                                      onPressed: (currentClient != null)
                                          ? () async {
                                              await BackendServices
                                                  .instance.logRepository
                                                  .reverseLog(currentLog,
                                                      currentClient);

                                              await Get.find<FollowController>()
                                                  .updateLogs();
                                            }
                                          : null,
                                      icon: const Icon(
                                        Icons.replay_circle_filled,
                                        color: Colors.blue,
                                      ),
                                      tooltip: "عكس العملية",
                                    ),
                                    IconButton(
                                      onPressed: () async {
                                        showDangerDialog("حذف معاملة",
                                            "تحذير : حذف المعاملة قد يؤدي الي جعل بعض الاموال مجهولة المصدر عليك التأكد انك فعلا تريد حذف تلك المعاملة بدلا من عكسها",
                                            () async {
                                          await BackendServices
                                              .instance.logRepository
                                              .delete(currentLog);

                                          await Get.find<FollowController>()
                                              .updateLogs();
                                        });
                                      },
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      tooltip: "حذف",
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
