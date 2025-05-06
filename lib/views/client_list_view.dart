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
import 'package:phone_system_app/utils/arabic_normalizer.dart';

class ClientListView extends StatefulWidget {
  final String? query;
  final List<Client> data;
  final bool isLoading;

  const ClientListView({
    super.key,
    this.query = "",
    required this.data,
    required this.isLoading,
  });

  @override
  State<ClientListView> createState() => _ClientListViewState();
}

class _ClientListViewState extends State<ClientListView> {
  late final AccountClientInfo accountController;
  late final ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    accountController = Get.find<AccountClientInfo>();
    scrollController = ScrollController();
    // Ensure controller exists
    if (!Get.isRegistered<ClientBottomSheetController>()) {
      Get.put(ClientBottomSheetController());
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void _showClientInfo(BuildContext context, Client client) {
    // Remove any existing controller first
    if (Get.isRegistered<ClientBottomSheetController>()) {
      Get.delete<ClientBottomSheetController>();
    }
    
    // Create a new controller instance
    final controller = Get.put(ClientBottomSheetController());
    controller.setClient(client);
    
    showClientInfoSheet(context, client);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;

    List<Client> filteredData =
        ClientFilterUtils.filterClients(widget.query ?? '', widget.data);

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF8E97FD),
        child: const Icon(Icons.person_add_alt, color: Colors.white),
        onPressed: () async {
          await clientEditModelSheet(context);
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section similar to the example UI
            const PageHeaderSection(),
            const SizedBox(height: 20),
            // Client list or empty state
            Expanded(
              child: widget.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredData.isEmpty
                      ? EmptyStateWidget(query: widget.query)
                      : GridView.builder(
                          controller: scrollController,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: screenWidth > 1200
                                ? 3
                                : (screenWidth > 800 ? 2 : 1),
                            childAspectRatio: 1.8, // Increased from 1.7
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: filteredData.length,
                          itemBuilder: (context, index) {
                            final client = filteredData[index];
                            return Obx(() => Stack(
                                  children: [
                                    EnhancedClientCard(
                                      client: client,
                                      onTap: () =>
                                          _showClientInfo(context, client),
                                    ),

                                    // Selection checkbox overlay
                                    if (accountController
                                        .enableMulipleClientPrint.value)
                                      Positioned(
                                        right: 8,
                                        top: 8,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.8),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Checkbox(
                                            value: accountController
                                                .clientPrintAdded
                                                .contains(client),
                                            onChanged: (selected) {
                                              if (selected == true) {
                                                accountController
                                                    .clientPrintAdded
                                                    .add(client);
                                              } else {
                                                accountController
                                                    .clientPrintAdded
                                                    .remove(client);
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                  ],
                                ));
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class PageHeaderSection extends StatelessWidget {
  const PageHeaderSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 20, 0, 0),
            child: Text(
              "قائمة العملاء",
              style: TextStyle(
                fontSize: 28,
                color: Colors.blueGrey[800],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 0, 5),
            child: Text(
              "جميع عملائك في مكان واحد",
              style: TextStyle(
                fontSize: 16,
                color: Colors.blueGrey[400],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EnhancedClientCard extends StatefulWidget {
  final Client client;
  final VoidCallback? onTap;
  const EnhancedClientCard({
    Key? key,
    required this.client,
    this.onTap,
  }) : super(key: key);

  @override
  State<EnhancedClientCard> createState() => _EnhancedClientCardState();
}

class _EnhancedClientCardState extends State<EnhancedClientCard>
    with SingleTickerProviderStateMixin {
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

  Color getStatusColor(double balance) {
    if (balance >= 10) {
      return const Color(0xFF6CB28E); // Green - Good balance
    } else if (balance >= 0 && balance < 10) {
      return const Color(0xFFFFB74D); // Orange - Low balance
    } else {
      return const Color(0xFFFA6E5A); // Red - Negative balance
    }
  }

  Color getTextColor(Color backgroundColor) {
    // Using the example's approach to text color
    if (backgroundColor == const Color(0xFFFFB74D)) {
      return const Color(0xff3F414E); // Darker text for lighter backgrounds
    }
    return const Color(0xffFFECCC); // Light text for darker backgrounds
  }

  @override
  Widget build(BuildContext context) {
    final clientCash = widget.client.totalCash;
    final requiredCash = (clientCash >= 0) ? 0 : -clientCash;
    final phoneNumber = widget.client.numbers?.isNotEmpty == true
        ? widget.client.numbers![0].phoneNumber ?? 'لا يوجد رقم'
        : 'لا يوجد رقم';

    final cardColor = getStatusColor(clientCash.toDouble());
    final textColor = getTextColor(cardColor);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return SizedBox(
          height: 170, // Reduced from 180
          child: Transform.scale(
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
              child: InkWell(
                onTap: widget.onTap,
                child: Card(
                  elevation: isHovered ? 8 : 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  color: cardColor,
                  child: Stack(
                    children: [
                      // Background Image Effect (similar to the example)
                      Align(
                        alignment: Alignment.topRight,
                        child: Opacity(
                          opacity: 0.2,
                          child: Container(
                            height: 115,
                            width: 115,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),

                      // Content
                      Padding(
                        padding:
                            const EdgeInsets.all(12.0), // Reduced from 16.0
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Client Status Text
                            SizedBox(
                              height: 16,
                              child: Text(
                                requiredCash > 0 ? "مطلوب سداد" : "رصيد جيد",
                                style: TextStyle(
                                  fontSize: 11, // Further reduced
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Client Name with limited height
                            SizedBox(
                              height: 28, // Reduced from 32
                              child: Text(
                                widget.client.name ?? '',
                                style: TextStyle(
                                  fontSize: 20, // Further reduced
                                  color: textColor,
                                  fontWeight: FontWeight.w300,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),

                            const Spacer(),

                            // Amount Info with reduced spacing
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "المبلغ المطلوب:",
                                        style: TextStyle(
                                          fontSize: 11, // Reduced from 12
                                          color: textColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        requiredCash == 0
                                            ? "لا يوجد مستحقات"
                                            : "$requiredCash جنيهاً",
                                        style: TextStyle(
                                          fontSize: 14, // Reduced from 16
                                          color: textColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Replace the "More" button with just padding
                                const SizedBox(width: 8),
                              ],
                            ),

                            const SizedBox(height: 4), // Reduced from 6

                            // Phone Number Row with reduced spacing
                            SizedBox(
                              height: 24, // Fixed height for phone row
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Icon(Icons.phone,
                                      color: textColor,
                                      size: 14), // Reduced from 16
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      phoneNumber,
                                      style: TextStyle(
                                        fontSize: 12, // Reduced from 14
                                        color: textColor,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // Copy Icon Button
                                  IconButton(
                                    icon: Icon(Icons.copy,
                                        color: textColor, size: 18),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      if (phoneNumber.isNotEmpty &&
                                          phoneNumber != 'لا يوجد رقم') {
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

                                  // Edit Icon Button (only for non-assistant roles)
                                  if (SupabaseAuthentication.myUser!.role !=
                                      UserRoles.assistant.index)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(left: 12.0),
                                      child: IconButton(
                                        icon: Icon(Icons.edit,
                                            color: textColor, size: 18),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () async {
                                          await clientEditModelSheet(context,
                                              client: widget.client);
                                        },
                                      ),
                                    ),
                                ],
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
          child: SizedBox(
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
