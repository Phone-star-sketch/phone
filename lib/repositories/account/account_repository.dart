import 'package:phone_system_app/models/account.dart';

abstract class AccountRepository {
    Future<List<Account>> getAllAccounts();  
}