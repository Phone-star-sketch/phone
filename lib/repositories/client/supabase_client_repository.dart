import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/controllers/account_client_info_data.dart';
import 'package:phone_system_app/models/account.dart';
import 'package:phone_system_app/models/client.dart';
import 'package:phone_system_app/models/log.dart';
import 'package:phone_system_app/models/phone_number.dart';
import 'package:phone_system_app/models/system.dart';
import 'package:phone_system_app/models/system_type.dart';
import 'package:phone_system_app/repositories/client/client_repository.dart';
import 'package:phone_system_app/repositories/crud_mixin.dart';
import 'package:phone_system_app/services/backend/auth.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';
import 'package:phone_system_app/views/pages/system_list.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientRepository extends ClientRepository
    with CrudOperations<Client> {
  static const String clientTableName = "client";

  final _clinet = Supabase.instance.client;

  @override
  Future<List<Client>> getAllClientsByAccount(Account account) async {
    List<Client> data = [];
    try {
      final values = await _clinet
          .from(clientTableName)
          .select("*, phone(* ,system(* , system_type(*))), log(*)")
          .match({"account_id": account.id as int}).order('name',
              ascending: true);
      data = values.map((e) {
        return Client.fromJson(e);
      }).toList();
    } catch (e) {
      Get.snackbar("Account Clients fetching error", e.toString());
    }
    return data;
  }

  @override
  Future<List<Client>> getAllLateClientsByAccount(Account account) {
    throw UnimplementedError();
  }

  @override
  Future<Object> create(Client item) async {
    final values = item.toJson();
    values.remove('id');
    Object id = -1;
    try {
      await _clinet
          .from(clientTableName)
          .insert(values)
          .select()
          .single()
          .then((value) {
        id = value["id"] as Object;
      });
    } catch (e) {
      Get.showSnackbar(GetSnackBar(
        title: "Error with creating a Clinet",
        message: e.toString(),
      ));
    }
    return id;
  }

  @override
  Future<void> delete(Client item) async {
    await _clinet.from(clientTableName).delete().match({'id': item.id});
  }

  @override
  Future<Client> read(Object id) async {
    final data =
        await _clinet.from(clientTableName).select().match({'id': id}).single();
    final obj = Client.fromJson(data);
    return obj;
  }

  @override
  Future<void> update(Client item) async {
    await _clinet
        .from(clientTableName)
        .update(item.toJson())
        .match({'id': item.id});
  }

  @override
  Future<void> addMoneyToClinet(Client client, double amount) async {
    try {
      client.totalCash += amount;
      await update(client);
      final log = Log(
        id: 0,
        accountId: AccountClientInfo.to.currentAccount.id,
        clientId: client.id,
        phoneId: client.numbers![0].id,
        createdBy: SupabaseAuthentication.myUser!.id,
        price: amount,
        systemType: "تعامل مالي : $amount جنيه",
        transactionType: (amount > 0)
            ? TransactionType.moneyAdded
            : TransactionType.moneyDeducted,
        createdAt: DateTime.now(),
      );

      await BackendServices.instance.logRepository.create(log);
      Get.snackbar(
        "حالة الماليات",
        "تمت تعديل المستحقات",
        animationDuration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar("Clinet Error", e.toString());
    }
  }

  @override
  Stream<List<Client>> getAllClientsByAccountStream(Account account) {
    final stream = _clinet
        .from(clientTableName)
        .select("*, phone(* ,system(* , system_type(*)))")
        .match({"account_id": account.id as int}).asStream();

    final mappedStream = stream.map((singleTransaction) {
      return singleTransaction.map((clientJsonObject) {
        return Client.fromJson(clientJsonObject);
      }).toList();
    });

    return mappedStream;
  }

  @override
  Future<List<Map<String, dynamic>>> getAllClients(String? coulmnName) async {
    return await _clinet.from(clientTableName).select(coulmnName ?? "*");
  }

  @override
  Future<void> assignSystemToClient(
      Client clinet, SystemType systemType) async {
    try {
      final system = System(
          id: 0,
          createdAt: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 30)),
          name: systemType.name,
          phoneID: clinet.numbers![0].id as int,
          startDate: DateTime.now(),
          type: systemType,
          typeId: systemType.id as int);

      await BackendServices.instance.systemRepository.create(system);
    } catch (e) {
      Get.snackbar("Client Assign System Error", e.toString());
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> getClientStream(Client client) {
    Object id = client.id;
    return _clinet
        .from(clientTableName)
        .stream(primaryKey: ['id']).eq('id', id);
  }

  @override
  void bindStreamToClientChanges(
      Client clinet, Function(List<Map<String, dynamic>> payload) callback) {
    _clinet
        .from(clientTableName)
        .stream(primaryKey: ['id'])
        .eq('id', clinet.id)
        .listen(callback);
  }

  @override
  void bindStreamToClientLogsChanges(
      Client clinet, Function(List<Map<String, dynamic>> data) callback) {
    _clinet
        .from("log")
        .stream(primaryKey: ['id'])
        .eq('client_id', clinet.id)
        .listen(callback, onError: (error) {
          Get.showSnackbar(GetSnackBar(
            title: "حدثت مشكلة ما ",
            message: error.toString(),
          ));
        });
  }

  @override
  void bindStreamToClientSystemsChanges(
      Client clinet, Function(List<Map<String, dynamic>> data) callback) {
    final phoneId = clinet.numbers![0].id;
    _clinet
        .from("system")
        .stream(primaryKey: ['id'])
        .eq('phone_id', phoneId)
        .listen(callback);
  }

  @override
  Future<void> createClientWithPhoneNumber(
      Client client, String phoneNumber) async {
    try {
      Object clientId = await create(client);

      debugPrint(clientId.toString());

      final phone = PhoneNumber(
        id: -1,
        createdAt: DateTime.now(),
        phoneNumber: phoneNumber,
        clientId: clientId,
        systems: [],
      );

      await BackendServices.instance.phoneRepository.create(phone);
    } catch (e) {
      Get.showSnackbar(GetSnackBar(
        title: "Error with creating Client",
        message: e.toString(),
      ));
    }
  }

  @override
  Future<void> paySystemsBills(Client client, int month, int year) async {
    try {
      double totalCash = client.totalCash;
      double bills = client.systemsCost();

      double newCash = totalCash - bills;

      final data = client.toJson();
      data[Client.totalCashColumns] = newCash;

      await BackendServices.instance.clientRepository
          .update(Client.fromJson(data));

      final log = Log(
        id: 0,
        month: month,
        createdBy: SupabaseAuthentication.myUser!.id,
        accountId: AccountClientInfo.to.currentAccount.id,
        year: year,
        clientId: client.id,
        phoneId: client.numbers![0].id,
        price: bills,
        paid: (totalCash >= bills)
            ? bills
            : (totalCash > 0)
                ? totalCash
                : 0,
        reminder: (totalCash >= bills)
            ? 0
            : (totalCash > 0)
                ? bills - totalCash
                : bills,
        systemType: client.systemsFullName(),
        transactionType: TransactionType.transactionDone,
        createdAt: DateTime.now(),
      );

      await BackendServices.instance.logRepository.create(log);

      // Remove temp systems
      final tempSystems = client.numbers![0].systems;
      final toBeRemoved = tempSystems!
          .where((element) => element.type!.category == SystemCategory.values)
          .toList();

      for (final system in toBeRemoved) {
        BackendServices.instance.systemRepository.delete(system);
      }
    } catch (e) {
      Get.showSnackbar(GetSnackBar(
        title: "Error with paying bills",
        message: e.toString(),
      ));
    }
  }

  Stream<List<Client>> getRealtimeClients(Account account) {
    return _clinet
        .from(clientTableName)
        .stream(primaryKey: ['id'])
        .eq('account_id', account.id)
        .order('name')
        .map((list) => list.map((e) => Client.fromJson(e)).toList());
  }

  Future<List<Map<String, dynamic>>> getAllClientsData() async {
    try {
      final response = await _clinet.from(clientTableName).select(
          'id, account_id, account:account_id (id, name)'); // Join with accounts table

      print('Fetched client data: $response');

      if (response == null) {
        print('No data returned from query');
        return [];
      }

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error in getAllClientsData: $e');
      return [];
    }
  }

  Future<Client?> getClient(String clientId) async {
    try {
      final response = await supabase
          .from('clients')
          .select('*, numbers(*), systems(*)')
          .eq('id', clientId)
          .single();

      if (response != null) {
        return Client.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error fetching client: $e');
      return null;
    }
  }

  Future<void> updateClient(Client client) async {
    try {
      await supabase.from('clients').update({
        'name': client.name,
        'expire_date': client.expireDate?.toIso8601String(),
        'total_cash': client.totalCash,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', client.id);
    } catch (e) {
      throw Exception('Failed to update client: $e');
    }
  }
}
