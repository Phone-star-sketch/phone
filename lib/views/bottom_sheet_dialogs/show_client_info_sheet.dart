import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:get/get_core/get_core.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:phone_system_app/components/money_display.dart';
import 'package:phone_system_app/controllers/account_client_info_data.dart';
import 'package:phone_system_app/controllers/client_bottom_sheet_controller.dart';
import 'package:phone_system_app/controllers/money_display_loading.dart';
import 'package:phone_system_app/models/client.dart';
import 'package:phone_system_app/models/log.dart';
import 'package:phone_system_app/models/system_type.dart';
import 'package:phone_system_app/services/backend/auth.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';
import 'package:phone_system_app/utils/string_utils.dart';
import 'package:phone_system_app/views/client_list_view.dart';
import 'package:phone_system_app/views/print_clients_receipts.dart';

Future showClientInfoSheet(
  BuildContext context,
  Client client,
) async {
  final colors = Get.theme.colorScheme;
  double width = MediaQuery.of(context).size.width;
  double height = MediaQuery.of(context).size.height;

  return showModalBottomSheet(
      backgroundColor: Colors.white,
      enableDrag: true,
      showDragHandle: true,
      isScrollControlled: true,
      barrierLabel: "بيانات العميل",
      constraints: BoxConstraints.expand(
        width: min(width, 800),
      ),
      context: context,
      builder: (context) {
        return ClientDataWidget(
          colors: colors,
          height: height,
          client: client,
        );
      });
}

