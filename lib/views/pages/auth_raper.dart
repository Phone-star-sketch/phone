import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/services/backend/auth.dart';
import 'package:phone_system_app/views/account_view.dart';
import 'package:phone_system_app/views/pages/login_page.dart';

class AuthRaper extends StatefulWidget {
  const AuthRaper({super.key});

  @override
  State<AuthRaper> createState() => _AuthRaperState();
}

class _AuthRaperState extends State<AuthRaper> {
  final SupabaseAuthentication controller = Get.put(SupabaseAuthentication());
  bool _hasShownWelcome = false;

  void _showWelcomeMessage() async {
    if (!_hasShownWelcome && SupabaseAuthentication.myUser?.role == 1) {
      _hasShownWelcome = true;
      Get.snackbar(
        'مرحباً بك كابتن اسلام',
        'نتمنى لك يوماً سعيداً',
        backgroundColor: const Color(0xFFff6b6b).withValues(alpha: 0.95),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 16,
        icon: const Icon(
          Icons.waving_hand_rounded,
          color: Colors.white,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (SupabaseAuthentication.userSession.value.accessToken != '') {
        _showWelcomeMessage();
        return AccountsView();
      }
      return const LoginPage();
    });
  }
}
