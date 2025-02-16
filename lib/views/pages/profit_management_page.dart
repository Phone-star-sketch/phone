import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/controllers/account_profit_controller.dart';
import 'package:phone_system_app/controllers/money_display_loading.dart';
import 'package:phone_system_app/models/profit.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';
import 'package:phone_system_app/views/bottom_sheet_dialogs/show_client_info_sheet.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phone_system_app/views/pages/profit_details_dialog.dart';
import 'package:phone_system_app/controllers/account_client_info_data.dart';

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

class ProfitManagement extends StatefulWidget {
  @override
  State<ProfitManagement> createState() => _ProfitManagementState();
}

class _ProfitManagementState extends State<ProfitManagement>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final profitController = Get.put(ProfitController());
  final loaders = Get.put(Loaders());
  final clientController = Get.find<AccountClientInfo>();
  List<int> years = List<int>.generate(10, (index) => 2024 + index);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(); // This makes the animation continuous
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _calculateTotalDues() {
    return profitController.calculateTotalDues();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: Obx(
        () => (Loaders.to.typesIsLoading.value)
            ? Center(
                child: CustomIndicator(
                  title: "يتم تحميل الارباح",
                ),
              )
            : SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) {
                              return Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.001)
                                  ..rotateY(_controller.value * 2 * 3.14159),
                                child: Icon(
                                  Icons.monetization_on_rounded,
                                  size: 32,
                                  color: const Color(0xFFFFD700),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            "إدارة الأرباح",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3250),
                            ),
                          ),
                        ],
                      ).animate().fadeIn().slideX(),
                      const SizedBox(height: 20),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.white, Colors.grey.shade50],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: CustomDropDown(
                                      onSelected: profitController
                                          .onMonthOrYearSelected,
                                      name: "الشهر",
                                      controller:
                                          profitController.monthController,
                                      ddEntries: profitController.months.entries
                                          .map((e) => DropdownMenuEntry(
                                              value: e.key, label: e.value))
                                          .toList(),
                                    ),
                                  ),
                                  Expanded(
                                    child: CustomDropDown(
                                      onSelected: profitController
                                          .onMonthOrYearSelected,
                                      name: "السنة",
                                      controller:
                                          profitController.yearController,
                                      ddEntries: years
                                          .map((e) => DropdownMenuEntry(
                                              value: e, label: e.toString()))
                                          .toList(),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Column(
                                children: [
                                  CustomInputField(
                                    title: "الفاتورة الصادرة من الشركة",
                                    controller:
                                        profitController.totalIncomeController,
                                    icon: Icons.attach_money,
                                    suffix: "ج.م",
                                    onChanged: (value) {
                                      profitController.calculateDiscount();
                                    },
                                  ),
                                  FutureBuilder<MonthlyProfit?>(
                                    future:
                                        profitController.calculateTotalProfit(
                                      profitController.monthsToInt[
                                          profitController
                                              .monthController.text]!,
                                      int.parse(
                                          profitController.yearController.text),
                                    ),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData &&
                                          snapshot.data != null) {
                                        return Container(
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 10, horizontal: 15),
                                          padding: const EdgeInsets.all(15),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8F9FA),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                                color: Colors.grey.shade300),
                                          ),
                                          child: Column(
                                            children: [
                                              const Text(
                                                "المبلغ المتوقع جمعه",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF424874),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Obx(() => Text(
                                                    "${_calculateTotalDues()} ج.م",
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.red,
                                                    ),
                                                  )),
                                            ],
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                  CustomInputField(
                                    title: "نسبة الخصم المتوقعة",
                                    controller:
                                        profitController.discountController,
                                    icon: Icons.discount,
                                    suffix: "%",
                                    onChanged: (value) {
                                      profitController.calculateDiscount();
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn().scale(),
                      const SizedBox(height: 30),
                      Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF424874),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: (Loaders.to.profitLoader.value)
                              ? null
                              : () async {
                                  final profit =
                                      await profitController.onStoreClick();
                                  final monthName =
                                      profitController.monthController.text;

                                  Get.dialog(
                                    ProfitDetailsDialog(
                                      profit: profit,
                                      monthName: monthName,
                                    ),
                                    barrierDismissible: true,
                                  );
                                },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calculate, color: Colors.white),
                              const SizedBox(width: 10),
                              const Text(
                                "تسجيل و حساب الربح",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn().scale(),
                      if (Loaders.to.profitLoader.value)
                        Center(
                          child: CustomIndicator(
                            title: "برجاء الانتظار يتم حساب الربح ...",
                          ),
                        ),
                    ],
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
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF424874),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              color: Colors.white,
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                textTheme: Theme.of(context).textTheme.apply(
                      bodyColor: const Color(0xFF424874),
                      displayColor: const Color(0xFF424874),
                    ),
              ),
              child: DropdownMenu(
                textStyle: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF424874),
                ),
                menuStyle: MenuStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.white),
                  elevation: MaterialStateProperty.all(4),
                  shadowColor: MaterialStateProperty.all(Colors.black54),
                ),
                inputDecorationTheme: InputDecorationTheme(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  hoverColor: Colors.grey.shade100,
                ),
                menuHeight: 250,
                width: MediaQuery.of(context).size.width * 0.4,
                requestFocusOnTap: true,
                enableSearch: true,
                expandedInsets: const EdgeInsets.all(0),
                dropdownMenuEntries: ddEntries,
                controller: controller,
                onSelected: onSelected,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomInputField extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final IconData? icon;
  final Function(String)? onChanged;
  final String? suffix;

  const CustomInputField({
    super.key,
    required this.title,
    required this.controller,
    this.icon,
    this.onChanged,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF424874),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                textSelectionTheme: const TextSelectionThemeData(
                  selectionColor:
                      Color(0xFFFFE6E6), // Light red background for selection
                  cursorColor: Colors.red,
                  selectionHandleColor: Colors.red,
                ),
              ),
              child: TextField(
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF424874),
                  fontWeight: FontWeight.w500,
                ),
                cursorColor: Colors.red,
                cursorWidth: 2,
                showCursor: true,
                enableInteractiveSelection: true,
                toolbarOptions: const ToolbarOptions(
                  copy: true,
                  cut: true,
                  paste: true,
                  selectAll: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: InputDecoration(
                  prefixIcon: Icon(icon, color: const Color(0xFF424874)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.red,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  hoverColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 16,
                  ),
                  suffixText: suffix,
                  suffixStyle: const TextStyle(
                    color: Color(0xFF424874),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                controller: controller,
                onChanged: onChanged,
                contextMenuBuilder: (context, editableTextState) {
                  return AdaptiveTextSelectionToolbar.editableText(
                    editableTextState: editableTextState,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