Future<void> showDangerDialog(
    String title, String message, Function() action) async {
  await Get.defaultDialog(
      backgroundColor: Colors.white,
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(
            shape: const StadiumBorder(),
            backgroundColor: Colors.red[900],
            padding: const EdgeInsets.all(10)),
        onPressed: () async {
          await action();
          Get.back();
        },
        child:
            const Text("تأكيد", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      title: title,
      content: Center(child: Text(message)));
}

class ClientDataWidget extends StatelessWidget {
  final clientController = Get.find<ClientBottomSheetController>();

  ClientDataWidget({
    super.key,
    required this.colors,
    required this.height,
    required this.client,
  });

  final ColorScheme colors;
  final double height;
  final Client client;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    double screenWidth = size.width;
    double minWidth = 450;

    int crossAxisCount =
        max((screenWidth ~/ minWidth != 0) ? screenWidth ~/ minWidth : 1, 2);
    return Obx(() {
      final client = clientController.getClient();
      final systems = clientController.getClientSystems();
      var logs = clientController.getClientLogs()
        ..sort(
          (a, b) {
            return (a.createdAt!.isAfter(b.createdAt!)) ? -1 : 1;
          },
        );

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            const Column(
              children: [
                Text(
                  'بيانات العميل',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Divider(),
              ],
            ),
            Align(
              alignment: Alignment.center,
              child: Text(
                client.name!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            MoneyDisplay(
              value: client.totalCash,
              title: "صافي مستحقات و ديون العميل",
              onAdd: () async {
                await showMoneyDialog(context, client, true);
                Get.find<AccountClientInfo>().updateCurrnetClinets();
              },
              onSubtraction: () async {
                await showMoneyDialog(context, client, false);
                Get.find<AccountClientInfo>().updateCurrnetClinets();
              },
            ),
            const SizedBox(
              height: 10,
            ),
            (SupabaseAuthentication.myUser!.role != UserRoles.assistant.index)
                ? Column(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            shape: const StadiumBorder(),
                            backgroundColor: Colors.red[900],
                            padding: const EdgeInsets.all(10)),
                        onPressed: () async {
                          await showDangerDialog(
                              "حذف عميل",
                              "هل أنت متأكد من أنك تريد محو بيانات العميل ${client.name}؟",
                              () async {
                            await BackendServices.instance.clientRepository
                                .delete(client);
                            AccountClientInfo.to.updateCurrnetClinets();
                            Get.back(); // Close the dialog
                            Get.back(); // Close the bottom sheet
                          });
                        },
                        child: const Text(
                          "حذف",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            shape: const StadiumBorder(),
                            backgroundColor: Colors.green[900],
                            padding: const EdgeInsets.all(10)),
                        onPressed: () async {
                          final firstDate =
                              DateTime.now().subtract(const Duration(days: 50));
                          DateTime lastDate = DateTime(firstDate.year + 10);

                          final data = await showDatePicker(
                              context: context,
                              firstDate: firstDate,
                              lastDate: lastDate);

                          if (data != null) {
                            client.expireDate = data;
                            await BackendServices.instance.clientRepository
                                .update(client);
                            AccountClientInfo.to.updateCurrnetClinets();
                            Get.back();
                          }
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.date_range,
                              color: Colors.white,
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Text(
                              "تغيير تاريخ انتهاء العرض",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Card(
                              color: colors.primary,
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Row(
                                  children: [
                                    Container(
                                        decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.black),
                                        width: 50,
                                        height: 50,
                                        child: const Icon(
                                          Icons.person,
                                          size: 50,
                                        )),
                                    const SizedBox(
                                      width: 20,
                                    ),
                                    Container(
                                      width: 1,
                                      height: 50,
                                      color: Colors.black,
                                    ),
                                    const SizedBox(
                                      width: 20,
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              style:
                                                  const TextStyle(fontSize: 12),
                                              'الرقم القومي:  ${client.nationalId}'),
                                          const Divider(),
                                          Text(
                                              style:
                                                  const TextStyle(fontSize: 12),
                                              'العنوان: ${client.address}'),
                                          const Divider(),
                                          Text(
                                              style:
                                                  const TextStyle(fontSize: 12),
                                              'رقم الخط:  ${client.numbers![0].phoneNumber}'),
                                          const Divider(),
                                          Text(
                                              style:
                                                  const TextStyle(fontSize: 12),
                                              'تاريخ انتهاء العرض:  ${(client.expireDate != null) ? fullExpressionArabicDate(client.expireDate!) : "لا يوجد"}'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Container(
                              //height: double.maxFinite,
                              decoration: BoxDecoration(
                                  color: colors.primary,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(style: BorderStyle.solid)),
                              child: Column(
                                children: [
                                  Container(
                                    decoration: const BoxDecoration(
                                        color: Colors.blueGrey,
                                        borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(20),
                                            topRight: Radius.circular(20))),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const SizedBox(
                                          width: 20,
                                        ),
                                        const Text('سجل التعاملات المالية'),
                                        Container(
                                          decoration: const BoxDecoration(
                                              borderRadius: BorderRadius.only(
                                                  topLeft:
                                                      Radius.circular(50))),
                                          child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      colors.background,
                                                  shape:
                                                      const RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.only(
                                                                  topLeft: Radius
                                                                      .circular(
                                                                          20)))),
                                              onPressed: () async {
                                                Get.to(PrintClientsReceipts(
                                                  clients: [client],
                                                ));
                                              },
                                              child: const Text('طباعة')),
                                        )
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: SingleChildScrollView(
                                      child: SizedBox(
                                        height: 0.5 * height,
                                        child: ListView.builder(
                                          itemCount:
                                              clientController.getLogLength(),
                                          itemBuilder: (context, index) {
                                            final currentLog = logs[index];
                                            return LogCardWidget(
                                              currentLog: currentLog,
                                              currentClient: client,
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Container(
                              decoration: BoxDecoration(
                                  color: colors.primary,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(style: BorderStyle.solid)),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.all(10.0),
                                    child: Text(
                                      "الخدمات المقدمة",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(10.0),
                                    child: Row(
                                      children: [
                                        const Text(
                                          "التكلفة الكلية للخدمات المقدمة : ",
                                          style: TextStyle(
                                            fontSize: 15,
                                          ),
                                        ),
                                        Text(
                                          "${(systems.isNotEmpty) ? systems.map((e) => e.type!.price!).reduce((value, element) => value + element) : 0} جنيهاً",
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: ElevatedButton.icon(
                                      style: const ButtonStyle(
                                          backgroundColor:
                                              MaterialStatePropertyAll(
                                                  Colors.blue)),
                                      onPressed: () =>
                                          showSystemAddDialog(client),
                                      icon: const Icon(
                                          Icons.add_circle_outline_sharp),
                                      label: const Text('إضافة باقة جديدة'),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: SingleChildScrollView(
                                      child: SizedBox(
                                        height: height * 0.5,
                                        child: GridView.builder(
                                          itemCount:
                                              systems.length, //systems.length,
                                          gridDelegate:
                                              SliverGridDelegateWithFixedCrossAxisCount(
                                            childAspectRatio: 1.2,
                                            crossAxisCount: crossAxisCount,
                                            crossAxisSpacing: 10,
                                            mainAxisSpacing: 10,
                                          ),
                                          itemBuilder: (context, index) {
                                            return Stack(
                                              children: [
                                                Positioned.fill(
                                                  child: Card(
                                                    margin:
                                                        const EdgeInsets.all(0),
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                          image:
                                                              DecorationImage(
                                                                  opacity: 0.1,
                                                                  image:
                                                                      AssetImage(
                                                                    systems[index]
                                                                        .type!
                                                                        .category!
                                                                        .icon(),
                                                                  ),
                                                                  fit: BoxFit
                                                                      .contain)),
                                                      width: 150,
                                                      child: Center(
                                                          child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                            systems[index]
                                                                .type!
                                                                .name!,
                                                            style: const TextStyle(
                                                                fontSize: 18,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                          ),
                                                          Text(
                                                            "${systems[index].type!.price!} جنيه",
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                        ],
                                                      )),
                                                    ),
                                                  ),
                                                ),
                                                Positioned(
                                                    top: 5,
                                                    left: 5,
                                                    child: IconButton(
                                                      onPressed: () async {
                                                        await showDangerDialog(
                                                            "الغاء اشتراك باقة",
                                                            "هل حقاً تريد الغاء اشتراك باقة العميل من نوع ${systems[index].name} ؟",
                                                            () async {
                                                          await BackendServices
                                                              .instance
                                                              .systemRepository
                                                              .delete(systems[
                                                                  index]);
                                                        });
                                                      },
                                                      icon: const Icon(
                                                          Icons.remove_circle,
                                                          color: Colors.red),
                                                    )),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                ],
                              ),
                            ),
                          )
                        ],
                      )
                    ],
                  )
                : const SizedBox()
          ],
        ),
      );
    });
  }
}

class LogCardWidget extends StatelessWidget {
  const LogCardWidget({
    super.key,
    required this.currentLog,
    required this.currentClient,
  });
  final Client currentClient;
  final Log currentLog;

  @override
  Widget build(BuildContext context) {
    return Card(
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
                          overflow: TextOverflow.clip,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          fullExpressionArabicDate(currentLog.createdAt!),
                          overflow: TextOverflow.clip,
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
                        onPressed: () async {
                          await BackendServices.instance.logRepository
                              .reverseLog(currentLog, currentClient);
                        },
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
    );
  }
}

void showSystemAddDialog(Client clinet) async {
  SystemType? currentType;

  final controller = Get.find<ClientBottomSheetController>();
  final loaders = Get.put(Loaders());

  await Get.defaultDialog(
      title: "أضف خدمة",
      backgroundColor: Colors.white,
      content: Obx(
        () => Column(
          children: [
            DropdownMenu(
              menuHeight: 200,
              enableFilter: true,
              requestFocusOnTap: true,
              enableSearch: true,
              dropdownMenuEntries: controller
                  .getAllTypes()
                  .map(
                    (systemTypeObject) => DropdownMenuEntry(
                      value: systemTypeObject,
                      label: systemTypeObject.name!,
                    ),
                  )
                  .toList(),
              onSelected: (value) {
                currentType = value;
              },
            ),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: (loaders.systemIsLoading.value)
                      ? null
                      : () async {
                          if (currentType != null) {
                            loaders.manageSystemType(clinet, currentType!);
                          }
                          Get.back();
                        },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_rounded),
                          Text("اضافة"),
                        ],
                      ),
                      Visibility(
                          visible: loaders.systemIsLoading.value,
                          child: CustomIndicator())
                    ],
                  )),
            ),
          ],
        ),
      ));
}

class CustomIndicator extends StatelessWidget {
  CustomIndicator({super.key, this.title = "تحميل"});
  String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          semanticsLabel: title,
          strokeWidth: 10,
          strokeCap: StrokeCap.butt,
          backgroundColor: Colors.amber,
          color: Colors.purple,
        ),
        SizedBox(
          height: 10,
        ),
        Text(title)
      ],
    );
  }
}

