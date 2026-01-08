import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/controllers/money_display_loading.dart';
import 'package:phone_system_app/services/backend/auth.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';
import 'package:phone_system_app/views/account_view.dart';
import 'package:fluttertoast/fluttertoast.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final formKey = GlobalKey<FormState>();
  late TextEditingController userName;
  late TextEditingController passWord;
  late TextEditingController secPass;
  late FocusNode userNameFocus;
  late FocusNode passwordFocus;
  late FocusNode secPassFocus;

  late AnimationController _entryController;
  late AnimationController _waveController;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    userName = TextEditingController();
    passWord = TextEditingController();
    secPass = TextEditingController();
    userNameFocus = FocusNode();
    passwordFocus = FocusNode();
    secPassFocus = FocusNode();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    userName.dispose();
    passWord.dispose();
    secPass.dispose();
    userNameFocus.dispose();
    passwordFocus.dispose();
    secPassFocus.dispose();
    _entryController.dispose();
    _waveController.dispose();
    _shakeController.dispose();
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
        backgroundColor: const Color(0xFF0a0a0a),
        body: Stack(
          children: [
            // Animated Background Waves
            _buildAnimatedWaves(),

            // Grid Pattern
            _buildGridPattern(),

            // Main Content
            _buildMainContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedWaves() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return CustomPaint(
          painter: _LoginWavePainter(animation: _waveController.value),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildGridPattern() {
    return Opacity(
      opacity: 0.02,
      child: CustomPaint(
        painter: _GridPainter(),
        size: Size.infinite,
      ),
    );
  }

  Widget _buildMainContent() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: AnimatedBuilder(
            animation: _entryController,
            builder: (context, child) {
              final opacity = Curves.easeOut.transform(_entryController.value);
              final slide = (1 - opacity) * 50;

              return Transform.translate(
                offset: Offset(0, slide),
                child: Opacity(
                  opacity: opacity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      _buildLogo(),

                      const SizedBox(height: 40),

                      // Title
                      _buildTitle(),

                      const SizedBox(height: 40),

                      // Login Form
                      _buildLoginForm(),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFff6b6b), Color(0xFFfeca57)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFff6b6b).withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: const Icon(
        Icons.lock_rounded,
        size: 45,
        color: Colors.white,
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        const Text(
          'تسجيل الدخول',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'أدخل بياناتك للمتابعة',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            // Username Field
            _buildTextField(
              controller: userName,
              focusNode: userNameFocus,
              label: 'اسم المستخدم',
              icon: Icons.person_rounded,
              validator: (v) =>
                  v?.isEmpty == true ? 'يرجى إدخال اسم المستخدم' : null,
            ),

            const SizedBox(height: 20),

            // Password Field
            Obx(() => _buildTextField(
                  controller: passWord,
                  focusNode: passwordFocus,
                  label: 'كلمة المرور',
                  icon: Icons.lock_rounded,
                  obscure: Loaders.to.showPassword.value,
                  suffixIcon: IconButton(
                    icon: Icon(
                      Loaders.to.showPassword.value
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      color: const Color(0xFFff6b6b),
                    ),
                    onPressed: () => Loaders.to.showPassword.value =
                        !Loaders.to.showPassword.value,
                  ),
                  validator: (v) =>
                      v?.isEmpty == true ? 'يرجى إدخال كلمة المرور' : null,
                )),

            const SizedBox(height: 20),

            // Security Password Field
            _buildTextField(
              controller: secPass,
              focusNode: secPassFocus,
              label: 'كلمة المرور الثانية',
              icon: Icons.security_rounded,
              obscure: true,
              keyboardType: TextInputType.number,
              validator: (v) =>
                  v?.isEmpty == true ? 'يرجى إدخال كلمة المرور الثانية' : null,
            ),

            const SizedBox(height: 32),

            // Login Button
            _buildLoginButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
      ),
      cursorColor: const Color(0xFFff6b6b),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(
          icon,
          color: const Color(0xFFff6b6b),
        ),
        suffixIcon: suffixIcon,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFff6b6b),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFff6b6b),
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFff6b6b),
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Obx(() {
      final isLoading = Loaders.to.logInIsLoading.value;

      return GestureDetector(
        onTap: isLoading ? null : () => _handleLogin(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: isLoading
                  ? [Colors.grey.shade700, Colors.grey.shade600]
                  : const [Color(0xFFff6b6b), Color(0xFFfeca57)],
            ),
            boxShadow: isLoading
                ? null
                : [
                    BoxShadow(
                      color: const Color(0xFFff6b6b).withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'دخول',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ],
                  ),
          ),
        ),
      );
    });
  }

  Future<void> _handleLogin(BuildContext context) async {
    _unfocusAll();
    if (!mounted) return;
    if (!formKey.currentState!.validate()) {
      _shakeController.forward().then((_) => _shakeController.reset());
      return;
    }

    try {
      Loaders.to.logInIsLoading.value = true;

      await BackendServices.instance.supabaseAuthentication
          .signIn(userName.text, passWord.text);

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
          backgroundColor: const Color(0xFFff6b6b),
          textColor: Colors.white,
          fontSize: 16.0,
        );
        throw Exception("كلمة المرور الثانية غير صحيحة");
      }

      if (!mounted) return;

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
        backgroundColor: const Color(0xFFff6b6b),
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

// Wave Painter
class _LoginWavePainter extends CustomPainter {
  final double animation;

  _LoginWavePainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Top glow
    paint.shader = RadialGradient(
      center: const Alignment(0, -0.8),
      radius: 1.5,
      colors: [
        const Color(0xFFff6b6b).withValues(alpha: 0.15),
        const Color(0xFFff6b6b).withValues(alpha: 0.0),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.6), paint);

    // Bottom wave
    paint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFFfeca57).withValues(alpha: 0.1),
        const Color(0xFFfeca57).withValues(alpha: 0.0),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    path.moveTo(0, size.height * 0.85);

    for (double i = 0; i <= size.width; i++) {
      final y = size.height * 0.85 +
          math.sin((i / size.width * 2 * math.pi) + (animation * 2 * math.pi)) *
              20;
      path.lineTo(i, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_LoginWavePainter oldDelegate) =>
      animation != oldDelegate.animation;
}

// Grid Painter
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1;

    const spacing = 40.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}
