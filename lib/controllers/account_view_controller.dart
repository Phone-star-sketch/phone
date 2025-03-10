import 'package:get/get.dart';
import 'package:phone_system_app/controllers/account_client_info_data.dart';
import 'package:phone_system_app/controllers/account_profit_controller.dart';
import 'package:phone_system_app/models/account.dart';
import 'package:phone_system_app/models/log.dart';
import 'package:phone_system_app/models/profit.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';
import 'package:phone_system_app/services/backend/supabase_backend_services.dart';

class AccountViewController extends GetxController {
  static RxList<Account> accounts = <Account>[].obs;

  Rx<bool> isLoading = false.obs;
  final showWelcome = true.obs;

  @override
  void onInit() async {
    // check for all client system bills
    super.onInit();

    try {
      final next = ProfitController.to.getNextMonthToBePaid();
      final month = next.month;
      final year = next.year;

      print("${month} ${year}");
    } catch (e) {
      print(e);
    }
    // final month = next.month;
    // final year = next.year;
    //checkSystemBillsByYearsAndMonths(month, year);
  }

  checkSystemBillsByYearsAndMonths(int month, int year) async {
    final clientController = Get.find<AccountClientInfo>();
    final logs =
        await BackendServices.instance.logRepository.getLogsByMatchMapQuery({
      "account_id": AccountClientInfo.to.currentAccount.id,
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
    isLoading.value = true;

    accounts.value =
        await BackendServices.instance.accountRepository.getAllAccounts();
    isLoading.value = false;
  }

  List<Account> getCurrentAccounts() {
    return accounts;
  }

  Future<List<Account>> getAccounts() async {
    isLoading.value = true;
    final accounts =
        await BackendServices.instance.accountRepository.getAllAccounts();
    isLoading.value = false;
    accounts.clear();
    accounts.addAll(accounts);
    return accounts;
  }

  Future<void> refreshAccounts() async {
    isLoading.value = true;
    try {
      final data = await BackendServices.instance.accountRepository.getAllAccounts();
      accounts.value = data;
    } catch (e) {
      print('Error refreshing accounts: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
