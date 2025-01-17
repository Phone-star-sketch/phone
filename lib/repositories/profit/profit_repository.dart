import 'package:phone_system_app/models/account.dart';
import 'package:phone_system_app/models/profit.dart';

abstract class ProfitRepository {
  Future<List<MonthlyProfit>> getAllMonthlyProfit();
  Future<List<MonthlyProfit>> getAllMonthlyProfitByAccount(Account account);
}
