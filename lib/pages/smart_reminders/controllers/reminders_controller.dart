import 'package:get/get.dart';
import 'package:phone_system_app/controllers/account_client_info_data.dart';
import 'package:phone_system_app/models/client.dart';
import 'package:phone_system_app/pages/smart_reminders/services/whatsapp_service.dart';
import 'package:phone_system_app/services/analytics_service.dart';
import 'package:phone_system_app/utils/string_utils.dart';

class RemindersController extends GetxController {
  final isLoading = true.obs;
  final selectedTab = 0.obs;
  final searchQuery = ''.obs;

  // Data lists
  final debtClients = <Client>[].obs;
  final expiringClients = <Map<String, dynamic>>[].obs;

  // Stats
  final totalDebtClients = 0.obs;
  final totalExpiringClients = 0.obs;
  final totalDebtAmount = 0.0.obs;

  List<Client> get filteredDebtClients {
    if (searchQuery.value.isEmpty) return debtClients;
    final q = removeSpecialArabicChars(searchQuery.value);
    return debtClients.where((c) {
      final nameMatch =
          c.name != null && removeSpecialArabicChars(c.name!).contains(q);
      final phoneMatch = c.numbers?.isNotEmpty == true &&
          (c.numbers![0].phoneNumber?.contains(searchQuery.value) ?? false);
      return nameMatch || phoneMatch;
    }).toList();
  }

  List<Map<String, dynamic>> get filteredExpiringClients {
    if (searchQuery.value.isEmpty) return expiringClients;
    final q = removeSpecialArabicChars(searchQuery.value);
    return expiringClients.where((data) {
      final name = data['name']?.toString() ?? '';
      return removeSpecialArabicChars(name).contains(q);
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    isLoading.value = true;
    try {
      await WhatsAppService.loadTemplates();
      await Future.wait([
        _loadDebtClients(),
        _loadExpiringClients(),
      ]);
    } catch (e) {
      // Silently handle
    }
    isLoading.value = false;
  }

  Future<void> _loadDebtClients() async {
    final allClients = AccountClientInfo.to.clinets;
    // Clients with negative balance (they owe money)
    final debts = allClients.where((c) => c.totalCash < 0).toList();
    debts.sort((a, b) => a.totalCash.compareTo(b.totalCash)); // Most debt first
    debtClients.value = debts;
    totalDebtClients.value = debts.length;
    totalDebtAmount.value =
        debts.fold(0.0, (sum, c) => sum + c.totalCash.abs());
  }

  Future<void> _loadExpiringClients() async {
    try {
      final expiring = await AnalyticsService.getExpiringClients(days: 7);
      expiringClients.value = expiring;
      totalExpiringClients.value = expiring.length;
    } catch (_) {}
  }

  String getClientPhone(Client client) {
    if (client.numbers == null || client.numbers!.isEmpty) return '';
    return client.numbers![0].phoneNumber ?? '';
  }

  String getClientPackages(Client client) {
    if (client.numbers == null || client.numbers!.isEmpty) return '';
    final systems = client.numbers![0].systems;
    if (systems == null || systems.isEmpty) return '';
    return systems
        .map((s) => s.type?.name ?? '')
        .where((n) => n.isNotEmpty)
        .join('، ');
  }
}
