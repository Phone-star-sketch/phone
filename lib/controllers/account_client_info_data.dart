import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/controllers/account_profit_controller.dart';
import 'package:phone_system_app/controllers/account_view_controller.dart';
import 'package:phone_system_app/controllers/money_display_loading.dart';
import 'package:phone_system_app/models/account.dart';
import 'package:phone_system_app/models/client.dart';
import 'package:phone_system_app/models/log.dart';
import 'package:phone_system_app/services/backend/auth.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';
import 'package:phone_system_app/utils/string_utils.dart';
import 'package:phone_system_app/views/pages/profit_management_page.dart';
import 'package:phone_system_app/utils/arabic_normalizer.dart';

class AccountClientInfo extends GetxController {
  Account currentAccount;
  TextEditingController searchController = TextEditingController();
  RxString query = "".obs;

  AccountClientInfo({required this.currentAccount});

  RxList<Client> clinets = <Client>[].obs;
  static RxList<Map<String, dynamic>> allClients = <Map<String, dynamic>>[].obs;
  List<Client> _queryClinets = <Client>[].obs;
  RxBool isLoading = false.obs;
  RxBool enableMulipleClientPrint = false.obs;
  RxList<Client> clientPrintAdded = <Client>[].obs;
  static AccountClientInfo get to => Get.find<AccountClientInfo>();

  // Payments

  late Rx<Client> currentPayingClient;
  RxInt countPaid = 0.obs;
  RxInt countNotPaid = 0.obs;

  @override
  void onReady() async {
    isLoading.value = true;
    if (currentAccount.id != -1) {
      clinets.value = await BackendServices.instance.clientRepository
          .getAllClientsByAccount(currentAccount);
    }

    isLoading.value = false;
    final day = DateTime.now().day;

    if (day >= currentAccount.day && SupabaseAuthentication.myUser!.role == UserRoles.manager.index) {
      await automaticPaymentAtStartup();
    }
  }

  List<Client> getCurrentClients() {
    return _queryClinets;
  }

  void updateCurrnetClinets() async {
    isLoading.value = true;
    final newClinets = await BackendServices.instance.clientRepository
        .getAllClientsByAccount(currentAccount);
    clinets.clear();
    clinets.addAll(newClinets);
    _queryClinets.clear();
    final currentQuery = query.value;
    query.value = "";
    query.value = currentQuery;
    searchQueryChanged(searchController.text);
    isLoading.value = false;
  }

  void searchQueryChanged(String newQuery) {
    query.value = newQuery;
    if (newQuery == "") {
      _queryClinets.clear();
      return;
    }
    final normalizedQuery = normalizeArabicText(newQuery.replaceAll(' ', ''));
    final results = clinets
        .where((client) {
          final normalizedClientName = normalizeArabicText(client.name?.replaceAll(' ', '') ?? '');
          final normalizedPhoneNumber = normalizeArabicText(client.numbers?[0].phoneNumber ?? '');
          return normalizedClientName.contains(normalizedQuery) ||
              normalizedPhoneNumber.contains(normalizedQuery);
        })
        .toList();
    _queryClinets.clear();
    _queryClinets.addAll(results);
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

    print("the total number is ${clinets.length}"); 

    int count = 0;

    for(final c in clients){ 
      final logs = c.logs;
      double newBalance = 0;  

      for (final l in logs!){
        if (l.transactionType == TransactionType.transactionDone){
          newBalance-= l.price; 
        }
        else {
          newBalance += l.price; 
        }
      }
      c.totalCash = newBalance; 
      BackendServices.instance.clientRepository.update(c); 
      count += 1; 
      print("$count of $total"); 
    }
  }

  Future<void> automaticPaymentAtStartup() async {
    try {
      Loaders.to.paymentIsLoading.value = true;

      print(" the length is ${clinets.length}");

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
      }
      Loaders.to.paymentIsLoading.value = false;
    } catch (e) {
      Loaders.to.paymentIsLoading.value = false;

      Get.showSnackbar(GetSnackBar(
        message: e.toString(),
        title: "حدثت مشكلة اثناء الدفع الالي ",
      ));
    }
  }
}
