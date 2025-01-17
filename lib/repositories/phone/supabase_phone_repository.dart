import 'package:get/get.dart';
import 'package:phone_system_app/models/account.dart';
import 'package:phone_system_app/models/client.dart';
import 'package:phone_system_app/models/phone_number.dart';
import 'package:phone_system_app/repositories/crud_mixin.dart';
import 'package:phone_system_app/repositories/phone/phone_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabasePhoneRepository extends PhoneRepository
    with CrudOperations<PhoneNumber> {
  static const String phoneTableName = "phone";

  final _client = Supabase.instance.client;

  @override
  Future<Object> create(PhoneNumber item) async {
    final values = item.toJson();
    values.remove('id');

    Object id = -1;
    try {
      await _client
          .from(phoneTableName)
          .insert(values)
          .select("id")
          .single()
          .then((value) {
        id = value["id"] as Object;
      });
    } catch (e) {
      Get.showSnackbar(GetSnackBar(
        title: "Error with creating phone number ",
        message: e.toString(),
      ));
    }

    return id;
  }

  @override
  Future<void> delete(PhoneNumber item) async {
    await _client.from(phoneTableName).delete().match({'id': item.id});
  }

  @override
  Future<List<PhoneNumber>> getPhoneNumbersByClient(Client client) async {
    final values =
        await _client.from(phoneTableName).select().match({'id': client.id});

    final phones = values.map((e) => PhoneNumber.fromJson(e)).toList();

    return phones;
  }

  @override
  Future<PhoneNumber> read(Object id) async {
    final values =
        await _client.from(phoneTableName).select().match({'id': id}).single();
    final PhoneNumber number = PhoneNumber.fromJson(values);
    return number;
  }

  @override
  Future<void> update(PhoneNumber item) async {
    await _client
        .from(phoneTableName)
        .update(item.toJson())
        .match({'id': item.id});
  }

  @override
  Future<List<PhoneNumber>> getPhoneNumbersByMatching(
      Map<String, Object> mm) async {
    List<PhoneNumber> phones = [];

    try {
      final values = await _client.from(phoneTableName).select().match(mm);
      print(values);
      phones = values.map((e) => PhoneNumber.fromJson(e)).toList();
    } catch (e) {
      Get.snackbar("مشكلة مع الارقام المعروضة", e.toString());
    }

    return phones;
  }

  @override
  void bindStreamToForSaleNumbersChanges(
      Function(List<Map<String, dynamic>> payload) callback) {
    try {
      _client
          .from(phoneTableName)
          .stream(primaryKey: ['id'])
          .eq(PhoneNumber.forSaleColumnName, true)
          .listen(callback);
    } catch (e) {
      Get.snackbar("مشكلة في الاتصال بالارقام للبيع", e.toString());
    }
  }
}
