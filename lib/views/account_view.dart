import 'dart:math';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/controllers/account_client_info_data.dart';
import 'package:phone_system_app/controllers/account_profit_controller.dart';
import 'package:phone_system_app/controllers/account_view_controller.dart';
import 'package:phone_system_app/models/account.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';
import 'package:phone_system_app/views/account_details.dart';
import 'package:phone_system_app/views/pages/charts_page.dart';
import 'package:phone_system_app/views/pages/table_page.dart';

class AccountsView extends StatelessWidget {
  AccountsView({super.key});
  final controller = Get.put(AccountViewController());

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    double screenWidth = size.width;
    double minWidth = 200;

    return Obx(() {
      final data = controller.getCurrentAccounts();
      
      // Determine if we should use vertical layout
      final bool useVerticalLayout = data.length == 2;

      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          centerTitle: true,
          title: const Text("الاكونتات المتاحة"),
          actions: [
            IconButton(
              tooltip: "تسجيل الخروج",
              onPressed: () async {
                await BackendServices.instance.supabaseAuthentication.signOut();
                html.window.location.reload();
              },
              icon: const Icon(
                Icons.door_back_door,
                color: Colors.red,
              ),
            ),
            IconButton(
              tooltip: "اظهار بينات العملاء",
              onPressed: () {
                Get.to(InfoTablePage());
              },
              icon: const Icon(
                Icons.table_chart,
                color: Colors.blue,
              ),
            ),
          ],
          leading: IconButton(
            onPressed: () {
              Get.to(ChartsPage());
            },
            icon: const Icon(
              FontAwesomeIcons.chartPie,
              color: Colors.red,
            ),
          ),
        ),
        body: (controller.isLoading.value)
            ? Center(child: CircularProgressIndicator())
            : useVerticalLayout
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: data.map((account) {
                        return SizedBox(
                          width: screenWidth * 0.8, // 80% of screen width
                          height: size.height * 0.35, // 35% of screen height
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: AccountCard(
                              width: screenWidth * 0.8,
                              account: account,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  )
                : GridView.builder(
                    itemCount: data.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          max((screenWidth ~/ minWidth != 0) ? screenWidth ~/ minWidth : 1, 2),
                      childAspectRatio: 1.1,
                    ),
                    itemBuilder: (context, index) {
                      double cardWidth = screenWidth / max((screenWidth ~/ minWidth != 0) ? screenWidth ~/ minWidth : 1, 2);
                      return Padding(
                        padding: const EdgeInsets.all(10),
                        child: AccountCard(
                          width: cardWidth,
                          account: data[index],
                        ),
                      );
                    },
                  ),
      );
    });
  }
}

class AccountCard extends StatelessWidget {
  final Account account;
  final double width;
  bool _isNavigating = false; // Track navigation state

  AccountCard({super.key, required this.width, required this.account});

  @override
  Widget build(BuildContext context) {
    final colors = Get.theme.colorScheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 2,
            blurStyle: BlurStyle.outer,
            spreadRadius: 2
          )
        ]
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Stack(
              children: [
                const Positioned.fill(
                  child: Icon(
                    Icons.account_balance,
                    size: 50,
                    color: Colors.grey,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: -5,
                  child: Container(
                    width: width,
                    height: 50,
                    decoration: BoxDecoration(
                      color: colors.background,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      )
                    ),
                    child: Center(
                      child: Text(
                        account.name!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                )
              ],
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(width: 1.5, color: Colors.black87)
              ),
            )
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                overlayColor:
                    MaterialStateProperty.all(Colors.black87.withAlpha(10)),
                focusColor: Colors.green,
                hoverColor: Colors.white,
                onTap: () async {
                  if (_isNavigating) return; // Prevent multiple taps
                  _isNavigating = true; // Set navigating state

                  // Delay the reset of the navigation state to ensure navigation happens first
                  Future.delayed(const Duration(milliseconds: 300), () {
                    _isNavigating = false; // Reset navigating state after the navigation
                  });

                  // Ensure we don't navigate to the same page again
                  if (Get.currentRoute != '/accountDetails') {
                    Get.put(AccountClientInfo(currentAccount: account));
                    final p = Get.put(ProfitController());
                    await p.updateTheProfitByAccount(account);

                    // Navigate to AccountDetails
                    Get.to(AccountDetails(), arguments: account);
                  }
                },
                child:
                    Container(color: Colors.transparent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
