import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/controllers/account_client_info_data.dart';
import 'package:phone_system_app/controllers/account_details_controller.dart';
import 'package:phone_system_app/controllers/account_profit_controller.dart';
import 'package:phone_system_app/services/backend/auth.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';
import 'package:phone_system_app/views/pages/all_clinets_page.dart';
import 'package:phone_system_app/views/pages/dues.dart';
import 'package:phone_system_app/views/pages/dues_management.dart';
import 'package:phone_system_app/views/pages/follow.dart';
import 'package:phone_system_app/views/pages/for_sale_number.dart';
import 'package:phone_system_app/views/pages/offers.dart';
import 'package:phone_system_app/views/pages/profit_management_page.dart';
import 'package:phone_system_app/views/pages/system_list.dart';
import 'package:phone_system_app/pages/user_management_page.dart';
import 'package:phone_system_app/views/pages/letter_of_waiver.dart';
import 'package:phone_system_app/views/pages/filter_systems.dart';
import 'package:phone_system_app/views/pages/create_subscription_page.dart';
import 'package:phone_system_app/views/pages/clients_recets.dart';
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

class AccountDetails extends StatefulWidget {
  const AccountDetails({super.key});

  @override
  State<AccountDetails> createState() => _AccountDetailsState();
}

class _AccountDetailsState extends State<AccountDetails>
    with TickerProviderStateMixin {
  final AccountDetailsController pageController =
      Get.put(AccountDetailsController());
  late AnimationController _waveController;

  static List<Page> get _pages => [
        if (SupabaseAuthentication.myUser?.role == UserRoles.manager.index)
          Page(
            roles: [UserRoles.manager],
            content: const AllClientsPage(),
            title: "بيانات العملاء",
            icon: const Icon(Icons.people_rounded),
          ),
        if (SupabaseAuthentication.myUser?.role == UserRoles.manager.index ||
            SupabaseAuthentication.myUser?.role == UserRoles.assistant.index)
          Page(
            roles: [UserRoles.manager, UserRoles.assistant],
            content: DuesManagement(),
            title: "المستحقات",
            icon: const Icon(Icons.payment_rounded),
          ),
        if (SupabaseAuthentication.myUser?.role == UserRoles.manager.index ||
            SupabaseAuthentication.myUser?.role == UserRoles.assistant.index)
          Page(
            roles: [UserRoles.manager, UserRoles.assistant],
            content: const ClientsReceipts(),
            title: "الفواتير الشهرية",
            icon: const Icon(Icons.receipt_long_rounded),
          ),
        if (SupabaseAuthentication.myUser?.role == UserRoles.manager.index ||
            SupabaseAuthentication.myUser?.role == UserRoles.assistant.index)
          Page(
            roles: [UserRoles.manager, UserRoles.assistant],
            content: const DuesPage(),
            title: "المديونات",
            icon: const Icon(Icons.attach_money_rounded),
          ),
        if (SupabaseAuthentication.myUser?.role == UserRoles.manager.index)
          Page(
            roles: [UserRoles.manager],
            content: OfferManagement(),
            title: "العروض المطلوبة",
            icon: const Icon(Icons.card_giftcard_rounded),
          ),
        if (SupabaseAuthentication.myUser?.role == UserRoles.manager.index)
          Page(
            roles: [UserRoles.manager],
            content: SystemList(),
            icon: const Icon(Icons.play_lesson_rounded),
            title: "الباقات المتاحة",
          ),
        if (SupabaseAuthentication.myUser?.role == UserRoles.manager.index)
          Page(
            roles: [UserRoles.manager],
            content: ProfitManagement(),
            icon: const Icon(Icons.account_balance_wallet_rounded),
            title: "الربح و الاحصاء",
          ),
        if (SupabaseAuthentication.myUser?.role == UserRoles.manager.index)
          Page(
            roles: [UserRoles.manager],
            content: FilterSystemsPage(),
            icon: const Icon(Icons.assessment_rounded),
            title: "احصاء الانظمة",
          ),
        Page(
          roles: [UserRoles.manager, UserRoles.assistant],
          content: ForSaleNumbers(),
          icon: const Icon(Icons.phone_android_rounded),
          title: "أرقام للبيع",
        ),
        Page(
          roles: [UserRoles.manager, UserRoles.assistant],
          content: Follow(),
          icon: const Icon(Icons.toc_rounded),
          title: "المتابعة",
        ),
        if (SupabaseAuthentication.myUser?.role == UserRoles.manager.index)
          Page(
            roles: [UserRoles.manager],
            content: UserManagementPage(),
            icon: const Icon(Icons.admin_panel_settings_rounded),
            title: "إدارة المستخدمين",
          ),
        if (SupabaseAuthentication.myUser?.role == UserRoles.manager.index)
          Page(
            roles: [UserRoles.manager],
            content: LetterOfWaiver(),
            icon: const Icon(Icons.description_rounded),
            title: "خطاب تنازل",
          ),
        if (SupabaseAuthentication.myUser?.role == UserRoles.manager.index)
          Page(
            roles: [UserRoles.manager],
            content: const CreateSubscriptionPage(),
            icon: const Icon(Icons.add_circle_outline_rounded),
            title: "اشتراك جديد",
          ),
      ];

  List<Page> get filteredPages => _pages
      .where((page) => page.roles
          .map((r) => r.index)
          .contains(SupabaseAuthentication.myUser!.role))
      .toList();

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    // Clean up controllers when leaving the page
    _cleanupControllers();
    super.dispose();
  }

  void _cleanupControllers() {
    if (Get.isRegistered<AccountDetailsController>()) {
      Get.delete<AccountDetailsController>(force: true);
    }
    if (Get.isRegistered<AccountClientInfo>()) {
      Get.delete<AccountClientInfo>(force: true);
    }
    if (Get.isRegistered<ProfitController>()) {
      Get.delete<ProfitController>(force: true);
    }
    if (Get.isRegistered<FollowController>()) {
      Get.delete<FollowController>(force: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 1200;

    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      appBar: _buildAppBar(),
      drawer: isMobile ? _buildDrawer() : null,
      bottomNavigationBar: isMobile ? _buildBottomNav() : null,
      body: Stack(
        children: [
          // Animated Background
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              return CustomPaint(
                painter: _BackgroundPainter(animation: _waveController.value),
                size: Size.infinite,
              );
            },
          ),
          // Grid
          Opacity(
            opacity: 0.02,
            child: CustomPaint(
              painter: _GridPainter(),
              size: Size.infinite,
            ),
          ),
          // Content
          isMobile
              ? Obx(() {
                  final currentPage =
                      filteredPages[pageController.selectedIndex.value];
                  if (currentPage.title == "العروض المطلوبة") {
                    final controller = Get.find<AccountClientInfo>();
                    final expiredClients = controller.clinets.value
                        .where((c) => c.numbers!
                            .any((n) => n.getExpiredSystems().isNotEmpty))
                        .toList();
                    return ExpiredSystemsPage(clients: expiredClients);
                  }
                  return currentPage.content;
                })
              : Row(
                  children: [
                    _buildSidebar(),
                    Expanded(
                      child: Obx(() {
                        final currentPage =
                            filteredPages[pageController.selectedIndex.value];
                        if (currentPage.title == "العروض المطلوبة") {
                          final controller = Get.find<AccountClientInfo>();
                          final expiredClients = controller.clinets.value
                              .where((c) => c.numbers!
                                  .any((n) => n.getExpiredSystems().isNotEmpty))
                              .toList();
                          return ExpiredSystemsPage(clients: expiredClients);
                        }
                        return currentPage.content;
                      }),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0a0a0a),
      elevation: 0,
      leading: Builder(
        builder: (context) {
          if (MediaQuery.of(context).size.width < 1200) {
            return IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          }
          return const SizedBox();
        },
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [Color(0xFFff6b6b), Color(0xFFfeca57)],
              ),
            ),
            child: Text(
              '${AccountClientInfo.to.currentAccount.day}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          tooltip: "يوم التحصيل",
          icon: const Icon(Icons.calendar_today_rounded, color: Colors.white),
          onPressed: () async {
            final data = await showDatePicker(
              context: context,
              firstDate: DateTime.now().subtract(const Duration(days: 30)),
              lastDate: DateTime.now().add(const Duration(days: 30)),
            );
            if (data != null) {
              final account = AccountClientInfo.to.currentAccount;
              account.day = data.day;
              await BackendServices.instance.accountRepository.update(account);
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () {
            Get.delete<AccountDetailsController>(force: true);
            Get.delete<AccountClientInfo>(force: true);
            Get.delete<ProfitController>(force: true);
            Get.delete<FollowController>(force: true);
            Get.back();
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Obx(() {
      final currentIndex = pageController.selectedIndex.value;

      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a1a),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filteredPages.asMap().entries.map((entry) {
                  final index = entry.key;
                  final page = entry.value;
                  final isSelected = currentIndex == index;

                  return GestureDetector(
                    onTap: () => pageController.selectedIndex.value = index,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [Color(0xFFff6b6b), Color(0xFFfeca57)],
                              )
                            : null,
                        color: isSelected
                            ? null
                            : Colors.white.withValues(alpha: 0.05),
                      ),
                      child: Icon(
                        (page.icon as Icon).icon,
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                        size: 22,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF0a0a0a),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => pageController.uploadNewImage(),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFff6b6b), Color(0xFFfeca57)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFff6b6b).withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Obx(() {
                          final images = pageController.userImages;
                          final latestImage =
                              images.isNotEmpty ? images.last : null;
                          return AnimatedProfileAvatar(
                            imagePath: latestImage ?? 'assets/images/owner.png',
                            isNetworkImage: latestImage != null,
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'كابتن / إسلام النني',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              height: 1,
              color: Colors.white.withValues(alpha: 0.1),
            ),
            // Menu Items
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredPages.length,
                itemBuilder: (context, index) {
                  return Obx(() {
                    final isSelected =
                        pageController.selectedIndex.value == index;
                    final page = filteredPages[index];

                    return GestureDetector(
                      onTap: () {
                        pageController.selectedIndex.value = index;
                        Navigator.pop(context);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFFff6b6b),
                                    Color(0xFFfeca57)
                                  ],
                                )
                              : null,
                          color: isSelected
                              ? null
                              : Colors.white.withValues(alpha: 0.05),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              (page.icon as Icon).icon,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.6),
                              size: 22,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                page.title,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.7),
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                          ],
                        ),
                      ),
                    );
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: const Color(0xFF0f0f0f),
        border: Border(
          right: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => pageController.uploadNewImage(),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(35),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFff6b6b), Color(0xFFfeca57)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFff6b6b).withValues(alpha: 0.3),
                          blurRadius: 25,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(35),
                      child: Obx(() {
                        final images = pageController.userImages;
                        final latestImage =
                            images.isNotEmpty ? images.last : null;
                        return AnimatedProfileAvatar(
                          imagePath: latestImage ?? 'assets/images/owner.png',
                          isNetworkImage: latestImage != null,
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'كابتن / إسلام النني',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            height: 1,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          // Menu Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredPages.length,
              itemBuilder: (context, index) {
                return Obx(() {
                  final isSelected =
                      pageController.selectedIndex.value == index;
                  final page = filteredPages[index];

                  return GestureDetector(
                    onTap: () => pageController.selectedIndex.value = index,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [Color(0xFFff6b6b), Color(0xFFfeca57)],
                              )
                            : null,
                        color: isSelected ? null : Colors.transparent,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFff6b6b)
                                      .withValues(alpha: 0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : Colors.white.withValues(alpha: 0.05),
                            ),
                            child: Icon(
                              (page.icon as Icon).icon,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.6),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              page.title,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.7),
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                              child: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Background Painter
class _BackgroundPainter extends CustomPainter {
  final double animation;

  _BackgroundPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Top glow
    paint.shader = RadialGradient(
      center: const Alignment(-0.5, -0.5),
      radius: 1.5,
      colors: [
        const Color(0xFFff6b6b).withValues(alpha: 0.08),
        const Color(0xFFff6b6b).withValues(alpha: 0.0),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.5), paint);

    // Bottom wave
    paint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFFfeca57).withValues(alpha: 0.05),
        const Color(0xFFfeca57).withValues(alpha: 0.0),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    path.moveTo(0, size.height * 0.9);

    for (double i = 0; i <= size.width; i++) {
      final y = size.height * 0.9 +
          math.sin((i / size.width * 2 * math.pi) + (animation * 2 * math.pi)) *
              15;
      path.lineTo(i, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BackgroundPainter oldDelegate) =>
      animation != oldDelegate.animation;
}

// Grid Painter
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1;

    const spacing = 50.0;

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
