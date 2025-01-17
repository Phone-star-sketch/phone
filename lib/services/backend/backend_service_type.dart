import 'package:phone_system_app/models/system.dart';
import 'package:phone_system_app/repositories/account/account_repository.dart';
import 'package:phone_system_app/repositories/client/client_repository.dart';
import 'package:phone_system_app/repositories/crud_mixin.dart';
import 'package:phone_system_app/repositories/log/log_repository.dart';

import 'package:phone_system_app/repositories/phone/phone_repository.dart';
import 'package:phone_system_app/repositories/profit/profit_repository.dart';
import 'package:phone_system_app/repositories/system/system_repository.dart';
import 'package:phone_system_app/repositories/system_type/system_type_repository.dart';
import 'package:phone_system_app/repositories/user/user_repository.dart';
import 'package:phone_system_app/services/backend/auth.dart';

abstract class BackendServiceType {
  Future<void> initialize();

  AccountRepository get accountRepository;
  ClientRepository get clientRepository;
  PhoneRepository get phoneRepository;
  SystemRepository get systemRepository;
  SystemTypeRepository get systemTypeRepository;
  LogRepository get logRepository;
  ProfitRepository get profitRepository; 
  SupabaseAuthentication get supabaseAuthentication;
  UserRepository get userRepository;
}
