import 'package:get/get.dart';
import 'package:phone_system_app/models/account.dart';
import 'package:phone_system_app/repositories/account/account_repository.dart';
import 'package:phone_system_app/repositories/crud_mixin.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAccountRepository extends AccountRepository
    with CrudOperations<Account> {
  static const String tableName = "account";

  static final client = Supabase.instance.client;

  @override
  Future<List<Account>> getAllAccounts() async {
    final data =
        await client.from(SupabaseAccountRepository.tableName).select();
    return data.map((e) => Account.fromJson(e)).toList();
  }

  @override
  Future<void> delete(Account item) async {
    await client
        .from(SupabaseAccountRepository.tableName)
        .delete()
        .match({'id': item.id});
  }

  @override
  Future<Account> read(Object id) async {
    final values = await client
        .from(SupabaseAccountRepository.tableName)
        .select("*")
        .match({'id': id}).single();
    Account account = Account.fromJson(values);
    return account;
  }

  @override
  Future<void> update(Account item) async {
    await client
        .from(SupabaseAccountRepository.tableName)
        .update(item.toJson())
        .match({'id': item.id});
  }

  @override
  Future<Object> create(Account item) async {
    final values = item.toJson();
    values.remove('id');
    Object id = -1;
    try {
      await client
          .from(SupabaseAccountRepository.tableName)
          .insert(values)
          .select("id")
          .single()
          .then((value) {
        id = value['id'] as Object;
      });
    } catch (e) {
      Get.showSnackbar(GetSnackBar(
        title: "Error with creating a Log",
        message: e.toString(),
      ));
    }
    return id;
  }
}
