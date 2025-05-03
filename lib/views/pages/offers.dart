import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/controllers/account_client_info_data.dart';
import 'package:phone_system_app/models/client.dart';
import 'package:phone_system_app/models/system.dart';
import 'package:phone_system_app/models/system_type.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';
import 'package:phone_system_app/utils/string_utils.dart';
import 'package:phone_system_app/views/bottom_sheet_dialogs/show_client_info_sheet.dart';
import 'package:phone_system_app/views/client_list_view.dart';
import 'package:phone_system_app/views/pages/all_clinets_page.dart';
import 'package:phone_system_app/views/pages/dues_management.dart';
import 'package:intl/intl.dart';
import 'package:phone_system_app/utils/arabic_normalizer.dart';
import 'package:phone_system_app/repositories/system/supabase_system_repository.dart';

class OfferManagement extends StatelessWidget {
  final controller = Get.find<AccountClientInfo>();

  void _navigateToExpiredSystems(BuildContext context, List<Client> clients) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Ensure clean navigation
      await Get.delete<ExpiredSystemsController>(force: true);

      Get.to(
        () => ExpiredSystemsPage(clients: clients),
        preventDuplicates: true,
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 300),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final q = controller.query.value;

      final printingClients = controller.clientPrintAdded.value;
      // Only show offers that have already expired
      List<Client> clients = controller.clinets.value
          .where((element) =>
              element.expireDate != null &&
              element.expireDate!.isBefore(DateTime.now()) && // Only past dates
              element.expireDate!
                  .isAfter(DateTime.now().subtract(const Duration(days: 10))))
          .toList();

      if (q != "") {
        clients = clients
            .where((element) =>
                element.numbers![0].phoneNumber!.contains(q) ||
                removeSpecialArabicChars(element.name!)
                    .contains(removeSpecialArabicChars(q)))
            .toList();
      }

      final totalCash = (clients.isNotEmpty)
          ? clients
              .map(
                (e) => e.totalCash,
              )
              .reduce(
                (value, element) => value + element,
              )
          : 0;

      final expiredSystemsClients = controller.clinets.value
          .where((client) =>
              client.expireDate != null &&
              client.expireDate!.isBefore(DateTime.now()) && // Only past dates
              client.numbers!
                  .any((number) => number.getExpiredSystems().isNotEmpty))
          .toList();

      // Update the explanatory text
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "العملاء الذين انتهت عروضهم خلال العشرة أيام الماضية فقط",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                CustomDataColumn(
                  title: "العدد",
                  value: "${clients.length}",
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _navigateToExpiredSystems(context, expiredSystemsClients);
                  },
                  icon: Icon(Icons.card_giftcard_rounded,
                      color: Colors.black), // Icon added here
                  label: Text(
                    "العروض المطلوبة",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
          CutsomToolBar(
              controller: controller, printingClients: printingClients),
          Expanded(
              child: ClientListView(
            data: clients,
            isLoading: controller.isLoading.value,
            query: controller.query.value,
          ))
        ],
      );
    });
  }
}

class ExpiredSystemsController extends GetxController {
  final RxString searchQuery = ''.obs;
  final RxList<Client> filteredClients = <Client>[].obs;
  final RxInt totalExpiredSystems = 0.obs;
  List<Client>? allClients = <Client>[].obs;

  Future<void> fetchClients() async {
    var clients = await BackendServices.instance.clientRepository
        .getAllClientsByAccount(Get.put(AccountClientInfo.to).currentAccount);

    // Filter expired clients
    filteredClients.value = clients
        .where((client) =>
            client.expireDate != null &&
            client.expireDate!.isBefore(DateTime.now()) &&
            client.numbers!
                .any((number) => number.getExpiredSystems().isNotEmpty))
        .toList();

    allClients = filteredClients.value;
    _updateTotalExpiredSystems();
  }

  ExpiredSystemsController() {
    // filteredClients.value = allClients;
    fetchClients();
  }

  void initializeWithClients(List<Client> clients) {
    // Filter expired clients once and store in allClients
    allClients = clients
        .where((client) =>
            client.expireDate != null &&
            client.expireDate!.isBefore(DateTime.now()) &&
            client.numbers!
                .any((number) => number.getExpiredSystems().isNotEmpty))
        .toList();

    // Set initial filtered clients
    filteredClients.value = allClients!;
    _updateTotalExpiredSystems();
  }

  void _updateTotalExpiredSystems() {
    totalExpiredSystems.value = filteredClients.fold<int>(
      0,
      (sum, client) =>
          sum +
          client.numbers!.fold<int>(
            0,
            (innerSum, number) => innerSum + number.getExpiredSystems().length,
          ),
    );
  }

