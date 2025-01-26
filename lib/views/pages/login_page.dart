import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/controllers/money_display_loading.dart';
import 'package:phone_system_app/services/backend/auth.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';
import 'package:phone_system_app/views/account_view.dart';
import 'package:phone_system_app/views/bottom_sheet_dialogs/show_client_info_sheet.dart';
import 'package:fluttertoast/fluttertoast.dart';  // Add this import if not already present

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formKey = GlobalKey<FormState>();
  late TextEditingController userName;
  late TextEditingController passWord;
  late TextEditingController secPass;
  late FocusNode userNameFocus;
  late FocusNode passwordFocus;
  late FocusNode secPassFocus;

  @override
  void initState() {
    super.initState();
    userName = TextEditingController();
    passWord = TextEditingController();
    secPass = TextEditingController();
    userNameFocus = FocusNode();
    passwordFocus = FocusNode();
    secPassFocus = FocusNode();
  }

  @override
  void dispose() {
    userName.dispose();
    passWord.dispose();
    secPass.dispose();
    userNameFocus.dispose();
    passwordFocus.dispose();
    secPassFocus.dispose();
    super.dispose();
  }

  void _unfocusAll() {
    userNameFocus.unfocus();
    passwordFocus.unfocus();
    secPassFocus.unfocus();
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
                                focusNode: userNameFocus,
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
                                      focusNode: passwordFocus,
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
                              
                              // Add Security Password Field after password field
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      focusNode: secPassFocus,
                                      obscureText: true,
                                      validator: (value) =>
                                          value?.isEmpty == true ? 'يرجي إدخال كلمة المرور الثانية' : null,
                                      controller: secPass,
                                      keyboardType: TextInputType.number,
                                      cursorColor: Colors.red,
                                      decoration: const InputDecoration(
                                        focusColor: Colors.red,
                                        icon: Icon(Icons.security),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(Radius.circular(20)),
                                        ),
                                        labelText: 'كلمة المرور الثانية',
                                        labelStyle: TextStyle(color: Colors.red),
                                      ),
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
      
      if (userSecpass == null || enteredSecpass == null || userSecpass != enteredSecpass) {
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