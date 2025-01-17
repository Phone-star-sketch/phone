import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/controllers/account_profit_controller.dart';
import 'package:phone_system_app/controllers/money_display_loading.dart';
import 'package:phone_system_app/models/profit.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';
import 'package:phone_system_app/views/bottom_sheet_dialogs/show_client_info_sheet.dart';

class ProfitMeasure {
  double totalMoneyCollected;
  double totalMoneyDebt;
  double totalExpectedMoneyToBeCollected;
  ProfitMeasure({
    required this.totalMoneyCollected,
    required this.totalMoneyDebt,
    required this.totalExpectedMoneyToBeCollected,
  });
}

class ProfitManagement extends StatelessWidget {
  final profitController = Get.put(ProfitController());
  final loaders = Get.put(Loaders());
  List<int> years = List<int>.generate(
    10,
    (index) {
      return 2024 + index;
    },
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Obx(
        () => (Loaders.to.typesIsLoading.value)
            ? Center(
                child: CustomIndicator(
                  title: "يتم تحميل الارباح",
                ),
              )
            : Container(
                decoration: BoxDecoration(border: Border.all(width: 1)),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomDropDown(
                              onSelected:
                                  profitController.onMonthOrYearSelected,
                              name: "الشهر",
                              controller: profitController.monthController,
                              ddEntries: profitController.months.entries.map(
                                (e) {
                                  return DropdownMenuEntry(
                                      value: e.key, label: e.value);
                                },
                              ).toList(),
                            ),
                            CustomDropDown(
                              onSelected:
                                  profitController.onMonthOrYearSelected,
                              name: "السنة",
                              controller: profitController.yearController,
                              ddEntries: years.map(
                                (e) {
                                  return DropdownMenuEntry(
                                      value: e, label: e.toString());
                                },
                              ).toList(),
                            ),
                          ],
                        ),
                        CustomInputField(
                          title: "المبلغ الكلي من الشركة",
                          controller: profitController.totalIncomeController,
                        ),
                        CustomInputField(
                          title: "خصم",
                          controller: profitController.discountController,
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        SizedBox(
                          width: 200,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red),
                            onPressed: (Loaders.to.profitLoader.value)
                                ? null
                                : () async {
                                    final profit =
                                        await profitController.onStoreClick();
                                    final monthName =
                                        profitController.monthController.text;
                                    final month =
                                        profitController.monthsToInt[monthName];
                                    final year = int.parse(
                                        profitController.yearController.text);

                                    Get.defaultDialog(
                                        backgroundColor: Colors.white,
                                        title: "حسابات الربح لشهر $monthName",
                                        content: Container(
                                          width: 500,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.6,
                                          margin: const EdgeInsets.all(10),
                                          padding: const EdgeInsets.all(30),
                                          child: ListView(
                                            children: [
                                              DataRow(
                                                title: "المبلغ المتوقع جمعه :",
                                                value: profit
                                                    .expectedToBeCollected,
                                              ),
                                              const Divider(),
                                              DataRow(
                                                title:
                                                    "حساب الشركة قبل الخصم :",
                                                value: profit.totalIncome,
                                              ),
                                              const Divider(),
                                              DataRow(
                                                title:
                                                    "حساب الشركة بعد الخصم :",
                                                value: profit.totalIncome -
                                                    profit.totalIncome *
                                                        profit.discount,
                                              ),
                                              const Divider(),
                                              DataRow(
                                                title: "(صافي الربح):",
                                                value: profit
                                                        .expectedToBeCollected -
                                                    (profit.totalIncome -
                                                        profit.totalIncome *
                                                            profit.discount),
                                              ),
                                            ],
                                          ),
                                        ));
                                  },
                            child: const Text("تسجيل و حساب الربح"),
                          ),
                        ),
                        (Loaders.to.profitLoader.value)
                            ? CustomIndicator(
                                title: "برجاء الانتظار يتم حساب الربح ...",
                              )
                            : const SizedBox()
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class DataRow extends StatelessWidget {
  DataRow(
      {super.key,
      required this.value,
      required this.title,
      this.end = "جنيهاً"});

  String title;
  double value;
  String end;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          "$value $end ",
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class CustomDropDown extends StatelessWidget {
  CustomDropDown(
      {super.key,
      required this.ddEntries,
      required this.name,
      required this.controller,
      required this.onSelected});

  final List<DropdownMenuEntry> ddEntries;
  final TextEditingController controller;
  final Function(dynamic) onSelected;
  String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(
            height: 10,
          ),
          DropdownMenu(
            menuHeight: 200,
            requestFocusOnTap: true,
            enableSearch: true,
            dropdownMenuEntries: ddEntries,
            controller: controller,
            onSelected: onSelected,
          ),
        ],
      ),
    );
  }
}

class CustomInputField extends StatelessWidget {
  String title;
  TextEditingController controller;

  CustomInputField({
    super.key,
    required this.title,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(width: 1)),
      margin: const EdgeInsets.all(10),
      child: Column(
        children: [
          Text(title),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: 200,
              child: TextField(
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),

                  //FilteringTextInputFormatter.digitsOnly
                ],
                decoration: const InputDecoration(
                  focusColor: Colors.red,
                  border: OutlineInputBorder(gapPadding: 10),
                ),
                controller: controller,
              ),
            ),
          )
        ],
      ),
    );
  }
}
