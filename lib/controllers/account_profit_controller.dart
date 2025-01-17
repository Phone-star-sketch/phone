import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/controllers/account_client_info_data.dart';
import 'package:phone_system_app/controllers/money_display_loading.dart';
import 'package:phone_system_app/models/account.dart';
import 'package:phone_system_app/models/profit.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';

class ProfitController extends GetxController {
  final Map<int, String> months = {
    1: 'يناير',
    2: 'فبراير',
    3: 'مارس',
    4: 'ابريل',
    5: 'مايو',
    6: 'يونيو',
    7: 'يوليو',
    8: 'اغسطس',
    9: 'سبتمبر',
    10: 'اكتوبر',
    11: 'نوفمبر',
    12: 'ديسمبر',
  };

  Map<String, int> monthsToInt = {};

  late Rx<MonthlyProfit> currentProfitCalculations;

  static ProfitController get to => Get.put(ProfitController());

  final yearController = TextEditingController(text: "2024");
  final monthController = TextEditingController();
  final totalIncomeController = TextEditingController();
  final discountController = TextEditingController();

  List<MonthlyProfit> profits = <MonthlyProfit>[].obs;

  @override
  void onInit() async {
    super.onInit();
    monthsToInt = Map.fromIterables(months.values, months.keys);

    final currentYear = DateTime.now().year;
    final currentMonth = DateTime.now().month;

    yearController.text = currentYear.toString();
    monthController.text = months[currentMonth].toString();
  }

  Future<void> updateTheProfitByAccount(Account account) async {
    Loaders.to.typesIsLoading.value = true;
    profits = await BackendServices.instance.profitRepository
        .getAllMonthlyProfitByAccount(account);

    onMonthOrYearSelected(null);
    Loaders.to.typesIsLoading.value = false;
  }

  MonthlyProfit? getProfitByYearAndMonth(int month, int year) {
    return profits.firstWhereOrNull(
      (element) {
        return element.year == year && element.month == month;
      },
    );
  }

  void onMonthOrYearSelected(data) {
    final month = monthsToInt[monthController.text];
    final year = int.parse(yearController.text);

    final profit = getProfitByYearAndMonth(month!, year);

    if (profit != null) {
      discountController.text = (profit.discount * 100).toString();
      totalIncomeController.text = profit.totalIncome.toString();
    } else {
      discountController.text = "0";
      totalIncomeController.text = "0";
    }
  }

  Future<MonthlyProfit> onStoreClick() async {
    Loaders.to.profitLoader.value = true;

    final month = monthsToInt[monthController.text];
    final year = int.parse(yearController.text);

    MonthlyProfit? profit = await calculateTotalProfit(month!, year);

    print(profit);

    try {
      if (profit != null) {
        profit.totalIncome = double.parse(totalIncomeController.text);
        profit.discount = double.parse(discountController.text) / 100.0;
        await BackendServices.instance.profitRepository.update(profit);
      } else {
        profit = MonthlyProfit(
          id: -1,
          createdAt: DateTime.now(),
          accountId: AccountClientInfo.to.currentAccount.id,
          totalCollected: 0,
          totalReminder: 0,
          expectedToBeCollected: 0,
          totalIncome: double.parse(totalIncomeController.text),
          discount: double.parse(discountController.text) / 100,
          year: int.parse(yearController.text),
          month: monthsToInt[monthController.text]!,
        );
        await BackendServices.instance.profitRepository.create(profit);
      }
    } catch (e) {
      Get.showSnackbar(GetSnackBar(
        title: "Error",
        message: e.toString(),
      ));
    }

    Loaders.to.profitLoader.value = false;

    return profit!;
  }

  DateTime? getLastMonthToBePaid() {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    //---------------------------------------------

    final filterdProfits = profits
        .where(
          (element) =>
              element.month <= currentMonth && element.year <= currentYear,
        )
        .toList();

    filterdProfits.sort((a, b) {
      if (a.year < b.year) {
        return 1;
      } else if (a.year > b.year) {
        return -1;
      } else {
        if (a.month < b.month) {
          return 1;
        } else {
          return -1;
        }
      }
    });

    //-------------------------------------------------------------

    final p = (filterdProfits.isNotEmpty) ? filterdProfits[0] : null;

    if (p != null) {
      return DateTime(p.year, p.month, AccountClientInfo.to.currentAccount.day);
    } else {
      return null;
    }
  }

  DateTime getNextMonthToBePaid() {
    DateTime? lastMonth = getLastMonthToBePaid();
    if (lastMonth != null) {
      final nextMonth = lastMonth.add(const Duration(days: 31));
      if (nextMonth.isAfter(DateTime.now())) {
        return lastMonth;
      } else {
        return nextMonth;
      }
    } else {
      final now = DateTime.now();
      final currentMonth = now.month;
      final currentYear = now.year;
      final currentDay = now.day;

      if (currentDay > AccountClientInfo.to.currentAccount.day + 5) {
        return DateTime(currentYear, currentMonth);
      } else {
        return DateTime(currentYear, currentMonth, 4)
            .subtract(const Duration(days: 31));
      }
    }
  }

  DateTime currentMonth() {
    final now = DateTime.now();
    final beforeNow = now.subtract(const Duration(days: 33));

    final month = now.month;
    final year = now.year;

    final beforeMonth = beforeNow.month;
    final beforeYear = beforeNow.year;

    final startingDay = AccountClientInfo.to.currentAccount.day;

    final before = DateTime(beforeYear, beforeMonth, startingDay);
    final center = DateTime(year, month, startingDay);

    if (now.isAfter(before) && now.isBefore(center)) {
      return before;
    } else {
      return center;
    }
  }

  Future<MonthlyProfit?> calculateTotalProfit(int month, int year) async {
    final logs =
        await BackendServices.instance.logRepository.getLogsByMatchMapQuery({
      'month': month,
      'year': year,
      'account_id': AccountClientInfo.to.currentAccount.id
    });

    MonthlyProfit? profit = getProfitByYearAndMonth(month, year);

    if (profit != null) {
      profit.totalCollected = (logs.isNotEmpty)
          ? logs
              .map(
                (e) => e.paid,
              )
              .reduce(
                (value, element) => value! + element!,
              )!
          : 0;
      profit.totalReminder = (logs.isNotEmpty)
          ? logs
              .map(
                (e) => e.reminder,
              )
              .reduce(
                (value, element) => value! + element!,
              )!
          : 0;
      profit.expectedToBeCollected = (logs.isNotEmpty)
          ? logs
              .map(
                (e) => e.price,
              )
              .reduce(
                (value, element) => value + element,
              )
          : 0;
      await BackendServices.instance.profitRepository.update(profit);
    }
    return profit;
  }
}
