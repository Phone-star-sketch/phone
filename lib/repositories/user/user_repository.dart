import 'package:phone_system_app/models/user.dart';

abstract class UserRepository {
  Future<AppUser> getCurrentUser(String uid);
  Future<List<AppUser>> getAllUsers();
}
