import 'package:get/get.dart';
import 'package:phone_system_app/models/user.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum UserRoles { admin, manager, assistant }

class SupabaseAuthentication extends GetxController {
  static Rx<Session> userSession = Session(
          accessToken: '',
          tokenType: '',
          user: const User(
              id: '',
              appMetadata: {},
              userMetadata: {},
              aud: '',
              createdAt: ''))
      .obs;

  static List<AppUser>? allUser;
  static AppUser? myUser;

  @override
  void onReady() async {
    super.onReady();
    authstate();
  }

  AppUser? getUserById(Object id){
    return allUser!.firstWhereOrNull((obj)=> obj.id == id);  
  }

  Future<void> signIn(String username, String password) async {
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: username,
        password: password,
      );
    } catch (e) {
      Get.snackbar('response', e.toString());
    }
  }

  authstate() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      print('event captured : $event');
      userSession.value = Session(
          accessToken: '',
          tokenType: '',
          user: const User(
              id: '',
              appMetadata: {},
              userMetadata: {},
              aud: '',
              createdAt: ''));
      if (data.session != null) {
        userSession.value = data.session!;
        myUser = await BackendServices.instance.userRepository
            .getCurrentUser(data.session!.user.id);
        allUser = await BackendServices.instance.userRepository.getAllUsers();
        print(allUser!.map(
          (e) => e.toJson(),
        ));
      }
    });
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }
}
