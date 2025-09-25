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
import 'package:phone_system_app/views/pages/dues.dart';
import 'package:phone_system_app/views/pages/dues_management.dart';
import 'package:phone_system_app/views/pages/follow.dart';
import 'package:phone_system_app/views/pages/for_sale_number.dart';
import 'package:phone_system_app/views/pages/offers.dart';
import 'package:phone_system_app/views/pages/profit_management_page.dart';
import 'package:phone_system_app/views/pages/system_list.dart';
import 'package:phone_system_app/views/pages/create_user_page.dart';
import 'package:phone_system_app/pages/user_management_page.dart'; // Add this import
import 'package:phone_system_app/views/pages/letter_of_waiver.dart';
import 'package:phone_system_app/views/pages/filter_systems.dart';
import 'package:phone_system_app/views/pages/create_subscription_page.dart';
import 'package:phone_system_app/views/pages/clients_recets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'animated_profile_avatar.dart';
import 'package:image_picker/image_picker.dart';

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
  // Cache size calculation
  final Size screenSize = Size.zero;

  // Use const constructor for static pages list
  static final List<Page> _pages = [
    if (SupabaseAuthentication.myUser?.role == UserRoles.manager.index)
      Page(
        roles: [UserRoles.manager],
        content: AllClientsPage(),
        title: "بيانات العملاء",
        icon: const Icon(
          Icons.supervised_user_circle,
          color: Colors.black54,
        ),
      ),
    if (SupabaseAuthentication.myUser?.role == UserRoles.manager.index ||
        SupabaseAuthentication.myUser?.role == UserRoles.assistant.index)
      Page(
        roles: [UserRoles.manager, UserRoles.assistant],
        content: DuesManagement(),
        title: "المستحقات",
        icon: const Icon(
          Icons.payment,
          color: Colors.black54,
        ),
      ),
    if (SupabaseAuthentication.myUser?.role == UserRoles.manager.index ||
        SupabaseAuthentication.myUser?.role == UserRoles.assistant.index)
      Page(
        roles: [UserRoles.manager, UserRoles.assistant],
        content: const ClientsReceipts(),
        title: "الفواتير الشهرية",
        icon: const Icon(
          Icons.receipt_long,
          color: Colors.black54,
        ),
      ),
    if (SupabaseAuthentication.myUser?.role == UserRoles.manager.index ||
        SupabaseAuthentication.myUser?.role == UserRoles.assistant.index)
      Page(
        roles: [UserRoles.manager, UserRoles.assistant],
        content: const DuesPage(),
        title: "المديونات",
        icon: const Icon(
          Icons.attach_money_rounded,
          color: Colors.black54,
        ),
      ),
    if (SupabaseAuthentication.myUser?.role == UserRoles.manager.index)
      Page(
        roles: [UserRoles.manager],
        content: OfferManagement(),
        title: "العروض المطلوبة",
        icon: const Icon(
          Icons.card_giftcard_rounded,
          color: Colors.black54,
        ),
      ),
    if (SupabaseAuthentication.myUser?.role == UserRoles.manager.index)
      Page(
        roles: [UserRoles.manager],
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
    if (SupabaseAuthentication.myUser?.role == UserRoles.manager.index)
      Page(
        roles: [UserRoles.manager],
        content: Container(
          color: Colors.white,
          constraints: const BoxConstraints.expand(),
          child: ProfitManagement(),
        ),
        icon: const Icon(
          Icons.account_balance_wallet,
          color: Colors.black54,
        ),
        title: "الربح و الاحصاء",
      ),
    if (SupabaseAuthentication.myUser?.role == UserRoles.manager.index)
      Page(
        roles: [UserRoles.manager],
        content: Container(
          color: Colors.white,
          constraints: const BoxConstraints.expand(),
          child: FilterSystemsPage(),
        ),
        icon: const Icon(
          Icons.assessment,
          color: Colors.black54,
        ),
        title: "احصاء الانظمة",
      ),
    Page(
      roles: [UserRoles.manager, UserRoles.assistant],
      content: Container(
        color: Colors.white,
        constraints: const BoxConstraints.expand(),
        child: ForSaleNumbers(),
      ),
      icon: const Icon(
        Icons.phone_android,
        color: Colors.black54,
      ),
      title: "أرقام للبيع",
    ),
    Page(
      roles: [UserRoles.manager, UserRoles.assistant],
      content: Container(
        color: Colors.white,
        constraints: const BoxConstraints.expand(),
        child: Follow(),
      ),
      icon: const Icon(
        Icons.toc_rounded,
        color: Colors.black54,
      ),
      title: "المتابعة",
    ),
    if (SupabaseAuthentication.myUser?.role == UserRoles.manager.index)
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
    if (SupabaseAuthentication.myUser?.role == UserRoles.manager.index)
      Page(
        roles: [UserRoles.manager],
        content: Container(
          color: Colors.white,
          constraints: const BoxConstraints.expand(),
          child: LetterOfWaiver(),
        ),
        icon: const Icon(
          Icons.description,
          color: Colors.black54,
        ),
        title: "خطاب تنازل",
      ),
    if (SupabaseAuthentication.myUser?.role == UserRoles.manager.index)
      Page(
        roles: [UserRoles.manager],
        content: const CreateSubscriptionPage(),
        icon: const Icon(
          Icons.add_circle_outline,
          color: Colors.black54,
        ),
        title: "اشتراك جديد",
      ),
  ];

  // Memoize filtered pages
  late final filteredPages = _pages
      .where((page) =>
          (page.roles
              .map((role) => role.index)
              .contains(SupabaseAuthentication.myUser!.role)) ||
          (page.title == "انشاء مستخدم" &&
              SupabaseAuthentication.myUser!.role == UserRoles.admin.index))
      .toList();

  ctrl.AccountDetailsController pageController =
      Get.put(ctrl.AccountDetailsController());
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    // Cache MediaQuery result
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 1200;
    final colors = Get.theme.colorScheme;
    final content = _pages
        .map(
          (e) => e.content,
        )
        .toList();

    // Move controller initialization to the beginning of build method
    final accountDetailsController = Get.put(AccountDetailsController());

    return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA), // Modern light background
        appBar: AppBar(
          backgroundColor: const Color(0xFF1a237e), // Dark blue
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF1a237e), // Dark blue
                  Color(0xFF0d47a1), // Slightly lighter blue
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          leading: (MediaQuery.of(context).size.width < 1200)
              ? Builder(
                  builder: (BuildContext context) {
                    return IconButton(
                      icon: const Icon(Icons.menu,
                          color: Colors.white), // Updated color
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
                  color: Colors.white, // Updated color
                  fontWeight: FontWeight.bold,
                  fontSize: 22),
            ),
            const SizedBox(width: 5),
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
                icon: const Icon(Icons.calendar_today,
                    color: Colors.white)), // Updated color
            Builder(
              builder: (BuildContext context) {
                return IconButton(
                  icon: const Icon(Icons.keyboard_arrow_left,
                      color: Colors.white), // Updated color
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
                              pages: _pages
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
            ? Obx(() {
                final currentIndex = pageController.selectedIndex.value;

                return Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF1a237e), // Dark blue
                        Color(0xFF0d47a1), // Slightly lighter blue
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 12,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: CurvedNavigationBar(
                    key: _bottomNavigationKey,
                    index: currentIndex,
                    height: 65.0,
                    items: filteredPages
                        .map((page) => Container(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                (page.icon as Icon).icon!,
                                size: 28,
                                color: Colors.white,
                              ),
                            ))
                        .toList(),
                    color: const Color(0xFF1a237e), // Dark blue
                    buttonBackgroundColor:
                        const Color(0xFF2196F3), // Accent blue for selected
                    backgroundColor: Colors.transparent,
                    animationCurve: Curves.easeInOutCubic,
                    animationDuration: const Duration(milliseconds: 300),
                    onTap: (index) =>
                        pageController.selectedIndex.value = index,
                    letIndexChange: (_) => true,
                  ),
                );
              })
            : null,
        body: isMobile
            ? Obx(() {
                final accountClientController = Get.find<AccountClientInfo>();
                final currentPage = _pages[pageController.selectedIndex.value];

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
                      pages: _pages
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
                            print(_pages[pageController.selectedIndex.value]
                                .title);
                            final accountClientController =
                                Get.find<AccountClientInfo>();
                            if (_pages[pageController.selectedIndex.value]
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
  final AccountDetailsController controller;

  SideBar({
    super.key,
    required this.pages,
  }) : controller = Get.find<AccountDetailsController>();

  @override
  Widget build(BuildContext context) {
    final colors = Get.theme.colorScheme;
    List<String> titles = pages.map((e) => e.title).toList();
    List<Widget> icons = pages.map((e) => e.icon).toList();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1a237e), // Dark blue
            const Color(0xFF0d47a1), // Slightly lighter blue
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: const Offset(5, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 220,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 25),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1a237e).withOpacity(0.95),
                  const Color(0xFF0d47a1).withOpacity(0.90),
                ],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Decorative circle background
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue[300]!.withOpacity(0.2),
                        Colors.blue[400]!.withOpacity(0.1),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 2,
                    ),
                  ),
                ),
                // Main avatar container
                GestureDetector(
                  onTap: () => controller.uploadNewImage(),
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue[400]!,
                          Colors.blue[600]!,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                        BoxShadow(
                          color: Colors.blue[300]!.withOpacity(0.5),
                          blurRadius: 30,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Avatar image
                        Obx(() {
                          final images = controller.userImages;
                          final latestImage =
                              images.isNotEmpty ? images.last : null;

                          return Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 3,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(65),
                              child: AnimatedProfileAvatar(
                                imagePath:
                                    latestImage ?? 'assets/images/owner.png',
                                isNetworkImage: latestImage != null,
                              ),
                            ),
                          );
                        }),
                        // Edit button with animated hover effect
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFF2196f3),
                                  const Color(0xFF1976d2),
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue[400]!.withOpacity(0.5),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.add_photo_alternate,
                              color: Colors.white,
                              size: 20,
                            ),
                          ).addHover,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'كابتن / إسلام النني',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.3),
                  Colors.white.withOpacity(0.1),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: Obx(() {
                            final isSelected =
                                controller.selectedIndex.value == index;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: isSelected
                                    ? LinearGradient(
                                        colors: [
                                          const Color(0xFF4FC3F7),
                                          const Color(0xFF2196F3),
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      )
                                    : null,
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF2196F3)
                                              .withOpacity(0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () =>
                                      controller.selectedIndex.value = index,
                                  hoverColor: Colors.white.withOpacity(0.1),
                                  splashColor: Colors.white.withOpacity(0.2),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                    child: Row(
                                      children: [
                                        AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 200),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? Colors.white.withOpacity(0.2)
                                                : Colors.white.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.all(8),
                                          child: IconTheme(
                                            data: IconThemeData(
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.white70,
                                              size: 22,
                                            ),
                                            child: icons[index],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                titles[index],
                                                style: TextStyle(
                                                  color: isSelected
                                                      ? Colors.white
                                                      : Colors.white70,
                                                  fontWeight: isSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.w500,
                                                  fontSize:
                                                      isSelected ? 15 : 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isSelected)
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: const Icon(
                                              Icons.arrow_forward_ios_rounded,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                          ),
                                      ],
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
