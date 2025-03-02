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
import 'package:flutter/services.dart';
import 'package:phone_system_app/utils/string_utils.dart';

class AllClientsPage extends StatefulWidget {
  const AllClientsPage({super.key}); // Make constructor const

  @override
  _AllClientsPageState createState() => _AllClientsPageState();
}

class _AllClientsPageState extends State<AllClientsPage>
    with AutomaticKeepAliveClientMixin {
  final controller = Get.find<AccountClientInfo>();

  List<Client> _getSmartFilteredClients(String query) {
    // Changed to use clients.value directly like dues_management
    List<Client> clients = controller.clinets.value;
    if (query.isEmpty) return clients;

    return clients.where((element) {
      final hasMatchingPhone = element.numbers?.isNotEmpty == true &&
          element.numbers![0].phoneNumber?.contains(query) == true;

      final hasMatchingName = element.name != null &&
          removeSpecialArabicChars(element.name!)
              .contains(removeSpecialArabicChars(query));

      return hasMatchingPhone || hasMatchingName;
    }).toList();
  }

  @override
  bool get wantKeepAlive => true; // Keep the state alive

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin

    return Container(
      key: const PageStorageKey<String>(
          'allClientsPage'), // Add page storage key
      color: Colors.white, // Add this to ensure white background
      child: Obx(() {
        // Cache the query result like in dues_management
        final q = controller.query.value;
        final filteredData = _getSmartFilteredClients(q);

        final isLoading = controller.isLoading.value;
        final printingClients = controller.clientPrintAdded.value;

        return Column(
          children: [
            Container(
              color: Colors
                  .white, // Add this to ensure white background for toolbar
              child: CutsomToolBar(
                  controller: controller, printingClients: printingClients),
            ),
            Expanded(
                child: (isLoading)
                    ? Center(child: CustomIndicator())
                    : (Loaders.to.paymentIsLoading.value)
                        ? PaymentLoadingWidget()
                        : ClientListView(
                            data: filteredData,
                            isLoading: isLoading,
                            query: controller.query.value,
                          ))
          ],
        );
      }),
    );
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
                          color: Colors.lightBlue,
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
                          color: Colors.lightBlue,
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue,
                    padding: const EdgeInsets.all(12),
                  ),
                  onPressed: () {
                    controller
                        .toggleMultiSelection(); // Use the new toggle method
                  },
                  child: Icon(
                    controller.enableMulipleClientPrint.value
                        ? Icons.cancel
                        : Icons.account_tree,
                    color: Colors.white,
                  ),
                ),
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
                      backgroundColor: Colors.lightBlue,
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(5)))),
                  onPressed: () {
                    Get.defaultDialog(
                        title: "قائمة الطباعة",
                        backgroundColor: Colors.white,
                        actions: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.lightBlue),
                            onPressed: () async {
                              if (printingClients.isNotEmpty) {
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Padding(
                                            padding: EdgeInsets.all(15.0),
                                            child: Icon(
                                              Icons.supervised_user_circle,
                                              color: Colors.lightBlue,
                                            ),
                                          ),
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  left:
                                                      40.0), // Add padding for remove button
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 8.0,
                                                            right: 8.0),
                                                    child: Text(
                                                      client.name!,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 15,
                                                        color: Colors.black,
                                                      ),
                                                      softWrap: true,
                                                      overflow:
                                                          TextOverflow.visible,
                                                    ),
                                                  ),
                                                  Row(
                                                    children: [
                                                      Flexible(
                                                        child: Text(
                                                          client.numbers![0]
                                                              .phoneNumber!,
                                                          style:
                                                              const TextStyle(
                                                                  color: Colors
                                                                      .black54),
                                                        ),
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(
                                                            Icons.copy,
                                                            size: 16),
                                                        onPressed: () {
                                                          Clipboard.setData(
                                                              ClipboardData(
                                                                  text: client
                                                                      .numbers![
                                                                          0]
                                                                      .phoneNumber!));
                                                          Get.showSnackbar(
                                                              const GetSnackBar(
                                                            message:
                                                                'تم نسخ رقم الهاتف',
                                                            duration: Duration(
                                                                seconds: 2),
                                                          ));
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
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
                                        ),
                                      )
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
                    color: Colors.lightBlue,
                    minHeight: 20,
                    borderRadius: BorderRadius.circular(20),
                    backgroundColor: Colors.lightBlue.withOpacity(0.3),
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

// Make CustomTextField more efficient
class CustomTextField extends StatefulWidget {
  const CustomTextField(
      { // Make constructor const
      super.key,
      required this.controller,
      this.onChanged});

  final TextEditingController controller;
  final Function(String)? onChanged;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  TextSelection? _selection;
  String _selectedText = '';

  void _handleSelectionChanged(TextSelection selection) {
    setState(() {
      _selection = selection;
      _selectedText = widget.controller.text.substring(
        selection.start,
        selection.end,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextSelectionTheme(
          data: TextSelectionThemeData(
            selectionColor: Colors.lightBlue.withOpacity(0.3),
          ),
          child: TextField(
            cursorColor: Colors.lightBlue,
            onChanged: widget.onChanged,
            controller: widget.controller,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            onTapOutside: (event) {
              setState(() {
                _selection = null;
                _selectedText = '';
              });
            },
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            selectionControls: MaterialTextSelectionControls(),
            decoration: InputDecoration(
              hintText: "ابحث عن عميل (الاسم، رقم الهاتف)",
              hintStyle: const TextStyle(
                color: Colors.black38,
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
              prefixIcon: const Icon(FontAwesomeIcons.searchengin,
                  color: Colors.lightBlue),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Colors.lightBlue),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Colors.lightBlue),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        if (_selection != null) ...[
          const SizedBox(height: 8),
          Text(
            'موضع المؤشر: ${_selection?.baseOffset}, النص المحدد: $_selectedText',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textDirection: TextDirection.rtl,
          ),
        ],
      ],
    );
  }
}
