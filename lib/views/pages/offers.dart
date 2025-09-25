import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/controllers/account_client_info_data.dart';
import 'package:phone_system_app/models/client.dart';
import 'package:phone_system_app/models/system.dart';
import 'package:phone_system_app/models/system_type.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';
import 'package:phone_system_app/utils/string_utils.dart';
import 'package:phone_system_app/views/bottom_sheet_dialogs/show_client_info_sheet.dart';
import 'package:phone_system_app/views/client_list_view.dart';
import 'package:phone_system_app/views/pages/all_clinets_page.dart';
import 'package:phone_system_app/views/pages/dues_management.dart';
import 'package:intl/intl.dart';
import 'package:phone_system_app/utils/arabic_normalizer.dart';
import 'package:phone_system_app/repositories/system/supabase_system_repository.dart';
import 'package:phone_system_app/views/widgets/custom_toolbar.dart';

class OfferManagement extends StatelessWidget {
  final controller = Get.find<AccountClientInfo>();

  void _navigateToExpiredSystems(BuildContext context, List<Client> clients) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Ensure clean navigation
      await Get.delete<ExpiredSystemsController>(force: true);

      Get.to(
        () => ExpiredSystemsPage(clients: clients),
        preventDuplicates: true,
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 300),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final q = controller.query.value;

      final printingClients = controller.clientPrintAdded.value;
      // Only show offers that have already expired
      List<Client> clients = controller.clinets.value
          .where((element) =>
              element.expireDate != null &&
              element.expireDate!.isBefore(DateTime.now()) && // Only past dates
              element.expireDate!
                  .isAfter(DateTime.now().subtract(const Duration(days: 10))))
          .toList();

      if (q != "") {
        clients = clients
            .where((element) =>
                element.numbers![0].phoneNumber!.contains(q) ||
                removeSpecialArabicChars(element.name!)
                    .contains(removeSpecialArabicChars(q)))
            .toList();
      }

      final totalCash = (clients.isNotEmpty)
          ? clients
              .map(
                (e) => e.totalCash,
              )
              .reduce(
                (value, element) => value + element,
              )
          : 0;

      final expiredSystemsClients = controller.clinets.value
          .where((client) =>
              client.expireDate != null &&
              client.expireDate!.isBefore(DateTime.now()) && // Only past dates
              client.numbers!
                  .any((number) => number.getExpiredSystems().isNotEmpty))
          .toList();

      // Update the explanatory text
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.shade100,
                              Colors.orange.shade50
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "العملاء المنتهية عروضهم",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  "${clients.length}",
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                                const Text(
                                  " عميل",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        _navigateToExpiredSystems(
                            context, expiredSystemsClients);
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.card_giftcard_rounded),
                      label: const Text(
                        "العروض المطلوبة",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                CustomToolbar(
                  controller: controller,
                  printingClients: printingClients,
                ),
              ],
            ),
          ),
          Expanded(
              child: ClientListView(
            data: clients,
            isLoading: controller.isLoading.value,
            query: controller.query.value,
          ))
        ],
      );
    });
  }
}

class ExpiredSystemsController extends GetxController {
  final RxString searchQuery = ''.obs;
  final RxList<Client> allFilteredClients = <Client>[].obs;
  final RxInt totalExpiredSystems = 0.obs;
  final RxInt totalNoExpirySystems = 0.obs;
  List<Client>? allClients = <Client>[].obs;

  Future<void> fetchClients() async {
    var clients = await BackendServices.instance.clientRepository
        .getAllClientsByAccount(Get.put(AccountClientInfo.to).currentAccount);

    // Combine both expired and no expiry clients
    var expiredClients = clients
        .where((client) =>
            client.expireDate != null &&
            client.expireDate!.isBefore(DateTime.now()) &&
            client.numbers!
                .any((number) => number.getExpiredSystems().isNotEmpty))
        .toList();

    var noExpiryClients = clients
        .where((client) =>
            client.expireDate == null &&
            client.numbers!
                .any((number) => number.getExpiredSystems().isNotEmpty))
        .toList();

    // Combine all clients
    allClients = [...expiredClients, ...noExpiryClients];
    allFilteredClients.value = allClients!;
    _updateTotalSystems();
  }

  void initializeWithClients(List<Client> clients) {
    var expiredClients = clients
        .where((client) =>
            client.expireDate != null &&
            client.expireDate!.isBefore(DateTime.now()) &&
            client.numbers!
                .any((number) => number.getExpiredSystems().isNotEmpty))
        .toList();

    var noExpiryClients = clients
        .where((client) =>
            client.expireDate == null &&
            client.numbers!
                .any((number) => number.getExpiredSystems().isNotEmpty))
        .toList();

    allClients = [...expiredClients, ...noExpiryClients];
    allFilteredClients.value = allClients!;
    _updateTotalSystems();
  }

