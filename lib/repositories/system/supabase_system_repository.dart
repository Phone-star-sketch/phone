import 'package:get/get.dart';
import 'package:phone_system_app/models/phone_number.dart';
import 'package:phone_system_app/models/system.dart';
import 'package:phone_system_app/repositories/crud_mixin.dart';
import 'package:phone_system_app/repositories/system/system_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseSystemRepository extends SystemRepository
    with CrudOperations<System> {
  static const String tableName = "system";

  final client = Supabase.instance.client;

  @override
  Future<System> getSystemByPhoneNumber(PhoneNumber phoneNumber) async {
    final values = await client
        .from(tableName)
        .select()
        .match({'phone_id': phoneNumber.id}).single();
    return System.fromJson(values);
  }

  @override
  Future<Object> create(System item) async {
    final values = item.toJson();
    values.remove('id');

    Object id = -1;

    try {
      await client
          .from(tableName)
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

  @override
  Future<void> delete(System item) async {
    await client.from(tableName).delete().match({'id': item.id});
  }

  @override
  Future<System> read(Object id) async {
    final values =
        await client.from(tableName).select().match({'id': id}).single();
    return System.fromJson(values);
  }

  @override
  Future<void> update(System item) async {
    await client.from(tableName).update(item.toJson()).match({'id': item.id});
  }

  @override
  Future<List<Map<String,dynamic>>> getAll(String? coulmnNames) async {
    return await client
        .from(tableName)
        .select(coulmnNames??"*");
  }
}
