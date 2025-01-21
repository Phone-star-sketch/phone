import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:phone_system_app/controllers/account_client_info_data.dart';
import 'package:phone_system_app/controllers/client_bottom_sheet_controller.dart';
import 'package:phone_system_app/controllers/money_display_loading.dart';
import 'package:phone_system_app/models/client.dart';
import 'package:phone_system_app/models/log.dart';
import 'package:phone_system_app/models/user.dart';
import 'package:phone_system_app/services/backend/auth.dart';
import 'package:phone_system_app/services/backend/backend_service_type.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';
import 'package:phone_system_app/utils/string_utils.dart';
import 'package:phone_system_app/views/bottom_sheet_dialogs/show_client_info_sheet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart';

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
              print('🔴 Realtime update received: ${payload.eventType} at ${DateTime.now()}');
              print('🔴 Changed data: ${payload.newRecord}');
              
              // Update timestamp
              lastUpdateTime.value = DateFormat.jm('ar').format(DateTime.now());
              
              // Show update notification
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
      final dataAdd = await BackendServices.instance.logRepository
          .getLogsByMatchMapQuery({
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
      final firstClient = AccountClientInfo.to.clinets.firstWhereOrNull((c) => c.id != null);
      
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
    return Obx(() {
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
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (SupabaseAuthentication.myUser!.role == UserRoles.admin.index)
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
                            ? Icons.wifi : Icons.wifi_off,
                          color: controller.connectionStatus.value == 'متصل' 
                            ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        SizedBox(width: 4),
                        Text(
                          controller.connectionStatus.value,
                          style: TextStyle(fontSize: 12),
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
                  child: ListView.separated(
                    separatorBuilder: (context, index) => const Divider(),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: (list[index].client != null)
                            ? () async {
                                final client = list[index].client;
                                final controller =
                                    Get.put(ClientBottomSheetController());
                                controller.setClient(client!);
                                await showClientInfoSheet(context, client);
                                Get.delete<ClientBottomSheetController>(
                                    force: true);
                              }
                            : null,
                        child: LogWithUserCardWidget(
                          logWidthUser: list[index],
                        ),
                      );
                    },
                  ),
                ),
        ],
      );
    });
  }
}

class LogWithUserCardWidget extends StatelessWidget {
  final controller = Get.put(FollowController());

  LogWithUserCardWidget({
    super.key,
    required this.logWidthUser,
  });
  final LogWidthUser logWidthUser;

  @override
  Widget build(BuildContext context) {
    final Client? currentClient = logWidthUser.client;
    final Log currentLog = logWidthUser.log;
    final AppUser? user = logWidthUser.user;

    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.red[100], borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "تمت العملية بواسطة : ",
                  style: TextStyle(fontSize: 15),
                ),
              ),
              Expanded(
                child: Text(
                  "${(user != null) ? user.name : "غير محدد"}",
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
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
                  style: TextStyle(fontSize: 15),
                ),
              ),
              Expanded(
                child: Text(
                  (currentClient != null)
                      ? currentClient.name!
                      : "تم حذف العميل",
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(),
          Card(
            child: Container(
              padding: const EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          currentLog.transactionType.icon(),
                          color: currentLog.transactionType.color(),
                        ),
                        const VerticalDivider(),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentLog.transactionType.name(),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                fullExpressionArabicDate(currentLog.createdAt!),
                                style: const TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
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
                            ),
                          ),
                          Text(
                            "${currentLog.price} جنيه",
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Visibility(
                        visible: SupabaseAuthentication.myUser!.role ==
                                UserRoles.admin.index ||
                            SupabaseAuthentication.myUser!.role ==
                                UserRoles.manager.index,
                        child: Column(
                          children: [
                            IconButton(
                              onPressed: (currentClient != null)
                                  ? () async {
                                      await BackendServices
                                          .instance.logRepository
                                          .reverseLog(
                                              currentLog, currentClient);

                                      await controller.updateLogs();
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
                                  await BackendServices.instance.logRepository
                                      .delete(currentLog);

                                  await controller.updateLogs();
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
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}