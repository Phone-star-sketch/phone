import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/controllers/account_profit_controller.dart';
import 'package:phone_system_app/controllers/money_display_loading.dart';
import 'package:phone_system_app/models/account.dart';
import 'package:phone_system_app/models/client.dart';
import 'package:phone_system_app/models/log.dart';
import 'package:phone_system_app/models/phone_number.dart';
import 'package:phone_system_app/repositories/client/supabase_client_repository.dart';
import 'package:phone_system_app/services/backend/auth.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';
import 'package:phone_system_app/views/pages/profit_management_page.dart';
import 'package:phone_system_app/utils/arabic_utils.dart';

class AccountClientInfo extends GetxController {
  Account currentAccount;
  TextEditingController searchController = TextEditingController();
  RxString query = "".obs;
  Timer? _searchDebounce;

  AccountClientInfo({required this.currentAccount});

  // All clients data (full list)
  RxList<Client> clinets = <Client>[].obs;
  static RxList<Map<String, dynamic>> allClients = <Map<String, dynamic>>[].obs;

  RxBool isLoading = false.obs;
  RxBool enableMulipleClientPrint = false.obs;
  RxList<Client> clientPrintAdded = <Client>[].obs;
  static AccountClientInfo get to => Get.find<AccountClientInfo>();

  // ============ PAGINATION ============
  // Number of items to show initially and load more
  static const int _pageSize = 30;

  // Current number of items being displayed
  RxInt _displayCount = 30.obs;

  // Loading state for pagination
  RxBool isLoadingMore = false.obs;

  // Get displayed clients (paginated)
  List<Client> get displayedClients {
    final allData = _getFilteredClients();
    final count = _displayCount.value.clamp(0, allData.length);
    return allData.take(count).toList();
  }

  // Check if there's more data to load
  bool get hasMoreData {
    final allData = _getFilteredClients();
    return _displayCount.value < allData.length;
  }

  // Get total count
  int get totalClientsCount => _getFilteredClients().length;

  // Get filtered clients based on search query
  List<Client> _getFilteredClients() {
    if (query.value.isEmpty) {
      return clinets;
    }

    final normalizedQuery = normalizeArabic(query.value);
    return clinets.where((client) {
      // Search in client name
      if (normalizeArabic(client.name ?? '').contains(normalizedQuery)) {
        return true;
      }
      // Search in phone numbers
      if (client.numbers != null) {
        for (var number in client.numbers!) {
          if (number.phoneNumber?.contains(normalizedQuery) ?? false) {
            return true;
          }
        }
      }
      return false;
    }).toList();
  }

  // Load more clients
  void loadMore() {
    if (isLoadingMore.value || !hasMoreData) return;

    isLoadingMore.value = true;

    // Simulate small delay for smooth UX
    Future.delayed(const Duration(milliseconds: 100), () {
      _displayCount.value += _pageSize;
      isLoadingMore.value = false;
      update(['client-list']);

      if (kDebugMode) {
        print(
            '📜 Loaded more. Now showing: ${displayedClients.length}/${totalClientsCount}');
      }
    });
  }

  // Reset pagination (call when data changes)
  void resetPagination() {
    _displayCount.value = _pageSize;
    if (kDebugMode) {
      print('📜 Pagination reset. Showing: $_pageSize/${clinets.length}');
    }
  }
  // ============ END PAGINATION ============

  // Full data cache (lazy-loaded on demand)
  final Map<int, Client> _fullDataCache = {};
  static const int _maxCacheSize = 50;

  // Payments
  late Rx<Client> currentPayingClient;
  RxInt countPaid = 0.obs;
  RxInt countNotPaid = 0.obs;

  late StreamSubscription<List<Client>> _clientSubscription;
  Timer? _realtimeDebounce;
  List<Client>? _pendingUpdate;
  bool _isProcessingBulkOperation = false;
  DateTime? _lastRealtimeUpdate;
  static const Duration _realtimeThrottleDuration = Duration(seconds: 10);
  static const Duration _realtimeBatchWindow = Duration(seconds: 2);

  @override
  void onInit() {
    super.onInit();
    setupRealtimeSubscription();
  }

  /// Fetch full client data on demand (with caching)
  Future<Client> getFullClientData(int clientId) async {
    if (_fullDataCache.containsKey(clientId)) {
      return _fullDataCache[clientId]!;
    }

    final fullClient =
        await BackendServices.instance.clientRepository.read(clientId);
    _fullDataCache[clientId] = fullClient;

    if (_fullDataCache.length > _maxCacheSize) {
      final oldestKey = _fullDataCache.keys.first;
      _fullDataCache.remove(oldestKey);
    }

    return fullClient;
  }