  void updateSearch(String query) {
    searchQuery.value = query;
    if (query.isEmpty) {
      filteredClients.value = allClients!;
    } else {
      final normalized = removeSpecialArabicChars(query.toLowerCase());
      filteredClients.value = allClients!
          .where((client) =>
              removeSpecialArabicChars(client.name!.toLowerCase())
                  .contains(normalized) ||
              client.numbers!.any((number) =>
                  number.phoneNumber != null &&
                  number.phoneNumber!.contains(normalized)))
          .toList();
    }
    _updateTotalExpiredSystems();
  }
}

class ExpiredSystemsPage extends StatelessWidget {
  final List<Client> clients;
  final ExpiredSystemsController controller;

  ExpiredSystemsPage({required this.clients})
      : controller = Get.put(ExpiredSystemsController()) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initializeWithClients(clients);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: WillPopScope(
        onWillPop: () async {
          if (Navigator.canPop(context)) {
            await Get.delete<ExpiredSystemsController>(force: true);
            Navigator.pop(context);
          }
          return false;
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 1,
            iconTheme: IconThemeData(color: Colors.black),
            title: Text(
              "العروض المطلوبة",
              style: TextStyle(color: Colors.black),
            ),
          ),
          body: SafeArea(
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      color: Colors.white,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              onChanged: controller.updateSearch,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.grey[200],
                                labelText: 'بحث',
                                prefixIcon: Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Obx(() => Text(
                                  'عدد العروض المنتهية: ${controller.totalExpiredSystems}',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      child: Obx(() => ListView.builder(
                            itemCount: controller.filteredClients.length,
                            itemBuilder: (context, index) {
                              final client = controller.filteredClients[index];
                              return _buildClientCard(client, context);
                            },
                          )),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClientCard(Client client, BuildContext context) {
    // Add BuildContext parameter here
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        color: Colors.white,
        elevation: 8,
        shadowColor: Colors.blue.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.blue.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: ExpansionTile(
          backgroundColor: Colors.white,
          collapsedBackgroundColor: Colors.white,
          leading: CircleAvatar(
            backgroundColor: Colors.blue.withOpacity(0.1),
            radius: 25,
            child: Icon(
              Icons.person,
              color: Colors.blue,
              size: 30,
            ),
          ),
          title: Text(
            client.name!,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'عدد الأنظمة المنتهية: ${client.numbers!.fold<int>(0, (sum, number) => sum + number.getExpiredSystems().length)}',
                style: TextStyle(color: Colors.black),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'تاريخ المتابعة: ${(client.expireDate != null && client.expireDate!.isBefore(DateTime.now())) ? fullExpressionArabicDate(client.expireDate!) : "لا يوجد"}',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: IconButton(
            icon: Icon(Icons.edit_calendar, size: 20),
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: client.expireDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                try {
                  // Update in Supabase
                  await BackendServices.instance.clientRepository
                      .updateClientInSupabase(
                          client.id.toString(),
                          {'expire_date': picked.toIso8601String()}
                              as Map<String, Object>);

                  // Update local state after successful Supabase update
                  await controller.fetchClients();

                  Get.snackbar(
                    'تم التحديث',
                    'تم تحديث تاريخ المتابعة بنجاح',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                } catch (e) {
                  Get.snackbar(
                    'خطأ',
                    'حدث خطأ أثناء تحديث التاريخ',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red[100],
                  );
                  print('Error updating expire date: $e');
                }
              }
            },
          ),
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(15),
              ),
              margin: EdgeInsets.all(12),
              child: Column(
                children: client.numbers!.map((number) {
                  final systems = number.systems ?? [];
                  if (systems.isEmpty) return SizedBox.shrink();

                  return Container(
                    margin: EdgeInsets.all(8),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.phone_android, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              number.phoneNumber ?? '',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.blue,
                              ),
                            ),
                            Spacer(),
                            IconButton(
                              icon: Icon(Icons.copy, color: Colors.blue),
                              onPressed: () {
                                if (number.phoneNumber != null) {
                                  Clipboard.setData(
                                      ClipboardData(text: number.phoneNumber!));
                                  Get.snackbar(
                                    'تم النسخ',
                                    'تم نسخ الرقم بنجاح',
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                        Divider(height: 20),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: systems.map((system) {
                            if (system.type!.category ==
                                SystemCategory.mobileInternet) {
                              if (system.createdAt != null) {
                                final collectionDay =
                                    AccountClientInfo.to.currentAccount.day;
                                final nextCollection = DateTime(
                                  system.createdAt!.month == 12
                                      ? system.createdAt!.year + 1
                                      : system.createdAt!.year,
                                  system.createdAt!.month == 12
                                      ? 1
                                      : system.createdAt!.month + 1,
                                  collectionDay,
                                );
                                if (DateTime.now().isAfter(nextCollection)) {
                                  return const SizedBox.shrink();
                                }
                              }
                            }

                            return Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    system.type!.name!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.edit, size: 20),
                                    onPressed: () =>
                                        _showEditSystemDialog(system),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSystemDialog(System system) {
    showEditSystemDialog(system); // Use the shared dialog function
  }
}