Future<void> showMoneyDialog(BuildContext context, Client client, bool adding,
    [bool both = false]) async {
  final controller = TextEditingController();
  final loaders = Get.put(Loaders());

  await Get.defaultDialog(
      backgroundColor: Colors.white,
      title: (adding) ? "التعاملات النقدية(ايداع)" : "التعاملات النقدية(حذف)",
      content: Obx(
        () => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: TextField(
                cursorColor: Colors.red,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(
                      RegExp((both!) ? r'[0-9.]' : r'[0-9.-]')),

                  //FilteringTextInputFormatter.digitsOnly
                ],
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  prefixIcon: Icon(FontAwesomeIcons.cashRegister),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: (adding) ? Colors.red : Colors.blue),
                onPressed: (loaders.moneyIsLoading.value)
                    ? null
                    : () async {
                        try {
                          await loaders.changeMoneyValue(
                              client, controller.text, adding);
                        } catch (e) {
                          Get.showSnackbar(GetSnackBar(
                            title: "حدث مشكلة",
                            message: e.toString(),
                            duration: const Duration(seconds: 3),
                          ));
                        }
                        Navigator.pop(context);
                      },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_rounded),
                        Text("تأكيد"),
                      ],
                    ),
                    Visibility(
                        visible: loaders.moneyIsLoading.value,
                        child: CustomIndicator())
                  ],
                )),
          ],
        ),
       ));
}