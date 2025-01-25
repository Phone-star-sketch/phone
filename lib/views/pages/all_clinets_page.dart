import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/controllers/account_client_info_data.dart';
import 'package:phone_system_app/controllers/account_profit_controller.dart';
import 'package:phone_system_app/controllers/money_display_loading.dart';
import 'package:phone_system_app/models/client.dart';
import 'package:phone_system_app/views/bottom_sheet_dialogs/show_client_info_sheet.dart';
import 'package:phone_system_app/views/client_list_view.dart';
import 'package:phone_system_app/views/print_clients_receipts.dart';

class AllClientsPage extends StatefulWidget {
  AllClientsPage({super.key});

  @override
  _AllClientsPageState createState() => _AllClientsPageState();
}

class _AllClientsPageState extends State<AllClientsPage> {
  final controller = Get.find<AccountClientInfo>();
  late RealTimeDataFetcher realTimeFetcher;

  @override
  void initState() {
    super.initState();
    // Initialize the real-time data fetcher
    realTimeFetcher = RealTimeDataFetcher(controller);
  }

  @override
  void dispose() {
    // Dispose of the timer when the widget is removed
    realTimeFetcher.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final data = controller.getCurrentClients();
      final isLoading = controller.isLoading.value;
      final printingClients = controller.clientPrintAdded.value;
      return Column(
        children: [
          CutsomToolBar(
              controller: controller, printingClients: printingClients),
          Expanded(
              child: (isLoading)
                  ? Center(
                      child: CustomIndicator(),
                    )
                  : (Loaders.to.paymentIsLoading.value)
                      ? PaymentLoadingWidget()
                      : ClientListView(
                          data: data,
                          isLoading: isLoading,
                          query: controller.query.value,
                        ))
        ],
      );
    });
  }
}

class CutsomToolBar extends StatelessWidget {
  const CutsomToolBar({
    super.key,
    required this.controller,
    required this.printingClients,
  });

  final AccountClientInfo controller;
  final List<Client> printingClients;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Get.find<AccountClientInfo>().enableMulipleClientPrint.value
            ? SizedBox(
                width: 50,
                height: 50,
                child: ListView(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: IconButton(
                          color: Colors.blue,
                          onPressed: () {
                            // call the file print.....
                            Get.find<AccountClientInfo>()
                                .enableMulipleClientPrint
                                .value = false;
                          },
                          icon: const Icon(Icons.check_box)),
                    ),
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: IconButton(
                          color: Colors.red,
                          onPressed: () {
                            final controller = Get.find<AccountClientInfo>();
                            controller.enableMulipleClientPrint.value = false;
                          },
                          icon: const Icon(Icons.cancel)),
                    ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(10),
                child: ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () {
                      Get.find<AccountClientInfo>()
                          .enableMulipleClientPrint
                          .value = true;
                      controller.clientPrintAdded.clear();
                    },
                    child: const Icon(Icons.account_tree)),
              ),
        Expanded(
          child: CustomTextField(
            controller: controller.searchController,
            onChanged: controller.searchQueryChanged,
          ),
        ),
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: IconButton(
                  style: IconButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(5)))),
                  onPressed: () {
                    Get.defaultDialog(
                        title: "قائمة الطباعة",
                        backgroundColor: Colors.white,
                        actions: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red),
                            onPressed: () async {
                              if (printingClients.isNotEmpty) {
                                print("Test length ----------->");
                                print(printingClients.length);
                                Get.to(
                                  PrintClientsReceipts(
                                    clients: controller.clientPrintAdded.value,
                                  ),
                                );
                              } else {
                                Get.showSnackbar(const GetSnackBar(
                                  title: 'تنويه',
                                  message: 'يجب اضافة اسماء اولاً',
                                  duration: Duration(seconds: 5),
                                ));
                                Get.back();
                              }
                            },
                            child: const Text("تأكيد"),
                          )
                        ],
                        content: Obx(
                          () => SizedBox(
                            width: 500,
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: ListView.separated(
                              separatorBuilder: (context, index) {
                                return const Divider(
                                  endIndent: 100,
                                  indent: 100,
                                );
                              },
                              itemCount: controller.clientPrintAdded.length,
                              itemBuilder: (context, index) {
                                final client =
                                    controller.clientPrintAdded[index];
                                return Card(
                                  child: Stack(
                                    children: [
                                      Row(
                                        children: [
                                          const Padding(
                                            padding: EdgeInsets.all(15.0),
                                            child: Icon(
                                              Icons.supervised_user_circle,
                                              color: Colors.red,
                                            ),
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  client.name!,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15,
                                                      color: Colors.black),
                                                ),
                                                Text(
                                                  client
                                                      .numbers![0].phoneNumber!,
                                                  style: const TextStyle(
                                                      color: Colors.black54),
                                                ),
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                      Positioned(
                                          left: 5,
                                          top: 5,
                                          child: IconButton(
                                            onPressed: () {
                                              controller.clientPrintAdded
                                                  .remove(client);
                                            },
                                            icon: const Icon(Icons.remove),
                                          ))
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ));
                  },
                  tooltip: "طباعة",
                  icon: const Icon(
                    FontAwesomeIcons.print,
                    color: Colors.white,
                  )),
            ),
          ],
        )
      ],
    );
  }
}

class PaymentLoadingWidget extends StatelessWidget {
  final controller = Get.find<AccountClientInfo>();

  PaymentLoadingWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final next = ProfitController.to.getNextMonthToBePaid();
    final month = next.month;
    final year = next.year;

    return Obx(() {
      final currentClient = controller.currentPayingClient;
      final totalLength = controller.clinets.length;
      final totalPaid = controller.countPaid;
      final totalNotPaid = controller.countNotPaid;
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("...برجاء الانتظار"),
          Text(
              "يتم الان تحصيل الفواتير المتبقية الخاصة بشهر ${ProfitController.to.months[month]} لعام ${year}"),
          Text("${currentClient.value.name}"),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("$totalPaid / $totalLength"),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(
                    value: totalPaid.value / totalLength,
                    color: Colors.red,
                    minHeight: 20,
                    borderRadius: BorderRadius.circular(20),
                    backgroundColor: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          CustomIndicator(
            title: "",
          ),
        ],
      );
    });
  }
}

class CustomTextField extends StatelessWidget {
  TextEditingController controller;
  Function(String)? onChanged;

  CustomTextField({super.key, required this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      cursorColor: Colors.red,
      onChanged: onChanged,
      controller: controller,
      decoration: InputDecoration(
          hintText: "أبحث عن رقم",
          hintStyle: const TextStyle(color: Colors.black38),
          prefixIcon: const Icon(FontAwesomeIcons.searchengin),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
    );
  }
}

class RealTimeDataFetcher {
  final AccountClientInfo controller;
  Timer? _timer;

  RealTimeDataFetcher(this.controller) {
    // Start fetching data every 10 seconds
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      controller.updateCurrnetClinets(); // Fetch new data
    });
  }

  void dispose() {
    _timer?.cancel(); // Cancel the timer when not needed
  }
}