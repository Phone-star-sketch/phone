import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/components/chart_display.dart';
import 'package:phone_system_app/controllers/account_client_info_data.dart';
import 'package:phone_system_app/controllers/account_view_controller.dart';
import 'package:phone_system_app/controllers/client_systems_controller.dart';
import 'package:phone_system_app/controllers/system_types_controller.dart';
import 'package:phone_system_app/models/account.dart';
import 'package:phone_system_app/models/system_type.dart';

class ChartsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.red,
          title: const Text("الإحصائيات"),
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.subscriptions_rounded),
                text: "إحصائيات الباقات",
              ),
              Tab(
                icon: Icon(Icons.person),
                text: "إحصائيات الاكونتات",
              ),
            ],
          ),
        ),
        body: TabBarView(children: [
          Obx(() {
            Get.put(SystemTypeController());
            Get.put(ClientSystemController());
            List<SystemType> systemTypes = SystemTypeController.types;
            List<int> typeIds = ClientSystemController.allTypesId
                .map((map) => int.parse(map['type_id'].toString()))
                .toList();
            List<int> systemValues = systemTypes.map((systemType) {
              return typeIds.where((typeId) => typeId == systemType.id).length;
            }).toList();
            return Row(
              children: [
                Expanded(
                    child: systemTypes.isEmpty
                        ? const Center(
                            child: Text('loading data...'),
                          )
                        : ViewChart(
                            systemTypes
                                .map((systemType) => systemType.name!)
                                .toList(),
                            systemValues)),
              ],
            );
          }),
          Obx(() {
            Get.put(AccountViewController());
            Get.put(AccountClientInfo(currentAccount: Account(id: -1)));

            List<Account> accounts = AccountViewController.accounts;
            List<Map<String, dynamic>> allclientaccounts =
                AccountClientInfo.allClients;
            List<int> accountClients = [];
            for (var account in accounts) {
              int currentValue = allclientaccounts
                  .where((map) =>
                      int.parse(map["account_id"].toString()) == account.id)
                  .length;
              accountClients.add(currentValue == 0 ? 0 : currentValue);
            }
            return Row(
              children: [
                Expanded(
                    child: accountClients.isEmpty
                        ? const Center(
                            child: Text('loading data...'),
                          )
                        : ViewChart(
                            accounts.map((account) => account.name!).toList(),
                            accountClients)),
              ],
            );
          })
        ]),
      ),
    );
  }
}
