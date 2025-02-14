import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

import 'package:get/get.dart';
import 'package:phone_system_app/controllers/account_client_info_data.dart';

import 'package:phone_system_app/controllers/account_details_controller.dart'
    as ctrl;
import 'package:phone_system_app/controllers/account_details_controller.dart';
import 'package:phone_system_app/controllers/account_profit_controller.dart';
import 'package:phone_system_app/controllers/money_display_loading.dart';
import 'package:phone_system_app/services/backend/auth.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';
import 'package:phone_system_app/views/client_list_view.dart';
import 'package:phone_system_app/views/pages/account_management.dart';
import 'package:phone_system_app/views/pages/all_clinets_page.dart';
import 'package:phone_system_app/views/pages/dues_management.dart';
import 'package:phone_system_app/views/pages/follow.dart';
import 'package:phone_system_app/views/pages/for_sale_number.dart';
import 'package:phone_system_app/views/pages/offers.dart';
import 'package:phone_system_app/views/pages/profit_management_page.dart';
import 'package:phone_system_app/views/pages/system_list.dart';
import 'package:phone_system_app/views/pages/create_user_page.dart';
import 'package:phone_system_app/pages/user_management_page.dart'; // Add this import
import 'animated_profile_avatar.dart';

class Page {
  Widget content;
  Widget icon;
  String title;
  List<UserRoles> roles;

  Page({
    required this.content,
    required this.icon,
    required this.title,
    required this.roles,
  });
}

class AccountDetails extends StatelessWidget {
  Size screenSize = Size.zero;
  List<Page> pages = [
    Page(
      roles: [UserRoles.admin, UserRoles.manager],
      content: AllClientsPage(),
      title: "بيانات العملاء",
      icon: const Icon(
        Icons.supervised_user_circle,
        color: Colors.black54,
      ),
    ),
    Page(
      roles: [UserRoles.admin, UserRoles.manager, UserRoles.assistant],
      content: DuesManagement(),
      title: "المستحقات",
      icon: const Icon(
        Icons.payment,
        color: Colors.black54,
      ),
    ),
    Page(
      roles: [UserRoles.admin, UserRoles.manager],
      content: OfferManagement(),
      title: "العروض المطلوبة",
      icon: const Icon(
        Icons.card_giftcard_rounded,
        color: Colors.black54,
      ),
    ),
    Page(
      roles: [UserRoles.admin, UserRoles.manager],
      content: Container(
        height: double.infinity,
        color: Colors.white,
        child: SystemList(),
      ),
      icon: const Icon(
        Icons.play_lesson,
        color: Colors.black54,
      ),
      title: "الباقات المتاحة",
    ),
    Page(
        roles: [UserRoles.admin, UserRoles.manager],
        content: Container(
          color: Colors.white,
          constraints: const BoxConstraints.expand(),
          child: ProfitManagement(),
        ),
        icon: const Icon(
          Icons.account_balance_wallet,
          color: Colors.black54,
        ),
        title: "الربح و الاحصاء"),
    Page(
        roles: [UserRoles.admin, UserRoles.manager],
        content: Container(
          color: Colors.white,
          constraints: const BoxConstraints.expand(),
          child: ForSaleNumbers(),
        ),
        icon: const Icon(
          Icons.phone_android,
          color: Colors.black54,
        ),
        title: "أرقام للبيع"),
    Page(
        roles: [UserRoles.admin, UserRoles.manager],
        content: Container(
          color: Colors.white,
          constraints: const BoxConstraints.expand(),
          child: Follow(),
        ),
        icon: const Icon(
          Icons.toc_rounded,
          color: Colors.black54,
        ),
        title: "المتابعة"),
    if (SupabaseAuthentication.myUser?.role == 1)
      Page(
        roles: [UserRoles.manager],
        content: Container(
          color: Colors.white,
          constraints: const BoxConstraints.expand(),
          child: UserManagementPage(),
        ),
        icon: const Icon(
          Icons.supervised_user_circle_sharp,
          color: Colors.black54,
        ),
        title: "إدارة المستخدمين",
      ),
  ];
  ctrl.AccountDetailsController pageController =
      Get.put(ctrl.AccountDetailsController());
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    screenSize = MediaQuery.of(context).size;
    final colors = Get.theme.colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 1200;
    final content = pages
        .map(
          (e) => e.content,
        )
        .toList();

    // Move controller initialization to the beginning of build method
    final accountDetailsController = Get.put(AccountDetailsController());

