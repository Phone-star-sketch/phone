import 'package:get/get_connect/http/src/request/request.dart';
import 'package:phone_system_app/models/account.dart';
import 'package:phone_system_app/models/model.dart';

class MonthlyProfit extends Model {
  static const profitTableName = "month_profit";
  static const yearColumnName = "year";
  static const monthColumnName = "month";
  static const incomeColumnName = "income";
  static const collectedColumnName = "collected";
  static const expectedColumnName = "expected";
  static const reminderColumnName = "reminder";
  static const discountColumnName = "discount";
  static const accountColumnName = "account_id";

  int month;
  int year;
  double totalIncome;
  double totalReminder;
  double totalCollected;
  double expectedToBeCollected;
  double discount;
  Object? accountId;

  MonthlyProfit({
    required super.id,
    super.createdAt,
    required this.totalCollected,
    required this.totalIncome,
    required this.totalReminder,
    required this.year,
    required this.month,
    required this.expectedToBeCollected,
    this.accountId,
    this.discount = 0.0,
  });

  MonthlyProfit.fromJson(super.data)
      : totalCollected = (data[collectedColumnName]).toDouble(),
        totalIncome = (data[incomeColumnName]).toDouble(),
        year = (data[yearColumnName]).toInt(),
        expectedToBeCollected = data[expectedColumnName].toDouble(),
        month = (data[monthColumnName]).toInt(),
        totalReminder = (data[reminderColumnName]).toDouble(),
        accountId = data[accountColumnName] as Object,
        discount = (data[discountColumnName]).toDouble(),
        super.fromJson();

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      discountColumnName: discount,
      monthColumnName: month,
      yearColumnName: year,
      expectedColumnName: expectedToBeCollected,
      reminderColumnName: totalReminder,
      accountColumnName: accountId,
      incomeColumnName: totalIncome,
      collectedColumnName: totalCollected,
    };
  }
}
