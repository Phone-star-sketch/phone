import 'package:phone_system_app/models/account.dart';
import 'package:phone_system_app/repositories/account/account_repository.dart';
import 'package:phone_system_app/repositories/account/supabase_account_repo.dart';
import 'package:phone_system_app/repositories/client/client_repository.dart';
import 'package:phone_system_app/repositories/client/supabase_client_repository.dart';
import 'package:phone_system_app/repositories/log/log_repository.dart';
import 'package:phone_system_app/repositories/log/log_supabase_repository.dart';
import 'package:phone_system_app/repositories/phone/phone_repository.dart';
import 'package:phone_system_app/repositories/phone/supabase_phone_repository.dart';
import 'package:phone_system_app/repositories/profit/profit_repository.dart';
import 'package:phone_system_app/repositories/profit/supabase_profit_repository.dart';
import 'package:phone_system_app/repositories/system/supabase_system_repository.dart';
import 'package:phone_system_app/repositories/system/system_repository.dart';
import 'package:phone_system_app/repositories/system_type/supabase_system_type_repository.dart';
import 'package:phone_system_app/repositories/system_type/system_type_repository.dart';
import 'package:phone_system_app/repositories/user/supabase_user_repository.dart';
import 'package:phone_system_app/repositories/user/user_repository.dart';
import 'package:phone_system_app/services/backend/auth.dart';
import 'package:phone_system_app/services/backend/backend_service_type.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseBackendServices extends BackendServiceType {
  late SupabaseAccountRepository _accountRepository;
  late SupabaseClientRepository _clientRepository;
  late SupabasePhoneRepository _phoneRepository;
  late SupabaseSystemRepository _systemRepository;
  late SupabaseSystemTypeRepository _systemTypeRepository;
  late SupabaseAuthentication _supabaseAuthentication;
  late SupabaseLogRepository _logRepository;
  late SupabaseProfitRepository _profitRepository;
  late SupabaseUserRepository _userRepository;

  @override
  Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://kmtimujsqhpltmzrycxw.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImttdGltdWpzcWhwbHRtenJ5Y3h3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTQ5MjYxOTIsImV4cCI6MjAzMDUwMjE5Mn0.G5zvCK0wlaK5VMF_hssR-AtkbKAfBtH_ZgPDZTXw5gg',
    );

    _logRepository = SupabaseLogRepository();
    _accountRepository = SupabaseAccountRepository();
    _clientRepository = SupabaseClientRepository();
    _phoneRepository = SupabasePhoneRepository();
    _systemRepository = SupabaseSystemRepository();
    _systemTypeRepository = SupabaseSystemTypeRepository();
    _profitRepository = SupabaseProfitRepository();
    // Authentication
    _supabaseAuthentication = SupabaseAuthentication();
    _supabaseAuthentication = SupabaseAuthentication();
    _userRepository = SupabaseUserRepository();
  }

  @override
  SupabaseAccountRepository get accountRepository => _accountRepository;

  @override
  SupabaseClientRepository get clientRepository => _clientRepository;

  @override
  SupabasePhoneRepository get phoneRepository => _phoneRepository;

  @override
  SupabaseSystemRepository get systemRepository => _systemRepository;

  @override
  SupabaseSystemTypeRepository get systemTypeRepository =>
      _systemTypeRepository;

  @override
  SupabaseLogRepository get logRepository => _logRepository;

  @override
  SupabaseAuthentication get supabaseAuthentication => _supabaseAuthentication;

  @override
  SupabaseProfitRepository get profitRepository => _profitRepository;
  //SupabaseAuthentication get supabaseAuthentication => _supabaseAuthentication;

  //@override
  //SupabaseLogRepository get logRepository => _logRepository;

  @override
  UserRepository get userRepository => _userRepository;
}