    return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA), // Modern light background
        appBar: AppBar(
          backgroundColor: const Color(0xFF2C3E50), // Modern dark blue
          elevation: 0,
          leading: (MediaQuery.of(context).size.width < 1200)
              ? Builder(
                  builder: (BuildContext context) {
                    return IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    );
                  },
                )
              : const SizedBox(),
          actions: [
            Text(
              "${AccountClientInfo.to.currentAccount.day}",
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22),
            ),
            const SizedBox(
              width: 5,
            ),
            IconButton(
                tooltip: "يوم التحصيل الشهري",
                onPressed: () async {
                  final startDate =
                      DateTime.now().subtract(const Duration(days: 30));
                  final endDate = DateTime.now().add(const Duration(days: 30));
                  final data = await showDatePicker(
                    context: context,
                    firstDate: startDate,
                    lastDate: endDate,
                  );

                  if (data != null) {
                    final currentAccount = AccountClientInfo.to.currentAccount;
                    currentAccount.day = data.day;
                    await BackendServices.instance.accountRepository
                        .update(currentAccount);
                  }
                },
                icon: const Icon(Icons.calendar_today, color: Colors.white)),
            Builder(
              builder: (BuildContext context) {
                return IconButton(
                  icon: const Icon(Icons.keyboard_arrow_left,
                      color: Colors.white),
                  onPressed: () {
                    Get.delete<AccountDetailsController>(force: true);
                    Get.delete<AccountClientInfo>(force: true);
                    Get.delete<ProfitController>(force: true);
                    Get.delete<FollowController>(force: true);

                    Get.back();
                  },
                );
              },
            ),
          ],
        ),
        drawer: (isMobile)
            ? Stack(
                children: [
                  Positioned.fill(
                      child: Container(
                    color: Colors.black.withOpacity(0.5),
                  )),
                  Positioned.fill(
                    child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IconButton(
                                onPressed: () => Get.back(),
                                icon: const Icon(Icons.arrow_back)),
                            Expanded(
                                child: SideBar(
                              pages: pages
                                  .where((page) =>
                                      (page.roles
                                          .map((role) => role.index)
                                          .contains(SupabaseAuthentication
                                              .myUser!.role)) ||
                                      (page.title == "انشاء مستخدم" &&
                                          SupabaseAuthentication.myUser!.role ==
                                              UserRoles.admin.index))
                                  .toList(),
                            )),
                          ],
                        )),
                  ),
                ],
              )
            : null,
        bottomNavigationBar: isMobile
            ? Obx(() => CurvedNavigationBar(
                  key: _bottomNavigationKey,
                  index: pageController.selectedIndex.value,
                  height: 65.0,
                  items: pages
                      .where((page) =>
                          (page.roles
                              .map((role) => role.index)
                              .contains(SupabaseAuthentication.myUser!.role)) ||
                          (page.title == "انشاء مستخدم" &&
                              SupabaseAuthentication.myUser!.role ==
                                  UserRoles.admin.index))
                      .map((page) => Icon(
                            (page.icon as Icon).icon!,
                            size: 33,
                            color: Colors.black54, // Changed to black54
                          ))
                      .toList(),
                  color: const Color(0xFF2C3E50), // Modern dark blue
                  buttonBackgroundColor: const Color(0xFF3498DB), // Modern blue
                  backgroundColor: Colors.transparent,
                  animationCurve: Curves.easeInOut,
                  animationDuration: const Duration(milliseconds: 600),
                  onTap: (index) {
                    pageController.selectedIndex.value = index;
                  },
                  letIndexChange: (index) => true,
                ))
            : null,
        body: isMobile
            ? Obx(() {
                final accountClientController = Get.find<AccountClientInfo>();
                final currentPage = pages[pageController.selectedIndex.value];

                if (currentPage.title == "العروض المطلوبة") {
                  // Instead of immediately navigating, return the ExpiredSystemsPage directly
                  final expiredSystemsClients = accountClientController
                      .clinets.value
                      .where((client) => client.numbers!.any(
                          (number) => number.getExpiredSystems().isNotEmpty))
                      .toList();
                  return ExpiredSystemsPage(clients: expiredSystemsClients);
                }

                return Container(
                  color: colors.background,
                  child: content[pageController.selectedIndex.value],
                );
              })
            : Row(
                children: [
                  Container(
                    color: colors.background,
                    width: 250,
                    child: SideBar(
                      pages: pages
                          .where((page) =>
                              (page.roles.map((role) => role.index).contains(
                                  SupabaseAuthentication.myUser!.role)) ||
                              (page.title == "انشاء مستخدم" &&
                                  SupabaseAuthentication.myUser!.role ==
                                      UserRoles.admin.index))
                          .toList(),
                    ),
                  ),
                  Obx(
                    () => Expanded(
                        child: Card(
                      margin: const EdgeInsets.all(0),
                      elevation: 0,
                      child: Container(
                          decoration: BoxDecoration(),
                          padding: const EdgeInsets.all(10),
                          child: () {
                            print(pages[pageController.selectedIndex.value]
                                .title);
                            final accountClientController =
                                Get.find<AccountClientInfo>();
                            if (pages[pageController.selectedIndex.value]
                                    .title ==
                                "العروض المطلوبة") {
                              print("GETTING THE VERY PAGE");
                              final expiredSystemsClients =
                                  accountClientController.clinets.value
                                      .where((client) => client.numbers!.any(
                                          (number) => number
                                              .getExpiredSystems()
                                              .isNotEmpty))
                                      .toList();
                              // Get.to(() => ExpiredSystemsPage(clients: expiredSystemsClients));
                              return ExpiredSystemsPage(
                                  clients: expiredSystemsClients);
                            } else {
                              return content[
                                  pageController.selectedIndex.value];
                            }
                          }()),
                    )),
                  ),
                ],
              ));
  }
}

