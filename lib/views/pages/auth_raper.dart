import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/services/backend/auth.dart';
import 'package:phone_system_app/views/account_view.dart';
import 'package:phone_system_app/views/pages/login_page.dart';

class AuthRaper extends StatelessWidget {
  SupabaseAuthentication controller = Get.put(SupabaseAuthentication());
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      //Session currentSession=controller.userSession.value;
      return ((SupabaseAuthentication.userSession.value.accessToken != '')
          ? AccountsView()
          : LoginPage());
    });
  }
}
