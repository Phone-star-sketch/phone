import 'package:get/get.dart';
import 'package:phone_system_app/models/client.dart';
import 'package:phone_system_app/models/log.dart';
import 'package:phone_system_app/models/phone_number.dart';
import 'package:phone_system_app/repositories/crud_mixin.dart';
import 'package:phone_system_app/repositories/log/log_repository.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseLogRepository extends LogRepository with CrudOperations<Log> {
  static const String logTableName = "log";

  final _client = Supabase.instance.client;

  @override
  Future<Object> create(Log item) async {
    Object id = -1;
    try {
      final response = await _client.rpc('insert_log', params: {
        'p_account_id': item.accountId,
        'p_client_id': item.clientId,
        'p_phone_id': item.phoneId,
        'p_creator': item.createdBy,
        'p_price': item.price,
        'p_paid': item.paid ?? 0,
        'p_reminder': item.reminder ?? 0,
        'p_system_type': item.systemType ?? '',
        'p_transaction_type': item.transactionType?.index ?? 0,
        'p_month': item.month ?? 0,
        'p_year': item.year ?? 0,
      });
      id = response as Object;
    } catch (e) {
      Get.showSnackbar(GetSnackBar(
        title: "Error with creating a Log",
        message: e.toString(),
      ));
      rethrow;
    }
    return id;
  }

  @override
  Future<void> delete(Log item) async {
    await _client.from(logTableName).delete().match({
      'id': item.id,
    });
  }

  @override
  Future<List<Log>> getAllLogsByPhoneNumber(PhoneNumber phnoe) async {
    final data =
        await _client.from(logTableName).select().match({'phone_id': phnoe.id});

    final mappedDate = data.map((e) => Log.fromJson(e)).toList();

    return mappedDate;
  }

  @override
  Future<Log> read(Object id) async {
    final data =
        await _client.from(logTableName).select().match({'id': id}).single();

    return Log.fromJson(data);
  }

  @override
  Future<void> update(Log item) async {
    await _client.from(logTableName).select().match({'id': item.id});
  }

  @override
  Future<List<Log>> getLogsByMatchMapQuery(Map<String, Object> query , [int limit = -1]) async {
    List<Log> fetchedLogs = [];

    try {
      if (limit < 0){
      final data = await _client
          .from(logTableName)
          .select("*, users(name)")
          .match(query)
          .order("created_at");
      fetchedLogs = data.map((e) => Log.fromJson(e)).toList();
      }else {
        final data = await _client
            .from(logTableName)
            .select("*, users(name)")
            .match(query)
            .order("created_at").limit(limit);
        fetchedLogs = data.map((e) => Log.fromJson(e)).toList();
      }
    } catch (e) {
      Get.showSnackbar(GetSnackBar(
        title: "حدث مشكلة اثناء تحميل التسجيلات",
        message: e.toString(),
      ));
    }

    return fetchedLogs;
  }

  @override
  Future<void> reverseLog(Log log, Client client) async {
    try {
      final price = log.price;
      final t = log.transactionType;
      if (t == TransactionType.transactionDone) {
        client.totalCash += price;
      } else if (t == TransactionType.moneyAdded) {
        client.totalCash -= price;
      } else if (t == TransactionType.moneyDeducted) {
        client.totalCash -= price;
      }

      await BackendServices.instance.clientRepository.update(client);
      await delete(log);
    } catch (e) {
      Get.snackbar("مشكلة اثناء عكس التسجيل", e.toString());
    }
  }
}
