import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/components/chart_display.dart';
import 'package:phone_system_app/controllers/account_client_info_data.dart';
import 'package:phone_system_app/controllers/account_view_controller.dart';
import 'package:phone_system_app/controllers/client_systems_controller.dart';
import 'package:phone_system_app/controllers/system_types_controller.dart';
import 'package:phone_system_app/models/account.dart';
import 'package:phone_system_app/models/system_type.dart';

class ChartsPage extends StatefulWidget {
  const ChartsPage({Key? key}) : super(key: key);

  @override
  State<ChartsPage> createState() => _ChartsPageState();
}

class _ChartsPageState extends State<ChartsPage> {
  @override
  void initState() {
    super.initState();
    // Initialize controllers in order
    Get.put(AccountViewController());
    Get.put(SystemTypeController());
    Get.put(ClientSystemController());

    // Initialize AccountClientInfo and fetch data immediately
    if (!Get.isRegistered<AccountClientInfo>()) {
      final accountInfo = AccountClientInfo(currentAccount: Account(id: -1));
      Get.put(accountInfo);
      // Fetch data after widget is built
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await accountInfo.getAllClients();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor:  const Color(0xFF00BFFF),
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
            final accounts = AccountViewController.accounts;
            final allclientaccounts = AccountClientInfo.allClients;

            print('Building chart with:');
            print('Accounts count: ${accounts.length}');
            print('Client accounts data: $allclientaccounts');

            if (accounts.isEmpty || allclientaccounts.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            List<int> accountClients = accounts.map((account) {
              final count = allclientaccounts
                  .where((client) =>
                      client["account_id"].toString() == account.id.toString())
                  .length;
              print('Account ${account.name} (${account.id}): $count clients');
              return count;
            }).toList();

            return Row(
              children: [
                Expanded(
                  child: ViewChart(
                    accounts.map((account) => account.name!).toList(),
                    accountClients,
                  ),
                ),
              ],
            );
          })
        ]),
      ),
    );
  }
}
