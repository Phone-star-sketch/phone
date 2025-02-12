import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/controllers/account_client_info_data.dart';
import 'package:phone_system_app/models/client.dart';
import 'package:phone_system_app/utils/string_utils.dart';
import 'package:phone_system_app/views/client_list_view.dart';
import 'package:phone_system_app/views/pages/all_clinets_page.dart';

class DuesManagement extends StatelessWidget {
  final controller = Get.find<AccountClientInfo>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final q = controller.query.value;

      final printingClients = controller.clientPrintAdded.value;
      List<Client> clients = controller.clinets.value
          .where(
            (element) => element.totalCash < 0,
          )
          .toList();

      if (q.isNotEmpty) {
        clients = clients.where((element) {
          final hasMatchingPhone = element.numbers?.isNotEmpty == true &&
              element.numbers![0].phoneNumber?.contains(q) == true;

          final hasMatchingName = element.name != null &&
              removeSpecialArabicChars(element.name!)
                  .contains(removeSpecialArabicChars(q));

          return hasMatchingPhone || hasMatchingName;
        }).toList();
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
            height: MediaQuery.of(context).size.height * 0.10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                CustomDataColumn(
                  title: "الدين الكلي",
                  value: "${totalCash * -1}",
                  end: "ج",
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

class CustomDataColumn extends StatelessWidget {
  CustomDataColumn(
      {super.key, required this.title, required this.value, this.end = ""});
  String title;
  String value;
  String end;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        Text("$value $end")
      ],
    );
  }
}
