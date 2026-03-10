import 'package:phone_system_app/models/client.dart';
import 'package:phone_system_app/models/phone_number.dart';

abstract class PhoneRepository {
  Future<List<PhoneNumber>> getPhoneNumbersByClient(Client client);
  Future<List<PhoneNumber>> getPhoneNumbersByMatching(Map<String, Object> mm);
  Future<PhoneNumber?> getPhoneNumberByNumber(String phoneNumber);
  void bindStreamToForSaleNumbersChanges(
      Function(List<Map<String, dynamic>> payload) callback);
}
