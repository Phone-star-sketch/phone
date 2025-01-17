import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/controllers/account_client_info_data.dart';
import 'package:phone_system_app/controllers/client_bottom_sheet_controller.dart';
import 'package:phone_system_app/models/client.dart';
import 'package:phone_system_app/models/phone_number.dart';
import 'package:phone_system_app/services/backend/auth.dart';
import 'package:phone_system_app/widget_models/clientCreationModelSheet.dart';
import 'bottom_sheet_dialogs/show_client_info_sheet.dart';
import 'package:phone_system_app/utils/string_utils.dart';
import 'package:phone_system_app/utils/arabic_normalizer.dart'; // Add this line

class ClientListView extends StatelessWidget {
  String? query;
  List<Client> data;
  bool isLoading;

  final accountController = Get.find<AccountClientInfo>();
  final scrollController = ScrollController();

  ClientListView({
    super.key,
    this.query = "",
    required this.data,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;

    // Filter clients based on the query
    List<Client> filteredData =
        ClientFilterUtils.filterClients(query ?? '', data);

    // Debug logs to verify filtering
    print("Query: $query");
    print(
        "Filtered Data: ${filteredData.map((client) => client.name).toList()}");

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        child: const Icon(Icons.person_add_alt),
        onPressed: () async {
          await clientEditModelSheet(context);
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const ClientListHeader(),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredData.isEmpty
                      ? EmptyStateWidget(query: query)
                      : GridView.builder(
                          controller: scrollController,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: screenWidth > 1200
                                ? 3
                                : (screenWidth > 800 ? 2 : 1),
                            childAspectRatio: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: filteredData.length,
                          itemBuilder: (context, index) => ClientCard(
                            client: filteredData[index],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class ClientListHeader extends StatelessWidget {
  const ClientListHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('الإسم', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('رقم الهاتف', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('المطلوب سدادة',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class ClientCard extends StatelessWidget {
  final Client client;

  ClientCard({Key? key, required this.client}) : super(key: key);

  final AccountClientInfo controller = Get.find<AccountClientInfo>();

  Color getWarningColorState(double required) {
    if (required >= 0 && required < 10) {
      return Colors.yellow;
    } else if (required > 10) {
      return Colors.green;
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientCash = client.totalCash;
    final requiredCash = (clientCash >= 0) ? 0 : -clientCash;
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final controller = Get.put(ClientBottomSheetController());
          controller.setClient(client);
          await showClientInfoSheet(context, client);
          Get.delete<ClientBottomSheetController>(force: true);
        },
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          client.name ?? '',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (SupabaseAuthentication.myUser!.role !=
                          UserRoles.assistant.index)
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.red),
                          onPressed: () async {
                            await clientEditModelSheet(context, client: client);
                          },
                        ),
                    ],
                  ),
                  Text(
                    client.numbers?[0].phoneNumber ?? '',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: getWarningColorState(clientCash.toDouble()),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "$requiredCash جنيهاً",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Obx(() => controller.enableMulipleClientPrint.value
                ? Positioned(
                    right: 8,
                    bottom: 8,
                    child: IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: const CircleBorder(),
                      ),
                      icon: const Icon(Icons.add_card_rounded,
                          color: Colors.white),
                      onPressed: () {
                        if (controller.clientPrintAdded.firstWhereOrNull(
                                (row) => row.id == client.id) ==
                            null) {
                          controller.clientPrintAdded.add(client);
                          Get.showSnackbar(GetSnackBar(
                            backgroundColor: Colors.blue,
                            duration: const Duration(seconds: 1),
                            title: "رسالة تأكيد",
                            message: 'تم إضافة العميل ${client.name}',
                          ));
                        }
                      },
                    ),
                  )
                : const SizedBox()),
          ],
        ),
      ),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final String? query;

  const EmptyStateWidget({Key? key, this.query}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Opacity(
            opacity: 0.1,
            child: Image.asset(
              'assets/images/v_logo_blank.png',
              height: 2000,
              fit: BoxFit.contain,
            ),
          ),
        ),
        Center(
          child: Container(
            width: 200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Opacity(
                  opacity: 0.6,
                  child: SvgPicture.asset(
                    "assets/images/zi_search_logo.svg",
                    width: 200,
                    fit: BoxFit.contain,
                  ),
                ),
                Text(
                  (query == null || query!.isEmpty)
                      ? "أبحث عن رقم او أسم"
                      : "لا يوجد نتائج لهذا البحث",
                  style: const TextStyle(color: Colors.black),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ClientFilterUtils {
  static List<Client> filterClients(String query, List<Client> clients) {
    final normalizedQuery = normalizeArabicText(query);

    return clients.where((client) {
      String normalizedName = normalizeArabicText(client.name ?? '');
      String normalizedPhone = normalizeArabicText(
          (client.numbers?.isNotEmpty == true
                  ? client.numbers![0].phoneNumber ?? ''
                  : '')
              .replaceAll(" ", ""));

      // Debug logs to verify normalization
      print("Normalized Query: $normalizedQuery");
      print("Normalized Name: $normalizedName");
      print("Normalized Phone: $normalizedPhone");

      return normalizedName.contains(normalizedQuery) ||
          normalizedPhone.contains(normalizedQuery);
    }).toList();
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
