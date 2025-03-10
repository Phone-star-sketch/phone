import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/services/backend/auth.dart';
import 'package:phone_system_app/views/pages/all_clinets_page.dart';
import 'package:phone_system_app/views/pages/dues_management.dart';
import 'package:phone_system_app/views/pages/follow.dart';
import 'package:phone_system_app/views/pages/for_sale_number.dart';
import 'package:phone_system_app/views/pages/offers.dart';
import 'package:phone_system_app/views/pages/profit_management_page.dart';
import 'package:phone_system_app/views/pages/system_list.dart';

class PageData {
  final String title;
  final Icon icon;
  final List<UserRoles> roles;
  final Widget? content;

  PageData({
    required this.title,
    required this.icon,
    required this.roles,
    this.content,
  });
}

class AccountDetailsController extends GetxController {
  static AccountDetailsController get to => Get.find();
  final RxInt selectedIndex = 0.obs;

  final Rx<String?> profileImage = Rx<String?>(null);

  final List<PageData> pages = [
    PageData(
      title: "بيانات العملاء",
      icon: const Icon(Icons.supervised_user_circle, color: Colors.black54),
      roles: [UserRoles.admin, UserRoles.manager],
    ),
    PageData(
      title: "المستحقات",
      icon: const Icon(Icons.payment, color: Colors.black54),
      roles: [UserRoles.admin, UserRoles.manager, UserRoles.assistant],
    ),
    PageData(
      title: "العروض المطلوبة",
      icon: const Icon(Icons.card_giftcard_rounded, color: Colors.black54),
      roles: [UserRoles.admin, UserRoles.manager],
    ),
    PageData(
      title: "الباقات المتاحة",
      icon: const Icon(Icons.play_lesson, color: Colors.black54),
      roles: [UserRoles.admin, UserRoles.manager],
    ),
    PageData(
      title: "الربح و الاحصاء",
      icon: const Icon(Icons.account_balance_wallet, color: Colors.black54),
      roles: [UserRoles.admin, UserRoles.manager],
    ),
    PageData(
      title: "أرقام للبيع",
      icon: const Icon(Icons.phone_android, color: Colors.black54),
      roles: [UserRoles.admin, UserRoles.manager],
    ),
    PageData(
      title: "المتابعة",
      icon: const Icon(Icons.toc_rounded, color: Colors.black54),
      roles: [UserRoles.admin, UserRoles.manager],
    ),
  ];

  void handleNavigation(int index) {
    selectedIndex.value = index;
    switch (index) {
      case 0:
        Get.to(() => AllClientsPage());
        break;
      case 1:
        Get.to(() => DuesManagement());
        break;
      case 2:
        Get.to(() => OfferManagement());
        break;
      case 3:
        Get.to(() => SystemList());
        break;
      case 4:
        Get.to(() => ProfitManagement());
        break;
      case 5:
        Get.to(() => ForSaleNumbers());
        break;
      case 6:
        Get.to(() => Follow());
        break;
    }
  }
}