  void clearFullDataCache() {
    _fullDataCache.clear();
  }

  void setupRealtimeSubscription() {
    final repository = BackendServices.instance.clientRepository;
    if (repository is SupabaseClientRepository) {
      _clientSubscription = repository
          .getBasicRealtimeClients(currentAccount)
          .listen((updatedClients) {
        if (_isProcessingBulkOperation) return;

        final now = DateTime.now();
        if (_lastRealtimeUpdate != null &&
            now.difference(_lastRealtimeUpdate!) < _realtimeThrottleDuration) {
          return;
        }

        _pendingUpdate = updatedClients;
        _realtimeDebounce?.cancel();
        _realtimeDebounce = Timer(_realtimeBatchWindow, () {
          if (_pendingUpdate != null && !_isProcessingBulkOperation) {
            clinets.value = _pendingUpdate!;
            resetPagination();
            _pendingUpdate = null;
            _lastRealtimeUpdate = DateTime.now();
            clearFullDataCache();
            update(['client-list']);
          }
        });
      });
    }
  }

  @override
  void onReady() async {
    isLoading.value = true;
    if (currentAccount.id != -1) {
      final repository = BackendServices.instance.clientRepository;
      if (repository is SupabaseClientRepository) {
        // Use optimized database function for faster loading
        final summaries = await repository.getClientsSummary(
          accountId: currentAccount.id as int,
        );
        
        // Convert summaries to basic Client objects
        clinets.value = summaries.map((summary) {
          return Client(
            id: summary.id,
            createdAt: summary.createdAt,
            name: summary.name,
            totalCash: summary.totalCash ?? 0,
            expireDate: summary.expireDate,
            accountId: summary.accountId,
            // Store phone numbers and system names for display
            numbers: summary.phoneNumbers?.map((phone) => 
              PhoneNumber(
                id: -1,
                phoneNumber: phone,
                clientId: summary.id,
                createdAt: DateTime.now(),
              )
            ).toList(),
          );
        }).toList();
      }
      resetPagination();
    }

    isLoading.value = false;
    final day = DateTime.now().day;

    if (day >= currentAccount.day &&
        SupabaseAuthentication.myUser!.role == UserRoles.manager.index) {
      await automaticPaymentAtStartup();
    }
  }

  @override
  void onClose() {
    _clientSubscription.cancel();
    _searchDebounce?.cancel();
    _realtimeDebounce?.cancel();
    _fullDataCache.clear();
    super.onClose();
  }

  // For backward compatibility
  List<Client> getCurrentClients() {
    return displayedClients;
  }

  // For backward compatibility
  List<Client> searchClients(String searchQuery) {
    if (searchQuery.isEmpty) {
      return displayedClients;
    }
    // When searching, return all matching results (not paginated)
    return _getFilteredClients();
  }

  void updateCurrnetClinets() async {
    isLoading.value = true;
    final newClinets = await BackendServices.instance.clientRepository
        .getAllClientsByAccount(currentAccount);
    clinets.clear();
    clinets.addAll(newClinets);
    resetPagination();
    searchQueryChanged(searchController.text);
    isLoading.value = false;
  }