  void _updateTotalSystems() {
    totalExpiredSystems.value = allFilteredClients
        .where((client) =>
            client.expireDate != null &&
            client.expireDate!.isBefore(DateTime.now()))
        .fold<int>(0, (sum, client) => sum + _countExpiredSystems(client));

    totalNoExpirySystems.value = allFilteredClients
        .where((client) => client.expireDate == null)
        .fold<int>(0, (sum, client) => sum + _countExpiredSystems(client));
  }

  int _countExpiredSystems(Client client) {
    return client.numbers!.fold<int>(
      0,
      (sum, number) => sum + number.getExpiredSystems().length,
    );
  }

  void updateSearch(String query) {
    searchQuery.value = query;
    if (query.isEmpty) {
      allFilteredClients.value = allClients!;
    } else {
      final normalized = removeSpecialArabicChars(query.toLowerCase());
      allFilteredClients.value = allClients!
          .where((client) => _matchesSearch(client, normalized))
          .toList();
    }
    _updateTotalSystems();
  }

  bool _matchesSearch(Client client, String normalized) {
    return removeSpecialArabicChars(client.name!.toLowerCase())
            .contains(normalized) ||
        client.numbers!.any((number) =>
            number.phoneNumber != null &&
            number.phoneNumber!.contains(normalized));
  }
}

class ExpiredSystemsPage extends StatefulWidget {
  final List<Client> clients;

  ExpiredSystemsPage({required this.clients});

  @override
  _ExpiredSystemsPageState createState() => _ExpiredSystemsPageState();
}

