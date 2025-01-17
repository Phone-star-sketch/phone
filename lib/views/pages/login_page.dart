import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/controllers/money_display_loading.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';
import 'package:phone_system_app/views/account_view.dart';
import 'package:phone_system_app/views/bottom_sheet_dialogs/show_client_info_sheet.dart';

class LoginPage extends StatelessWidget {
  LoginPage({Key? key}) : super(key: key);

  final formKey = GlobalKey<FormState>();
  final userName = TextEditingController();
  final passWord = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(
        () => Stack(
          children: [
            // Background Image
            Image.asset(
              'assets/images/LoginPageImage.jpg',
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
            
            // Scrollable Content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 40),
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white54,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Form(
                        key: formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Logo
                            Opacity(
                              opacity: 0.6,
                              child: SvgPicture.asset(
                                "assets/images/zi_search_logo.svg",
                                width: 200,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 44),
                            
                            // Username Field
                            TextFormField(
                              validator: (value) =>
                                  value?.isEmpty == true ? 'يرجي إدخال إسم المستخدم' : null,
                              controller: userName,
                              keyboardType: TextInputType.name,
                              cursorColor: Colors.red,
                              decoration: const InputDecoration(
                                focusColor: Colors.red,
                                icon: Icon(Icons.person),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(20)),
                                ),
                                labelText: 'إسم المستخدم',
                                labelStyle: TextStyle(color: Colors.red),
                              ),
                            ),
                            const SizedBox(height: 44),
                            
                            // Password Field
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    obscureText: Loaders.to.showPassword.value,
                                    validator: (value) =>
                                        value?.isEmpty == true ? 'يرجي إدخال كلمة المرور' : null,
                                    controller: passWord,
                                    keyboardType: TextInputType.visiblePassword,
                                    cursorColor: Colors.red,
                                    decoration: const InputDecoration(
                                      focusColor: Colors.red,
                                      icon: Icon(Icons.password),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(20)),
                                      ),
                                      labelText: 'كلمة المرور',
                                      labelStyle: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => Loaders.to.showPassword.value = !Loaders.to.showPassword.value,
                                  icon: Icon(
                                    Loaders.to.showPassword.value
                                        ? Icons.remove_red_eye
                                        : Icons.hide_image,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 44),
                            
                            // Login Button
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                              icon: const Icon(Icons.smart_button_sharp),
                              onPressed: Loaders.to.logInIsLoading.value
                                  ? null
                                  : () => _handleLogin(context),
                              label: const Text(
                                'تسجيل الدخول',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                            
                            // Loading Indicator
                            if (Loaders.to.logInIsLoading.value)
                              Container(
                                margin: const EdgeInsets.all(20),
                                child: CustomIndicator(
                                  title: "جاري تسجيل الدخول",
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogin(BuildContext context) async {
    if (!formKey.currentState!.validate()) return;
    
    try {
      Loaders.to.logInIsLoading.value = true;
      final user = await BackendServices.instance.supabaseAuthentication
          .signIn(userName.text, passWord.text);
      
      // Show animated welcome dialog
      await Get.dialog(
        WillPopScope(
          onWillPop: () async => false, // Prevent back button dismissal
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: TweenAnimationBuilder(
              duration: const Duration(milliseconds: 600),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: value,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 15,
                            spreadRadius: 5,
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TweenAnimationBuilder(
                            duration: const Duration(milliseconds: 800),
                            tween: Tween<double>(begin: 0, end: 1),
                            builder: (context, double value, child) {
                              return Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.red, width: 3),
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/images/owner.png',
                                      height: 150,
                                      width: 150,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          TweenAnimationBuilder(
                            duration: const Duration(milliseconds: 800),
                            tween: Tween<double>(begin: 0, end: 1),
                            builder: (context, double value, child) {
                              return Opacity(
                                opacity: value,
                                child: const Text(
                                  "مرحبا كابتن اسلام",
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          TweenAnimationBuilder(
                            duration: const Duration(milliseconds: 1000),
                            tween: Tween<double>(begin: 0, end: 1),
                            builder: (context, double value, child) {
                              return Opacity(
                                opacity: value,
                                child: const Text(
                                  "نتمنى لك يوماً سعيداً",
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.black87,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          TweenAnimationBuilder(
                            duration: const Duration(milliseconds: 1200),
                            tween: Tween<double>(begin: 0, end: 1),
                            builder: (context, double value, child) {
                              return Opacity(
                                opacity: value,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 40,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  onPressed: () {
                                    Get.back();
                                    Get.off(() => AccountsView(),
                                      transition: Transition.fadeIn,
                                      duration: const Duration(milliseconds: 500)
                                    );
                                  },
                                  child: const Text(
                                    "حسناً",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // Auto-close after 3 seconds if button not pressed
      await Future.delayed(const Duration(seconds: 3));
      if (Get.isDialogOpen == true) {
        Get.back();
        Get.off(() => AccountsView(),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 500)
        );
      }

    } catch (e) {
      await Get.snackbar(
        "خطأ اثناء تسجيل الدخول", 
        e.toString(),
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        borderRadius: 20,
        duration: const Duration(seconds: 3),
      );
    } finally {
      Loaders.to.logInIsLoading.value = false;
    }
  }
}