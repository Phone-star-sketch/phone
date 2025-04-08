import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
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
import 'package:phone_system_app/utils/string_utils.dart';
import 'package:phone_system_app/views/bottom_sheet_dialogs/show_client_info_sheet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:phone_system_app/services/transaction_notification_service.dart';

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

class FollowController extends GetxController {
  RxList<LogWidthUser> logs = <LogWidthUser>[].obs;
  RealtimeChannel? _subscription;
  RxString connectionStatus = 'غير متصل'.obs;
  RxString lastUpdateTime = ''.obs;

  @override
  void onInit() async {
    super.onInit();
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

      // Initialize notification service if not already initialized
      if (!kIsWeb) {
        await TransactionNotificationService.instance.initialize();
      }
    } catch (e) {
      print('Error initializing data: $e');
    }
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
              print('🔴 Changed data: ${payload.newRecord}');

              // Update timestamp
              lastUpdateTime.value = DateFormat.jm('ar').format(DateTime.now());

              // Get the new log data
              final newLog = Log.fromJson(payload.newRecord);

              // Create LogWidthUser to check if it's from assistant
              final logWithUser = LogWidthUser(log: newLog);

              // Check if the transaction is from المساعد and current user is المدير
              final String userName =
                  logWithUser.user?.name?.toLowerCase() ?? '';
              final bool isManager = SupabaseAuthentication.myUser?.role ==
                      UserRoles.admin.index ||
                  SupabaseAuthentication.myUser?.role ==
                      UserRoles.manager.index;

              if (userName.contains('المساعد') && isManager) {
                // Show notification for assistant transactions only to manager
                await TransactionNotificationService.instance
                    .showTransactionNotification(logWithUser);
              }

              // Show update notification in app
              Get.snackbar(
                'تحديث مباشر',
                'تم استلام تحديث جديد',
                backgroundColor: Colors.green.withOpacity(0.1),
                duration: Duration(seconds: 2),
              );

              await AccountClientInfo.to.fetchClients();
              await updateLogs();
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
      print("Real-time update: Found ${logs.length} logs");
      Loaders.to.followLoading.value = false;
    } catch (e) {
      print("Real-time update error: $e");
      Get.snackbar("مشكلة اثناء التحميل", e.toString());
      Loaders.to.followLoading.value = false;
    }
  }

  Future<void> insertDummyLog() async {
    try {
      final firstClient =
          AccountClientInfo.to.clinets.firstWhereOrNull((c) => c.id != null);

      if (firstClient == null) {
        Get.snackbar('خطأ', 'لا يوجد عملاء متاحين لإجراء الاختبار');
        return;
      }

      final supabase = Supabase.instance.client;

      Get.snackbar(
        'اختبار',
        'تم إضافة معاملة تجريبية',
        backgroundColor: Colors.blue.withOpacity(0.1),
      );

      // Refresh logs after insertion
      await updateLogs();
    } catch (e) {
      print('🔴 Error inserting dummy log: $e');
      Get.snackbar('خطأ', 'فشل في إضافة البيانات التجريبية: $e');
    }
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
                Tab(text: 'المدير'),
                Tab(text: 'المساعد'),
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
    // Filter logs for manager (كابتن/اسلام النني)
    final managerLogs = list.where((logWithUser) {
      final userName = logWithUser.user?.name?.toLowerCase() ?? '';
      return userName.contains('كابتن') || userName.contains('اسلام النني');
    }).toList();

    return ListView.separated(
      separatorBuilder: (context, index) => const Divider(),
      itemCount: managerLogs.length,
      itemBuilder: (context, index) {
        return InkWell(
          onTap: (managerLogs[index].client != null)
              ? () async {
                  final client = managerLogs[index].client;
                  final controller = Get.put(ClientBottomSheetController());
                  controller.setClient(client!);
                  await showClientInfoSheet(context, client);
                  Get.delete<ClientBottomSheetController>(force: true);
                }
              : null,
          child: LogWithUserCardWidget(
            logWidthUser: managerLogs[index],
            showAdminControls: true,
          ),
        );
      },
    );
  }

  Widget _buildAssistantView(List<LogWidthUser> list, BuildContext context) {
    // Filter logs for assistant (المساعد)
    final assistantLogs = list.where((logWithUser) {
      final userName = logWithUser.user?.name?.toLowerCase() ?? '';
      return userName.contains('المساعد');
    }).toList();

    return ListView.separated(
      separatorBuilder: (context, index) => const Divider(),
      itemCount: assistantLogs.length,
      itemBuilder: (context, index) {
        return InkWell(
          onTap: (assistantLogs[index].client != null)
              ? () async {
                  final client = assistantLogs[index].client;
                  final controller = Get.put(ClientBottomSheetController());
                  controller.setClient(client!);
                  await showClientInfoSheet(context, client);
                  Get.delete<ClientBottomSheetController>(force: true);
                }
              : null,
          child: LogWithUserCardWidget(
            logWidthUser: assistantLogs[index],
            showAdminControls: false,
          ),
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
