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
import 'package:phone_system_app/models/system.dart';
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

Future<void> showEditSystemDialog(System system) async {
  final TextEditingController nameController =
      TextEditingController(text: system.name);

  await Get.dialog(
    AlertDialog(
      title: const Text('تعديل النظام'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('النظام: ${system.type!.name}'),
          const SizedBox(height: 16),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'الملاحظات',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              system.name = nameController.text;
              await BackendServices.instance.systemRepository.update(system);
              Get.back();
              Get.snackbar(
                'نجاح',
                'تم تحديث الملاحظات بنجاح',
                snackPosition: SnackPosition.BOTTOM,
              );
              // Update UI in both views
              Get.find<ClientBottomSheetController>().updateClient();
              Get.find<AccountClientInfo>().updateCurrnetClinets();
            } catch (e) {
              Get.snackbar(
                'خطأ',
                'حدث خطأ أثناء تحديث الملاحظات',
                snackPosition: SnackPosition.BOTTOM,
              );
            }
          },
          child: const Text('حفظ', style: TextStyle(color: Colors.black)),
        ),
      ],
    ),
  );
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
            // For assistants, don't show anything else
            if (SupabaseAuthentication.myUser!.role !=
                UserRoles.assistant.index)
              Column(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        shape: const StadiumBorder(),
                        backgroundColor: Colors.red[900],
                        padding: const EdgeInsets.all(10)),
                    onPressed: () async {
                      await showDangerDialog("حذف عميل",
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
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        shape: const StadiumBorder(),
                        backgroundColor: Colors.orange[900],
                        padding: const EdgeInsets.all(10)),
                    onPressed: () async {
                      await showDiscountDialog(context, client);
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.discount,
                          color: Colors.white,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          "إضافة خصم",
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
                                          style: const TextStyle(fontSize: 12),
                                          'الرقم القومي:  ${client.nationalId}'),
                                      const Divider(),
                                      Text(
                                          style: const TextStyle(fontSize: 12),
                                          'العنوان: ${client.address}'),
                                      const Divider(),
                                      Text(
                                          style: const TextStyle(fontSize: 12),
                                          'رقم الخط:  ${client.numbers![0].phoneNumber}'),
                                      const Divider(),
                                      Text(
                                          style: const TextStyle(fontSize: 12),
                                          'تاريخ انتهاء العرض:  ${(client.expireDate != null) ? fullExpressionArabicDate(client.expireDate!) : "لا يوجد"}'),
                                      const Divider(),
                                      Text(
                                          style: const TextStyle(fontSize: 12),
                                          'الخصم الحالي:  ${client.discountPercentage != null ? "${client.discountPercentage}% حتى ${fullExpressionArabicDate(client.discountEndDate!)}" : "لا يوجد"}'),
                                      const Divider(),
                                      Text(
                                          style: const TextStyle(fontSize: 12),
                                          'تاريخ الأشتراك:  ${fullExpressionArabicDate(client.createdAt!)}'),
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
                                              topLeft: Radius.circular(50))),
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                      backgroundColor: MaterialStatePropertyAll(
                                          Colors.blue)),
                                  onPressed: () => showSystemAddDialog(client),
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
                                      itemCount: systems.length,
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                        childAspectRatio: 1.2,
                                        crossAxisCount: crossAxisCount,
                                        crossAxisSpacing: 10,
                                        mainAxisSpacing: 10,
                                      ),
                                      itemBuilder: (context, index) {
                                        final system = systems[index];
                                        // Don't show expired other services but keep their price in total
                                        if (system.type!.category ==
                                            SystemCategory.mobileInternet) {
                                          if (system.createdAt != null) {
                                            final collectionDay =
                                                AccountClientInfo
                                                    .to.currentAccount.day;
                                            final nextCollection = DateTime(
                                              system.createdAt!.month == 12
                                                  ? system.createdAt!.year + 1
                                                  : system.createdAt!.year,
                                              system.createdAt!.month == 12
                                                  ? 1
                                                  : system.createdAt!.month + 1,
                                              collectionDay,
                                            );
                                            if (DateTime.now()
                                                .isAfter(nextCollection)) {
                                              return const SizedBox.shrink();
                                            }
                                          }
                                        }

                                        return Stack(
                                          children: [
                                            Positioned.fill(
                                              child: Card(
                                                margin: const EdgeInsets.all(0),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                      image: DecorationImage(
                                                          opacity: 0.1,
                                                          image: systems[index]
                                                                      .type!
                                                                      .image !=
                                                                  null
                                                              ? NetworkImage(
                                                                  systems[index]
                                                                      .type!
                                                                      .image!,
                                                                ) as ImageProvider
                                                              : AssetImage(
                                                                  systems[index]
                                                                      .type!
                                                                      .category!
                                                                      .icon(),
                                                                ),
                                                          fit: BoxFit.contain)),
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
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(
                                                            Icons.edit),
                                                        onPressed: () =>
                                                            showEditSystemDialog(
                                                                systems[index]),
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
                                                          .delete(
                                                              systems[index]);
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

Future<void> showDiscountDialog(BuildContext context, Client client) async {
  // Initialize with current values if they exist
  final amountController =
      TextEditingController(text: client.discountPercentage?.toString() ?? '');
  final loaders = Get.put(Loaders());

  final discountAmount = (client.discountPercentage ?? 0.0).obs;
  final selectedDate = (client.discountEndDate ?? DateTime.now()).obs;
  final endDate = (client.discountEndDate ?? DateTime.now()).obs;
  final isLongPressed = false.obs;

  // Update preview when inputs change
  void updatePreview() {
    final amount = double.tryParse(amountController.text) ?? 0.0;
    discountAmount.value = amount;
    endDate.value = selectedDate.value;
  }

  void applyDiscount() async {
    try {
      final discountAmount = double.tryParse(amountController.text);

      if (discountAmount == null) {
        Get.snackbar(
          'خطأ',
          'الرجاء إدخال نسبة خصم صحيحة',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      if (discountAmount <= 0 || discountAmount > 100) {
        Get.snackbar(
          'خطأ',
          'نسبة الخصم يجب أن تكون بين 0 و 100',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      if (selectedDate.value.isBefore(DateTime.now())) {
        Get.snackbar(
          'خطأ',
          'تاريخ الانتهاء يجب أن يكون في المستقبل',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // Apply discount and update database
      client.discountPercentage = discountAmount;
      client.discountEndDate = selectedDate.value;

      // Calculate discounted amount for money transactions
      if (client.totalCash != null && client.totalCash! > 0) {
        final discountedAmount = client.totalCash! * (discountAmount / 100);
        client.totalCash = client.totalCash! - discountedAmount;
      }

      await BackendServices.instance.clientRepository.update(client);

      // Update UI controllers
      Get.find<ClientBottomSheetController>().updateClient();
      Get.find<AccountClientInfo>().updateCurrnetClinets();

      Get.back();
      Get.snackbar(
        'نجاح',
        'تم إضافة الخصم وتطبيقه على المبلغ المستحق بنجاح',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء إضافة الخصم: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  amountController.addListener(updatePreview);

  await Get.defaultDialog(
    backgroundColor: Colors.white,
    title: "إضافة خصم",
    content: Obx(
      () => Column(
        children: [
          // Preview Card
          Card(
            color: Colors.orange[50],
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "معاينة الخصم",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("نسبة الخصم:"),
                          const SizedBox(width: 4),
                          Text(
                            "${discountAmount.value}%",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("تاريخ الانتهاء:"),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              fullExpressionArabicDate(endDate.value),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Input Fields
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: GestureDetector(
              onLongPress: () {
                isLongPressed.value = true;
                Future.delayed(const Duration(milliseconds: 500), () {
                  isLongPressed.value = false;
                });
              },
              child: Theme(
                data: Theme.of(context).copyWith(
                  textSelectionTheme: TextSelectionThemeData(
                    selectionColor: Colors.orange[200],
                    selectionHandleColor: Colors.orange[900],
                    cursorColor: Colors.orange[900],
                  ),
                ),
                child: TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    labelText: 'نسبة الخصم (%)',
                    prefixIcon: const Icon(Icons.percent),
                    border: const OutlineInputBorder(),
                    suffixIcon: Icon(
                      Icons.discount,
                      color:
                          discountAmount.value > 0 ? Colors.green : Colors.grey,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Colors.orange[900]!, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[400]!),
                    ),
                    labelStyle: TextStyle(
                      color: Colors.orange[900],
                      fontWeight: FontWeight.bold,
                    ),
                    floatingLabelStyle: TextStyle(
                      color: Colors.orange[900],
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    hintText: 'أدخل نسبة الخصم',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                    filled: true,
                    fillColor:
                        isLongPressed.value ? Colors.blue[50] : Colors.grey[50],
                  ),
                  onChanged: (value) {
                    updatePreview();
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: GestureDetector(
              onLongPress: () {
                isLongPressed.value = true;
                Future.delayed(const Duration(milliseconds: 500), () {
                  isLongPressed.value = false;
                });
              },
              child: InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate.value,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: Colors.orange[900]!,
                            onPrimary: Colors.white,
                            surface: Colors.white,
                            onSurface: Colors.black,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    final TimeOfDay? time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(selectedDate.value),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                              primary: Colors.orange[900]!,
                              onPrimary: Colors.white,
                              surface: Colors.white,
                              onSurface: Colors.black,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (time != null) {
                      selectedDate.value = DateTime(
                        picked.year,
                        picked.month,
                        picked.day,
                        time.hour,
                        time.minute,
                      );
                      updatePreview();
                    }
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'تاريخ الانتهاء',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: const OutlineInputBorder(),
                    suffixIcon: Icon(
                      Icons.timer,
                      color: selectedDate.value.isAfter(DateTime.now())
                          ? Colors.green
                          : Colors.grey,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Colors.orange[900]!, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[400]!),
                    ),
                    labelStyle: TextStyle(
                      color: Colors.orange[900],
                      fontWeight: FontWeight.bold,
                    ),
                    floatingLabelStyle: TextStyle(
                      color: Colors.orange[900],
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                    filled: true,
                    fillColor:
                        isLongPressed.value ? Colors.blue[50] : Colors.grey[50],
                  ),
                  child: Text(
                    fullExpressionArabicDate(selectedDate.value),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Submit Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[900],
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: loaders.discountIsLoading.value ? null : applyDiscount,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check, color: Colors.white),
                const SizedBox(width: 8),
                const Text(
                  'تأكيد',
                  style: TextStyle(color: Colors.white),
                ),
                if (loaders.discountIsLoading.value)
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
