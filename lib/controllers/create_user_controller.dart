import 'package:get/get.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateUserController extends GetxController {
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  Future<bool> createUser(String email, String password) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        errorMessage.value = 'حدث خطأ اثناء انشاء المستخدم';
        return false;
      }

      // Insert additional user data into the 'users' table
      await Supabase.instance.client.from('users').insert({
        'id': response.user!.id,
        'uuid': email, // Insert email into the uuid column
        'created_at': DateTime.now().toIso8601String(),
        'role': 2, // Default role (assistant)
      });

      return true;
    } catch (e) {
      errorMessage.value = 'حدث خطأ اثناء انشاء المستخدم: ${e.toString()}';
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
