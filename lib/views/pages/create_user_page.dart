import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/controllers/create_user_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateUserPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final controller = Get.put(CreateUserController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'انشاء مستخدم جديد',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),
                  Obx(() => controller.errorMessage.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            controller.errorMessage.value,
                            style: TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : SizedBox()),
                  Obx(() => ElevatedButton(
                        onPressed: controller.isLoading.value
                            ? null
                            : () async {
                                if (emailController.text.isEmpty ||
                                    passwordController.text.isEmpty) {
                                  controller.errorMessage.value =
                                      'الرجاء ادخال جميع البيانات';
                                  return;
                                }

                                final success = await controller.createUser(
                                  emailController.text,
                                  passwordController.text,
                                );

                                if (success) {
                                  emailController.clear();
                                  passwordController.clear();
                                  Get.snackbar(
                                    'تم',
                                    'تم انشاء المستخدم بنجاح',
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.all(16),
                        ),
                        child: controller.isLoading.value
                            ? CircularProgressIndicator(color: Colors.black)
                            : Text('انشاء المستخدم',
                                style: TextStyle(fontSize: 16)),
                      )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
        'email': email,
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
