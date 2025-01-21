import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/controllers/account_client_info_data.dart';
import 'package:phone_system_app/models/client.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';
import 'package:phone_system_app/utils/string_utils.dart';
import 'package:phone_system_app/views/client_list_view.dart';
import 'package:phone_system_app/views/pages/all_clinets_page.dart';
import 'package:phone_system_app/views/pages/dues_management.dart';
import 'package:intl/intl.dart';
import 'package:phone_system_app/utils/arabic_normalizer.dart';

class OfferManagement extends StatelessWidget {
  final controller = Get.find<AccountClientInfo>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final q = controller.query.value;

      final printingClients = controller.clientPrintAdded.value;
      List<Client> clients = controller.clinets.value
          .where((element) =>
              element.expireDate != null &&
              element.expireDate!
                  .isBefore(DateTime.now().add(const Duration(days: 7))) &&
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
          .where((client) => client.numbers!
              .any((number) => number.getExpiredSystems().isNotEmpty))
          .toList();

      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "سوف تنتهي عروض العملاء المدرج اسمائهم \n${fullExpressionArabicDate(DateTime.now().add(const Duration(days: 7)))}"
                    "\n أو أنتهت عروضهم منذ 10 ايام من تاريخ اليوم",
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
                    Get.to(() =>
                        ExpiredSystemsPage(clients: expiredSystemsClients));
                  },
                  icon: Icon(Icons.card_giftcard_rounded, color: Colors.black), // Icon added here
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
    filteredClients.value = await BackendServices.instance.clientRepository
        .getAllClientsByAccount(Get.put(AccountClientInfo.to).currentAccount);
    filteredClients.value = filteredClients
        .where((client) => client.numbers!
            .any((number) => number.getExpiredSystems().isNotEmpty))
        .toList();
    allClients = filteredClients.value;
    _updateTotalExpiredSystems();
  }

  ExpiredSystemsController() {
    // filteredClients.value = allClients;
    fetchClients();
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
  final controller;

  ExpiredSystemsPage({required this.clients})
      : controller = Get.put(ExpiredSystemsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("العروض المطلوبة"),
        automaticallyImplyLeading: false, // Ensure no back button is shown
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: controller.updateSearch,
                    decoration: InputDecoration(
                      labelText: 'بحث',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Obx(() => Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'عدد العروض المنتهية: ${controller.totalExpiredSystems}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )),
              ],
            ),
          ),
          Expanded(
            child: Obx(() => ListView.builder(
                  itemCount: controller.filteredClients.length,
                  itemBuilder: (context, index) {
                    final client = controller.filteredClients[index];
                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              client.name!,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 5),
                            ...client.numbers!.map((number) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'رقم الهاتف: ${number.phoneNumber}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  ...number.getExpiredSystems().map((system) {
                                    final formattedDate =
                                        DateFormat.yMMMMd('ar')
                                            .format(system.endDate!);
                                    return Text(
                                      'النظام: ${system.name}, انتهى في: $formattedDate',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.red,
                                      ),
                                    );
                                  }).toList(),
                                ],
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    );
                  },
                )),
          ),
        ],
      ),
    );
  }
}

String normalizeArabicText(String text) {
  // Remove all special characters and spaces
  text = text.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '');

  // Normalize Arabic characters
  text = text
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي')
      .replaceAll('ؤ', 'و')
      .replaceAll('ئ', 'ي');

  return text.trim().toLowerCase();
}