class _ExpiredSystemsPageState extends State<ExpiredSystemsPage> {
  final controller = Get.put(ExpiredSystemsController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initializeWithClients(widget.clients);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: IconThemeData(color: Colors.black),
          title: Text(
            "العروض المطلوبة",
            style: TextStyle(color: Colors.black),
          ),
        ),
        body: SafeArea(
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                // Summary Cards
                Container(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Obx(() => Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.red.shade100,
                                    Colors.red.shade50
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    "العروض المنتهية",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade800,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "${controller.totalExpiredSystems}",
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                  Text(
                                    "نظام",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.red.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Obx(() => Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.orange.shade100,
                                    Colors.orange.shade50
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    "غير متوفر",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade800,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "${controller.totalNoExpirySystems}",
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  Text(
                                    "نظام",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ),
                    ],
                  ),
                ),
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    color: Colors.white,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            onChanged: controller.updateSearch,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey[200],
                              labelText: 'بحث',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Obx(() => Text(
                                'العدد: ${controller.allFilteredClients.length}',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              )),
                        ),
                      ],
                    ),
                  ),
                ),
                // Client Cards List
                Expanded(
                  child: Obx(() => ListView.builder(
                        itemCount: controller.allFilteredClients.length,
                        itemBuilder: (context, index) {
                          final client = controller.allFilteredClients[index];
                          return _buildClientCard(client, context);
                        },
                      )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClientCard(Client client, BuildContext context) {
    bool hasExpiredDate = client.expireDate != null &&
        client.expireDate!.isBefore(DateTime.now());
    bool isNoExpiry = client.expireDate == null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Stack(
        children: [
          Card(
            color: Colors.white,
            elevation: 3,
            shadowColor: Colors.blue.withOpacity(0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(
                color: hasExpiredDate
                    ? Colors.red.withOpacity(0.3)
                    : Colors.orange.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
                colorScheme: ColorScheme.light(
                  primary: hasExpiredDate
                      ? Colors.red.shade700
                      : Colors.orange.shade700,
                ),
              ),
              child: ExpansionTile(
                backgroundColor: Colors.white,
                collapsedBackgroundColor: Colors.white,
                leading: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: hasExpiredDate
                          ? [Colors.red.shade100, Colors.red.shade200]
                          : [Colors.orange.shade100, Colors.orange.shade200],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (hasExpiredDate ? Colors.red : Colors.orange)
                            .withOpacity(0.2),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    radius: 25,
                    child: Icon(
                      Icons.person,
                      color: hasExpiredDate
                          ? Colors.red.shade700
                          : Colors.orange.shade700,
                      size: 28,
                    ),
                  ),
                ),
                title: Text(
                  client.name!,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                    color: hasExpiredDate
                        ? Colors.red.shade900
                        : Colors.orange.shade900,
                    letterSpacing: 0.3,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.system_update_alt,
                            size: 16,
                            color: hasExpiredDate
                                ? Colors.red.shade800
                                : Colors.orange.shade800),
                        SizedBox(width: 4),
                        Text(
                          'الأنظمة المطلوبة: ${client.numbers!.fold<int>(0, (sum, number) => sum + number.getExpiredSystems().length)}',
                          style: TextStyle(
                            color: hasExpiredDate
                                ? Colors.red.shade800
                                : Colors.orange.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.event,
                            size: 16, color: Colors.grey.shade700),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'تاريخ المتابعة: ${hasExpiredDate ? fullExpressionArabicDate(client.expireDate!) : "غير متوفر"}',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: Container(
                  decoration: BoxDecoration(
                    color: hasExpiredDate
                        ? Colors.red.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.edit_calendar,
                        color: hasExpiredDate
                            ? Colors.red.shade700
                            : Colors.orange.shade700,
                        size: 20),
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: client.expireDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        try {
                          await BackendServices.instance.clientRepository
                              .updateClientInSupabase(client.id.toString(),
                                  {'expire_date': picked.toIso8601String()});

                          client.expireDate = picked;
                          await controller.fetchClients();

                          final mainController = Get.find<AccountClientInfo>();
                          await mainController.getClients();

                          Get.snackbar(
                            'تم التحديث',
                            'تم تحديث تاريخ المتابعة بنجاح',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        } catch (e) {
                          Get.snackbar(
                            'خطأ',
                            'حدث خطأ أثناء تحديث التاريخ',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red[100],
                          );
                          print('Error updating expire date: $e');
                        }
                      }
                    },
                  ),
                ),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.grey.shade50,
                          Colors.white,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: EdgeInsets.all(12),
                    child: Column(
                      children: client.numbers!.map((number) {
                        final systems = number.systems ?? [];
                        if (systems.isEmpty) return SizedBox.shrink();

                        return Container(
                          margin: EdgeInsets.all(8),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                spreadRadius: 0,
                                offset: Offset(0, 2),
                              ),
                            ],
                            border: Border.all(
                              color: hasExpiredDate
                                  ? Colors.red.shade100
                                  : Colors.orange.shade100,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: hasExpiredDate
                                          ? Colors.red.shade50
                                          : Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(Icons.phone_android,
                                        color: hasExpiredDate
                                            ? Colors.red.shade700
                                            : Colors.orange.shade700,
                                        size: 20),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    number.phoneNumber ?? '',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: hasExpiredDate
                                          ? Colors.red.shade700
                                          : Colors.orange.shade700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Spacer(),
                                  IconButton(
                                    icon: Icon(Icons.copy,
                                        color: hasExpiredDate
                                            ? Colors.red.shade400
                                            : Colors.orange.shade400),
                                    onPressed: () {
                                      if (number.phoneNumber != null) {
                                        Clipboard.setData(ClipboardData(
                                            text: number.phoneNumber!));
                                        Get.snackbar(
                                          'تم النسخ',
                                          'تم نسخ الرقم بنجاح',
                                          snackPosition: SnackPosition.BOTTOM,
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                              Divider(
                                  height: 20,
                                  color: hasExpiredDate
                                      ? Colors.red.shade50
                                      : Colors.orange.shade50),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: systems.map((system) {
                                  if (system.type!.category ==
                                      SystemCategory.mobileInternet) {
                                    if (system.createdAt != null) {
                                      final collectionDay = AccountClientInfo
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

                                  return Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: hasExpiredDate
                                            ? [
                                                Colors.red.shade50,
                                                Colors.red.shade100
                                              ]
                                            : [
                                                Colors.orange.shade50,
                                                Colors.orange.shade100
                                              ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: hasExpiredDate
                                            ? Colors.red.shade200
                                            : Colors.orange.shade200,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          system.type!.name!,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: hasExpiredDate
                                                ? Colors.red.shade900
                                                : Colors.orange.shade900,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        IconButton(
                                          icon: Icon(Icons.edit,
                                              size: 18,
                                              color: hasExpiredDate
                                                  ? Colors.red.shade700
                                                  : Colors.orange.shade700),
                                          onPressed: () =>
                                              _showEditSystemDialog(system),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Flag indicator
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: hasExpiredDate ? Colors.red : Colors.orange,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: (hasExpiredDate ? Colors.red : Colors.orange)
                        .withOpacity(0.3),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    hasExpiredDate ? Icons.schedule : Icons.help_outline,
                    color: Colors.white,
                    size: 16,
                  ),
                  SizedBox(width: 4),
                  Text(
                    hasExpiredDate ? "منتهي" : "غير متوفر",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditSystemDialog(System system) {
    showEditSystemDialog(system);
  }
}
