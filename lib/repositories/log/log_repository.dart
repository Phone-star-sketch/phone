

import 'package:phone_system_app/models/client.dart';
import 'package:phone_system_app/models/log.dart';
import 'package:phone_system_app/models/phone_number.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class LogRepository {

  Future<List<Log>> getAllLogsByPhoneNumber (PhoneNumber phnoe); 
  Future<List<Log>> getLogsByMatchMapQuery(Map<String , Object> query);
  Future<void> reverseLog(Log log , Client client);

}