import 'package:phone_system_app/models/phone_number.dart';
import 'package:phone_system_app/models/system.dart';

abstract class SystemRepository {
  Future<System> getSystemByPhoneNumber(PhoneNumber phoneNumber);
  Future<List<Map<String,dynamic>>> getAll(String? coulmnNames);
}
