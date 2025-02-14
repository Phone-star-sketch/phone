import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/controllers/account_client_info_data.dart';
import 'package:phone_system_app/controllers/client_bottom_sheet_controller.dart';
import 'package:phone_system_app/models/client.dart';
import 'package:phone_system_app/models/phone_number.dart';
import 'package:phone_system_app/services/backend/auth.dart';
import 'package:phone_system_app/widget_models/clientCreationModelSheet.dart';
import 'bottom_sheet_dialogs/show_client_info_sheet.dart';
import 'package:phone_system_app/utils/string_utils.dart';
import 'package:phone_system_app/utils/arabic_normalizer.dart'; // Add this line

class ClientListView extends StatelessWidget {
  String? query;
  List<Client> data;
  bool isLoading;

  final accountController = Get.find<AccountClientInfo>();
  final scrollController = ScrollController();

  ClientListView({
    super.key,
    this.query = "",
    required this.data,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;

    // Filter clients based on the query
    List<Client> filteredData =
        ClientFilterUtils.filterClients(query ?? '', data);

    // Debug logs to verify filtering
    print("Query: $query");
    print(
        "Filtered Data: ${filteredData.map((client) => client.name).toList()}");

    return Scaffold(
      backgroundColor: Colors.white, // Ensure background color is set to white
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        child: const Icon(Icons.person_add_alt),
        onPressed: () async {
          await clientEditModelSheet(context);
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const ClientListHeader(),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredData.isEmpty
                      ? EmptyStateWidget(query: query)
                      : GridView.builder(
                          controller: scrollController,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: screenWidth > 1200
                                ? 3
                                : (screenWidth > 800 ? 2 : 1),
                            childAspectRatio: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: filteredData.length,
                          itemBuilder: (context, index) => ClientCard(
                            client: filteredData[index],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class ClientListHeader extends StatelessWidget {
  const ClientListHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('الإسم', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('رقم الهاتف', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('المطلوب سدادة',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class ClientCard extends StatefulWidget {
  final Client client;
  ClientCard({Key? key, required this.client}) : super(key: key);

  @override
  State<ClientCard> createState() => _ClientCardState();
}

class _ClientCardState extends State<ClientCard>
    with SingleTickerProviderStateMixin {
  final AccountClientInfo controller = Get.find<AccountClientInfo>();
  bool isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color getWarningColorState(double required) {
    if (required >= 0 && required < 10) {
      return const Color(0xFFFFB74D); // Orange
    } else if (required > 10) {
      return const Color(0xFF66BB6A); // Green
    } else {
      return const Color(0xFFEF5350); // Red
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientCash = widget.client.totalCash;
    final requiredCash = (clientCash >= 0) ? 0 : -clientCash;
    final phoneNumber = widget.client.numbers?.isNotEmpty == true
        ? widget.client.numbers![0].phoneNumber ?? 'لا يوجد رقم'
        : 'لا يوجد رقم';

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: MouseRegion(
            onEnter: (_) {
              setState(() => isHovered = true);
              _controller.forward();
            },
            onExit: (_) {
              setState(() => isHovered = false);
              _controller.reverse();
            },
            child: Card(
              elevation: isHovered ? 8 : 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isHovered
                        ? [Colors.white, Colors.blue.shade50]
                        : [Colors.white, Colors.grey.shade50],
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () async {
                    final controller = Get.put(ClientBottomSheetController());
                    controller.setClient(widget.client);
                    await showClientInfoSheet(context, widget.client);
                    Get.delete<ClientBottomSheetController>(force: true);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.blue.shade100,
                                    child: Text(
                                      widget.client.name
                                              ?.substring(0, 1)
                                              .toUpperCase() ??
                                          '',
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.client.name ?? '',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          phoneNumber,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                if (SupabaseAuthentication.myUser!.role !=
                                    UserRoles.assistant.index)
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    color: Colors.blue,
                                    onPressed: () async {
                                      await clientEditModelSheet(context,
                                          client: widget.client);
                                    },
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.copy),
                                  color: Colors.green,
                                  onPressed: () {
                                    if (phoneNumber.isNotEmpty) {
                                      Clipboard.setData(
                                          ClipboardData(text: phoneNumber));
                                      Get.showSnackbar(
                                        const GetSnackBar(
                                          message: 'تم نسخ رقم الهاتف',
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: getWarningColorState(clientCash.toDouble()),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    getWarningColorState(clientCash.toDouble())
                                        .withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "المطلوب:",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "$requiredCash جنيهاً",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final String? query;

  const EmptyStateWidget({Key? key, this.query}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Opacity(
            opacity: 0.1,
            child: Image.asset(
              'assets/images/v_logo_blank.png',
              height: 2000,
              fit: BoxFit.contain,
            ),
          ),
        ),
        Center(
          child: Container(
            width: 200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Opacity(
                  opacity: 0.6,
                  child: SvgPicture.asset(
                    "assets/images/zi_search_logo.svg",
                    width: 200,
                    fit: BoxFit.contain,
                  ),
                ),
                Text(
                  (query == null || query!.isEmpty)
                      ? "أبحث عن رقم او أسم"
                      : "لا يوجد نتائج لهذا البحث",
                  style: const TextStyle(color: Colors.black),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ClientFilterUtils {
  static List<Client> filterClients(String query, List<Client> clients) {
    final normalizedQuery = normalizeArabicText(query);

    return clients.where((client) {
      String normalizedName = normalizeArabicText(client.name ?? '');
      String normalizedPhone = normalizeArabicText(
          (client.numbers?.isNotEmpty == true
                  ? client.numbers![0].phoneNumber ?? ''
                  : '')
              .replaceAll(" ", ""));

      // Debug logs to verify normalization
      print("Normalized Query: $normalizedQuery");
      print("Normalized Name: $normalizedName");
      print("Normalized Phone: $normalizedPhone");

      return normalizedName.contains(normalizedQuery) ||
          normalizedPhone.contains(normalizedQuery);
    }).toList();
  }
}

String normalizeArabicText(String text) {
  // Remove all special characters and spaces
  text = text.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '');

  // Normalize Arabic characters
  text = text
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي')
      .replaceAll('ؤ', 'و')
      .replaceAll('ئ', 'ي');

  return text.trim().toLowerCase();
}