  void searchQueryChanged(String searchQuery) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      query.value = normalizeArabic(searchQuery);
      resetPagination(); // Reset pagination when search changes
      update(['client-list']);
    });
  }

  List<Client> getClients() {
    return clinets;
  }

  ProfitMeasure getProfitMeasure(int month, int year) {
    double totalMoneyExpected = 0;
    double totalMoneyCollected = 0;

    for (Client c in clinets) {
      final monthLog = c.logs!.firstWhere((element) {
        final date = element.createdAt!;
        final end = DateTime(year, month + 1, 11);
        final start = DateTime(year, month, 25);

        bool isBetween = date.isAfter(start) && date.isBefore(end);
        return element.transactionType == TransactionType.transactionDone &&
            isBetween;
      });

      totalMoneyExpected += monthLog.paid!;
      totalMoneyCollected += monthLog.reminder!;
    }

    return ProfitMeasure(
      totalMoneyCollected: totalMoneyCollected,
      totalMoneyDebt: totalMoneyExpected - totalMoneyCollected,
      totalExpectedMoneyToBeCollected: totalMoneyCollected,
    );
  }

  Future<void> balanceAllClientsData() async {
    final clients = clinets;
    final total = clinets.length;

    if (kDebugMode) {
      print("the total number is ${clinets.length}");
    }

    int count = 0;

    for (final c in clients) {
      final logs = c.logs;
      double newBalance = 0;

      for (final l in logs!) {
        if (l.transactionType == TransactionType.transactionDone) {
          newBalance -= l.price;
        } else {
          newBalance += l.price;
        }
      }
      c.totalCash = newBalance;
      BackendServices.instance.clientRepository.update(c);
      count += 1;
      if (kDebugMode) {
        print("$count of $total");
      }
    }
  }

  Future<void> automaticPaymentAtStartup() async {
    try {
      _isProcessingBulkOperation = true;
      Loaders.to.paymentIsLoading.value = true;

      if (kDebugMode) {
        print(" the length is ${clinets.length}");
      }

      countPaid.value = 0;
      countNotPaid.value = 0;

      final next = ProfitController.to.currentMonth();
      final month = next.month;
      final year = next.year;

      final toBePaidClients = <Client>[];

      for (Client client in clinets) {
        currentPayingClient = client.obs;

        final payment = client.logs!.firstWhereOrNull(
          (element) =>
              element.month! == month &&
              element.year! == year &&
              element.transactionType == TransactionType.transactionDone,
        );
        if (payment == null) {
          toBePaidClients.add(client);
        }
      }

      countPaid.value = clinets.length - toBePaidClients.length;

      for (Client client in toBePaidClients) {
        currentPayingClient = client.obs;
        countPaid++;

        await BackendServices.instance.clientRepository
            .paySystemsBills(client, month, year);

        final index = clinets.indexWhere((c) => c.id == client.id);
        if (index != -1) {
          double bills = client.systemsCost();

          if (client.discountPercentage != null &&
              client.discountEndDate != null &&
              client.discountEndDate!.isAfter(DateTime.now())) {
            double discountAmount = bills * (client.discountPercentage! / 100);
            bills -= discountAmount;
          }

          clinets[index].totalCash = clinets[index].totalCash - bills;
        }
      }

      clinets.refresh();
      await _refreshClientsAfterBulkOperation();

      Loaders.to.paymentIsLoading.value = false;
      _isProcessingBulkOperation = false;
    } catch (e) {
      _isProcessingBulkOperation = false;
      Loaders.to.paymentIsLoading.value = false;

      Get.showSnackbar(GetSnackBar(
        message: e.toString(),
        title: "حدثت مشكلة اثناء الدفع الالي ",
      ));
    }
  }

  Future<void> _refreshClientsAfterBulkOperation() async {
    try {
      final repository = BackendServices.instance.clientRepository;
      if (repository is SupabaseClientRepository) {
        // Use optimized function for refresh too
        final summaries = await repository.getClientsSummary(
          accountId: currentAccount.id as int,
        );
        
        clinets.value = summaries.map((summary) {
          return Client(
            id: summary.id,
            createdAt: summary.createdAt,
            name: summary.name,
            totalCash: summary.totalCash ?? 0,
            expireDate: summary.expireDate,
            accountId: summary.accountId,
            numbers: summary.phoneNumbers?.map((phone) => 
              PhoneNumber(
                id: -1,
                phoneNumber: phone,
                clientId: summary.id,
                createdAt: DateTime.now(),
              )
            ).toList(),
          );
        }).toList();
        resetPagination();
        clearFullDataCache();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error refreshing clients after bulk operation: $e');
      }
    }
  }

  Future<void> fetchClients() async {
    try {
      isLoading.value = true;
      final newClients = await BackendServices.instance.clientRepository
          .getAllClientsByAccount(currentAccount)
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () => throw Exception('Request timed out'),
          );
      clinets.value = newClients;
      resetPagination();
      isLoading.value = false;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching clients: $e');
      }
      isLoading.value = false;

      String errorMessage = 'حدث خطأ أثناء تحميل بيانات العملاء';
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection') ||
          e.toString().contains('timed out')) {
        errorMessage = 'فشل الاتصال بالخادم. يرجى التحقق من اتصال الإنترنت.';
      }

      Get.snackbar(
        'خطأ',
        errorMessage,
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> getAllClients() async {
    try {
      final allClientsData =
          await BackendServices.instance.clientRepository.getAllClientsData();
      allClients.value = allClientsData;
      if (kDebugMode) {
        print("Fetched ${allClientsData.length} total clients");
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching all clients: $e');
      }
    }
  }

  void toggleMultiSelection() {
    enableMulipleClientPrint.value = !enableMulipleClientPrint.value;
    if (!enableMulipleClientPrint.value) {
      clientPrintAdded.clear();
    }
    update(['toolbar', 'client-list']);
  }

  void selectClient(Client client) {
    if (!clientPrintAdded.contains(client)) {
      clientPrintAdded.add(client);
    }
  }

  void unselectClient(Client client) {
    clientPrintAdded.remove(client);
  }

  void clearSelections() {
    clientPrintAdded.clear();
  }
}
