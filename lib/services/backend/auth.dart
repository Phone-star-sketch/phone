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
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: username,
        password: password,
      );
      
      // Update session immediately
      userSession.value = response.session!;
      
      // Get user data with secpass
      if (userSession.value.user != null) {
        myUser = await BackendServices.instance.userRepository
            .getCurrentUser(userSession.value.user!.id);
        
        if (myUser == null || myUser!.secpass == null) {
          await signOut();
          throw Exception("بيانات المستخدم غير موجودة أو غير مكتملة");
        }
      }
      
    } catch (e) {
      await signOut();
      throw e;
    }
  }

  Future<void> authstate() async {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      try {
        final AuthChangeEvent event = data.event;
        print('event captured : $event');
        
        if (data.session != null) {
          userSession.value = data.session!;
          myUser = await BackendServices.instance.userRepository
              .getCurrentUser(data.session!.user.id);
          allUser = await BackendServices.instance.userRepository.getAllUsers();
        } else {
          userSession.value = Session(
            accessToken: '',
            tokenType: '',
            user: const User(
              id: '',
              appMetadata: {},
              userMetadata: {},
              aud: '',
              createdAt: ''
            ),
          );
          myUser = null;
          allUser = null;
        }
      } catch (e) {
        print('Auth state error: $e');
      }
    });
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }
}
