import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/controllers/account_client_info_data.dart';
import 'package:phone_system_app/models/client.dart';
import 'package:phone_system_app/utils/string_utils.dart';
import 'package:phone_system_app/views/client_list_view.dart';
import 'package:phone_system_app/views/pages/all_clinets_page.dart';
import 'package:flutter/animation.dart';

class DuesManagement extends StatefulWidget {
  // Change to StatefulWidget
  const DuesManagement({super.key}); // Make constructor const

  @override
  State<DuesManagement> createState() => _DuesManagementState();
}

class _DuesManagementState extends State<DuesManagement>
    with AutomaticKeepAliveClientMixin {
  final controller = Get.find<AccountClientInfo>();

  @override
  bool get wantKeepAlive => true; // Keep the state alive

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin

    return Container(
      key: const PageStorageKey<String>(
          'duesManagementPage'), // Add page storage key
      color: Colors.white,
      child: Obx(() {
        // Cache the query result
        final q = controller.query.value;
        final clients = _getFilteredClients(q);
        final totalCash = _calculateTotalCash(clients);

        return Column(
          children: [
            Container(
              color: Colors.white, // Add white background
              height:
                  MediaQuery.of(context).size.height * 0.15, // Increased height
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceEvenly, // Changed to spaceEvenly
                children: [
                  CustomDataColumn(
                    title: "الدين الكلي",
                    value: "${totalCash * -1}",
                    end: "ج",
                  ),
                  Container(
                    height: 50,
                    width: 1,
                    color: Colors.grey.withOpacity(0.3),
                  ),
                  CustomDataColumn(
                    title: "العدد",
                    value: "${clients.length}",
                  )
                ],
              ),
            ),
            Container(
              color: Colors.white, // Add white background
              child: CutsomToolBar(
                  controller: controller,
                  printingClients: _getFilteredClients(controller.query.value)),
            ),
            Expanded(
                child: ClientListView(
              data: clients,
              isLoading: controller.isLoading.value,
              query: controller.query.value,
            ))
          ],
        );
      }),
    );
  }

  // Extract filtering logic to separate method for better performance
  List<Client> _getFilteredClients(String query) {
    List<Client> clients = controller.clinets.value
        .where((element) => element.totalCash < 0)
        .toList();

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

  // Extract calculation to separate method
  num _calculateTotalCash(List<Client> clients) {
    if (clients.isEmpty) return 0;
    return clients
        .map((e) => e.totalCash)
        .reduce((value, element) => value + element);
  }

  void _handlePrintClients() {
    // Add your printing logic here
    final clients = _getFilteredClients(controller.query.value);
    // Implement printing functionality
  }
}

class CustomDataColumn extends StatefulWidget {
  const CustomDataColumn({
    super.key,
    required this.title,
    required this.value,
    this.end = "",
  });

  final String title;
  final String value;
  final String end;

  @override
  State<CustomDataColumn> createState() => _CustomDataColumnState();
}

class _CustomDataColumnState extends State<CustomDataColumn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.lightBlue.shade100,
            Colors.lightBlue.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.lightBlue,
                  ),
                ),
                if (widget.end.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(
                    widget.end,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
