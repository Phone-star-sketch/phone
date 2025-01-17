import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/controllers/account_client_info_data.dart';
import 'package:phone_system_app/models/client.dart';
import 'package:phone_system_app/utils/string_utils.dart';
import 'package:phone_system_app/views/client_list_view.dart';
import 'package:phone_system_app/views/pages/all_clinets_page.dart';
import 'package:phone_system_app/views/pages/dues_management.dart';

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
                )
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
