import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:phone_system_app/models/account.dart';
import 'package:phone_system_app/models/profit.dart';
import 'package:phone_system_app/repositories/crud_mixin.dart';
import 'package:phone_system_app/repositories/profit/profit_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseProfitRepository extends ProfitRepository
    with CrudOperations<MonthlyProfit> {
  static const String profitTable = "month_profit";

  final _client = Supabase.instance.client;

  @override
  Future<Object> create(MonthlyProfit item) async {
    final data = item.toJson();

    data.remove('id');
    Object id = -1;

    try {
      await _client
          .from(profitTable)
          .insert(data)
          .select("id")
          .single()
          .then((value) {
        id = value['id'];
      });
    } catch (e) {
      Get.snackbar("مشكلة من استرجاع البيانات الخاصة بالربح", e.toString());
    }

    return id;
  }

  @override
  Future<void> delete(MonthlyProfit item) async {
    final id = item.id;
    try {
      _client.from(profitTable).delete().match({"id": id});
    } catch (e) {
      Get.snackbar("مشكلة اثناء حذف الربح", e.toString());
    }
  }

  @override
  Future<MonthlyProfit> read(Object id) async {
    try {
      final data = await _client
          .from(profitTable)
          .select("*")
          .match({"id": id}).single();
      return MonthlyProfit.fromJson(data);
    } catch (e) {
      Get.snackbar("مشكلة اثناء قراءة الربح", e.toString());
    }

    return MonthlyProfit(
      id: -1,
      totalCollected: 0,
      totalIncome: 0,
      totalReminder: 0,
      year: 0,
      month: 0,
      expectedToBeCollected: 0
    );
  }

  @override
  Future<void> update(MonthlyProfit item) async {
    final data = item.toJson();
    try {
      data.remove("id");
      await _client.from(profitTable).update(data).match({'id': item.id});
    } catch (e) {
            print(data); 

      Get.snackbar("مشكلة اثناء تحديث الربح", e.toString());
    }
  }

  @override
  Future<List<MonthlyProfit>> getAllMonthlyProfit() async {
    List<MonthlyProfit> dataList = [];

    try {
      final data = await _client.from(profitTable).select("*");

      dataList = data.map((profitJsonObject) {
        return MonthlyProfit.fromJson(profitJsonObject);
      }).toList();
    } catch (e) {
      print(dataList); 
      Get.showSnackbar(GetSnackBar(
        title: "حدثت مشلكة اثناء تحميل الارباح السابقة",
        message: e.toString(),
      ));
    }
    return dataList;
  }

  @override
  Future<List<MonthlyProfit>> getAllMonthlyProfitByAccount(
      Account account) async {
    List<MonthlyProfit> dataList = [];

    try {
      final data = await _client
          .from(profitTable)
          .select("*")
          .match({"account_id": account.id});
      dataList = data.map((profitJsonObject) {
        return MonthlyProfit.fromJson(profitJsonObject);
      }).toList();
    } catch (e) {
      Get.showSnackbar(GetSnackBar(
        title: "حدثت مشلكة اثناء تحميل الارباح السابقة",
        message: e.toString(),
      ));
    }
    return dataList;
  }
}
