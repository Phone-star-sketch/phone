import 'package:phone_system_app/models/system_type.dart';
import 'package:phone_system_app/repositories/crud_mixin.dart';
import 'package:phone_system_app/repositories/system_type/system_type_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseSystemTypeRepository extends SystemTypeRepository
    with CrudOperations<SystemType> {
  static const String systemTypeTableName = "system_type";
  final _client = Supabase.instance.client;

  @override
  Future<Object> create(SystemType item) async {
    final data = item.toJson();
    data.remove("id");

    try {
      await _client
          .from(systemTypeTableName)
          .insert(data)
          .select("id")
          .single()
          .then((value) {
        return value['id'];
      });
    } catch (e) {
      return -1;
    }

    return -1;
  }

  @override
  Future<void> delete(SystemType item) async {
    await _client.from(systemTypeTableName).delete().match({'id': item.id});
  }

  @override
  Future<List<SystemType>> getAllTypes(bool isAscending) async {
    final data = await _client
        .from(systemTypeTableName)
        .select()
        .order('id', ascending: isAscending);
    final systems = (data as List).map((e) => SystemType.fromJson(e)).toList();
    return systems;
  }

  @override
  Future<SystemType> read(Object id) async {
    final system = await _client
        .from(systemTypeTableName)
        .select()
        .match({"id": id}).single();
    return SystemType.fromJson(system);
  }

  @override
  Future<void> update(SystemType item) async {
    final data = item.toJson();
    await _client
        .from(systemTypeTableName)
        .update(data)
        .match({"id": item.id}).then((value) => print(value));
  }
}
