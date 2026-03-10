import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/controllers/account_client_info_data.dart';
import 'package:phone_system_app/controllers/account_profit_controller.dart';
import 'package:phone_system_app/models/account.dart';
import 'package:phone_system_app/models/profit.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';

class AccountViewController extends GetxController {
  static RxList<Account> accounts = <Account>[].obs;

  Rx<bool> isLoading = false.obs;
  final showWelcome = true.obs;

  @override
  void onInit() {
    super.onInit();
    _initAsync();
  }

  void _initAsync() {
    try {
      final next = ProfitController.to.getNextMonthToBePaid();
      final month = next.month;
      final year = next.year;

      print("$month $year");
    } catch (e) {
      print(e);
    }
  }

  checkSystemBillsByYearsAndMonths(int month, int year) async {
    if (!Get.isRegistered<AccountClientInfo>()) return;
    final clientController = Get.find<AccountClientInfo>();
    final logs =
        await BackendServices.instance.logRepository.getLogsByMatchMapQuery({
      "account_id": clientController.currentAccount.id,
      "month": month,
      "year": year
    });

    final totalCollected =
        logs.map((e) => e.paid).reduce((value, element) => value! + element!);

    final totalRequired =
        logs.map((e) => e.price).reduce((value, element) => value + element);

    final totalReminder = logs
        .map((e) => e.reminder)
        .reduce((value, element) => value! + element!);

    final profit = MonthlyProfit(
      id: -1,
      totalReminder: totalReminder!,
      expectedToBeCollected: totalRequired,
      accountId: AccountClientInfo.to.currentAccount.id,
      discount: 0,
      createdAt: DateTime.now(),
      totalCollected: totalCollected!,
      totalIncome: totalRequired,
      year: year,
      month: month,
    );
  }

  @override
  void onReady() async {
    super.onReady();
    await fetchAccountsWithRetry();
  }

  Future<void> fetchAccountsWithRetry({int maxRetries = 3}) async {
    isLoading.value = true;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        accounts.value =
            await BackendServices.instance.accountRepository.getAllAccounts();
        isLoading.value = false;
        return; // Success, exit the retry loop
      } catch (e) {
        retryCount++;
        print('Error fetching accounts (attempt $retryCount/$maxRetries): $e');

        if (retryCount >= maxRetries) {
          isLoading.value = false;
          Get.snackbar(
            'خطأ في الاتصال',
            'فشل الاتصال بالخادم. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.',
            backgroundColor: Get.theme.colorScheme.error.withOpacity(0.9),
            colorText: Colors.white,
            duration: const Duration(seconds: 5),
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(16),
            mainButton: TextButton(
              onPressed: () => fetchAccountsWithRetry(),
              child: const Text(
                'إعادة المحاولة',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          );
          break;
        }

        // Wait before retrying (exponential backoff)
        await Future.delayed(Duration(seconds: retryCount * 2));
      }
    }
  }

  List<Account> getCurrentAccounts() {
    return accounts;
  }

  Future<List<Account>> getAccounts() async {
    isLoading.value = true;
    final fetchedAccounts =
        await BackendServices.instance.accountRepository.getAllAccounts();
    isLoading.value = false;
    accounts.clear();
    accounts.addAll(fetchedAccounts);
    return fetchedAccounts;
  }

  Future<void> refreshAccounts() async {
    isLoading.value = true;
    try {
      final data = await BackendServices.instance.accountRepository.getAllAccounts();
      accounts.value = data;
    } catch (e) {
      print('Error refreshing accounts: $e');
      Get.snackbar(
        'خطأ في التحديث',
        'فشل تحديث البيانات: ${e.toString()}',
        backgroundColor: Get.theme.colorScheme.error.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
