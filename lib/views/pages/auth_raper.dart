import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/services/backend/auth.dart';
import 'package:phone_system_app/views/account_view.dart';
import 'package:phone_system_app/views/pages/login_page.dart';

class AuthRaper extends StatefulWidget {
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
        'مرحبا بك كابتن اسلام',
        'نتمنى لك يوما سعيدا',
        backgroundColor: Get.theme.colorScheme.primary.withOpacity(0.9),
        colorText: Get.theme.colorScheme.onPrimary,
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(8),
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
      return LoginPage();
    });
  }
}