class SideBar extends StatelessWidget {
  List<Page> pages;
  // Add controller instance
  final AccountDetailsController controller;

  SideBar({
    super.key,
    required this.pages,
  }) : controller =
            Get.find<AccountDetailsController>(); // Initialize in constructor

  @override
  Widget build(BuildContext context) {
    final colors = Get.theme.colorScheme;
    print('page icons number is ${pages.length}');
    List<String> titles = pages.map((e) => e.title).toList();
    List<Widget> icons = pages.map((e) => e.icon).toList();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF2C3E50), // Modern dark blue
            const Color(0xFF34495E), // Slightly lighter blue
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(5, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 200, // Increased height
            alignment: Alignment.center, // Center alignment
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: const AnimatedProfileAvatar(
              imagePath: 'assets/images/owner.png',
              size: 120,
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'كابتن / إسلام النني',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: 0.5,
            ),
          ),
          Divider(
            indent: 20,
            endIndent: 20,
            color: Colors.white.withOpacity(0.2),
            thickness: 1,
          ),
          Expanded(
            child: ListView.builder(
              itemCount: titles.length,
              itemBuilder: (context, index) {
                return TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: Duration(milliseconds: 400 + (index * 100)),
                  builder: (context, double value, child) {
                    return Transform.translate(
                      offset: Offset(50 * (1 - value), 0),
                      child: Opacity(
                        opacity: value,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8, // Reduced horizontal padding
                          ),
                          child: Obx(() {
                            final isSelected =
                                controller.selectedIndex.value == index;
                            return MouseRegion(
                              onEnter: (_) {},
                              onExit: (_) {},
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                transform: Matrix4.identity()
                                  ..scale(isSelected ? 1.02 : 1.0),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF3498DB)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF3498DB)
                                                .withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          )
                                        ]
                                      : null,
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      controller.selectedIndex.value = index;
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                        horizontal:
                                            12, // Reduced horizontal padding
                                      ),
                                      child: Row(
                                        mainAxisSize:
                                            MainAxisSize.min, // Added this
                                        children: [
                                          SizedBox(
                                            width: 24, // Fixed width for icon
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 300),
                                              transform: Matrix4.identity()
                                                ..scale(isSelected ? 1.2 : 1.0),
                                              child: icons[index],
                                            ),
                                          ),
                                          const SizedBox(
                                              width: 8), // Reduced spacing
                                          Expanded(
                                            child: Text(
                                              titles[index],
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: isSelected
                                                    ? Colors.white
                                                    : Colors.white
                                                        .withOpacity(0.8),
                                                fontSize: isSelected
                                                    ? 15
                                                    : 14, // Slightly reduced font size
                                              ),
                                              overflow: TextOverflow
                                                  .ellipsis, // Added this
                                            ),
                                          ),
                                          if (isSelected)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 4),
                                              child: Icon(
                                                Icons.chevron_right,
                                                color: Colors.white,
                                                size: 20, // Reduced icon size
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Add this extension method at the end of the file
extension HoverExtensions on Widget {
  Widget get addHover {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.identity()..scale(isHovered ? 1.05 : 1.0),
            child: this,
          ),
        );
      },
    );
  }
}
