import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/controllers/money_display_loading.dart';
import 'package:phone_system_app/services/backend/auth.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';
import 'package:phone_system_app/views/account_view.dart';
import 'package:phone_system_app/views/bottom_sheet_dialogs/show_client_info_sheet.dart';
import 'package:fluttertoast/fluttertoast.dart'; // Add this import if not already present

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final formKey = GlobalKey<FormState>();
  late TextEditingController userName;
  late TextEditingController passWord;
  late TextEditingController secPass;
  late FocusNode userNameFocus;
  late FocusNode passwordFocus;
  late FocusNode secPassFocus;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    userName = TextEditingController();
    passWord = TextEditingController();
    secPass = TextEditingController();
    userNameFocus = FocusNode();
    passwordFocus = FocusNode();
    secPassFocus = FocusNode();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    userName.dispose();
    passWord.dispose();
    secPass.dispose();
    userNameFocus.dispose();
    passwordFocus.dispose();
    secPassFocus.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _unfocusAll() {
    userNameFocus.unfocus();
    passwordFocus.unfocus();
    secPassFocus.unfocus();
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle:
          const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
      prefixIcon: Icon(icon, color: Colors.red.withOpacity(0.7)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.red.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _unfocusAll,
      child: Scaffold(
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

              FadeTransition(
                opacity: _fadeAnimation,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 500),
                        margin: const EdgeInsets.symmetric(vertical: 40),
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Form(
                          key: formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Logo with bounce animation
                              TweenAnimationBuilder(
                                duration: const Duration(milliseconds: 1200),
                                tween: Tween<double>(begin: 0.8, end: 1.0),
                                builder: (context, double value, child) {
                                  return Transform.scale(
                                    scale: value,
                                    child: Opacity(
                                      opacity: 0.8,
                                      child: SvgPicture.asset(
                                        "assets/images/zi_search_logo.svg",
                                        width: 200,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 44),

                              // Username Field
                              TextFormField(
                                focusNode: userNameFocus,
                                validator: (value) => value?.isEmpty == true
                                    ? 'يرجي إدخال إسم المستخدم'
                                    : null,
                                controller: userName,
                                keyboardType: TextInputType.name,
                                cursorColor: Colors.red,
                                decoration: _buildInputDecoration(
                                    'إسم المستخدم', Icons.person),
                              ),
                              const SizedBox(height: 20),

                              // Password Field
                              TextFormField(
                                focusNode: passwordFocus,
                                obscureText: Loaders.to.showPassword.value,
                                validator: (value) => value?.isEmpty == true
                                    ? 'يرجي إدخال كلمة المرور'
                                    : null,
                                controller: passWord,
                                keyboardType: TextInputType.visiblePassword,
                                cursorColor: Colors.red,
                                decoration: _buildInputDecoration(
                                        'كلمة المرور', Icons.lock)
                                    .copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      Loaders.to.showPassword.value
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Colors.red.withOpacity(0.7),
                                    ),
                                    onPressed: () => Loaders.to.showPassword
                                        .value = !Loaders.to.showPassword.value,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Add Security Password Field after password field
                              TextFormField(
                                focusNode: secPassFocus,
                                obscureText: true,
                                validator: (value) => value?.isEmpty == true
                                    ? 'يرجي إدخال كلمة المرور الثانية'
                                    : null,
                                controller: secPass,
                                keyboardType: TextInputType.number,
                                cursorColor: Colors.red,
                                decoration: _buildInputDecoration(
                                    'كلمة المرور الثانية', Icons.security),
                              ),
                              const SizedBox(height: 44),

                              // Enhanced login button
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: Loaders.to.logInIsLoading.value
                                      ? null
                                      : () => _handleLogin(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    elevation: 5,
                                  ),
                                  child: Loaders.to.logInIsLoading.value
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'تسجيل الدخول',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
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
      ),
    );
  }

  Future<void> _handleLogin(BuildContext context) async {
    _unfocusAll();
    if (!mounted) return;
    if (!formKey.currentState!.validate()) return;

    try {
      Loaders.to.logInIsLoading.value = true;

      // First authenticate with email and password
      await BackendServices.instance.supabaseAuthentication
          .signIn(userName.text, passWord.text);

      // Verify secpass matches
      final currentUser = SupabaseAuthentication.myUser;
      if (currentUser == null) {
        throw Exception("لم يتم العثور على بيانات المستخدم");
      }

      final userSecpass = currentUser.secpass;
      final enteredSecpass = int.tryParse(secPass.text);

      if (userSecpass == null ||
          enteredSecpass == null ||
          userSecpass != enteredSecpass) {
        await BackendServices.instance.supabaseAuthentication.signOut();
        await Fluttertoast.showToast(
          msg: "كلمة المرور الثانية غير صحيحة",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        throw Exception("كلمة المرور الثانية غير صحيحة");
      }

      if (!mounted) return;

      // Navigate on success
      await Get.offAll(
        () => AccountsView(),
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 500),
      );
    } catch (e) {
      if (!mounted) return;
      await Fluttertoast.showToast(
        msg: "خطأ في تسجيل الدخول",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      secPass.clear();
    } finally {
      if (mounted) {
        Loaders.to.logInIsLoading.value = false;
      }
    }
  }
}
