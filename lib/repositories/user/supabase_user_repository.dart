import 'package:get/get.dart';
import 'package:phone_system_app/models/phone_number.dart';
import 'package:phone_system_app/models/system.dart';
import 'package:phone_system_app/models/user.dart';
import 'package:phone_system_app/repositories/crud_mixin.dart';
import 'package:phone_system_app/repositories/system/system_repository.dart';
import 'package:phone_system_app/repositories/user/user_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseUserRepository extends UserRepository
    with CrudOperations<System> {
  static const String tableName = "users";

  final client = Supabase.instance.client;

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
        title: "Error with creating a user",
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
  Future<List<AppUser>> getAllUsers() async {
    final values = await client.from(tableName).select();
    return values.map((row) => AppUser.fromJson(row)).toList();
  }

  @override
  Future<AppUser> getCurrentUser(String uid) async {
    final values =
        await client.from(tableName).select().match({'uid': uid}).single();
    return AppUser.fromJson(values);
  }
}
