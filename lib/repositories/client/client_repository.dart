import 'package:phone_system_app/models/account.dart';
import 'package:phone_system_app/models/client.dart';
import 'package:phone_system_app/models/system.dart';
import 'package:phone_system_app/models/system_type.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ClientRepository {
  Future<List<Client>> getAllClientsByAccount(Account account);
  Future<List<Client>> getAllLateClientsByAccount(Account account);
  Future<void> addMoneyToClinet(Client client, double amount);
  Stream<List<Client>> getAllClientsByAccountStream(Account account);
  Future<void> assignSystemToClient(Client clinet, SystemType systemType);
  Stream<List<Map<String, dynamic>>> getClientStream(Client client);
  Future<List<Map<String, dynamic>>> getAllClients(String? coulmnName);

  Future<void> createClientWithPhoneNumber(Client client, String phoneNumber);

  void bindStreamToClientChanges(
      Client clinet, Function(List<Map<String, dynamic>>) callback);
  void bindStreamToClientLogsChanges(
      Client clinet, Function(List<Map<String, dynamic>>) callback);
  void bindStreamToClientSystemsChanges(
      Client clinet, Function(List<Map<String, dynamic>>) callback);

  Future<void> paySystemsBills(Client client, int month, int year);

  Future<List<Map<String, dynamic>>> getAllClientsData();

  Future<Client?> getClient(String clientId);
}
