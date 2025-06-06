import 'dart:math';
import 'dart:async';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/controllers/account_client_info_data.dart';
import 'package:phone_system_app/controllers/account_profit_controller.dart';
import 'package:phone_system_app/controllers/account_view_controller.dart';
import 'package:phone_system_app/models/account.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';
import 'package:phone_system_app/views/account_details.dart';
import 'package:phone_system_app/views/pages/charts_page.dart';
import 'package:phone_system_app/views/pages/table_page.dart';
import 'package:phone_system_app/services/backend/backend_service_type.dart';

class AccountsView extends StatelessWidget {
  AccountsView({super.key});
  final controller = Get.put(AccountViewController());

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    double screenWidth = size.width;
    double minWidth = 200;

    return Obx(() {
      final data = controller.getCurrentAccounts();
      final bool useVerticalLayout = data.length == 2;

      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            "الاكونتات المتاحة",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              letterSpacing: 1.2,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
          ),
          actions: [
            _buildAppBarAction(
              tooltip: "تسجيل الخروج",
              icon: Icons.logout_rounded,
              color: Colors.red.shade700,
              onPressed: () async {
                await _showLogoutConfirmation(context);
              },
            ),
            _buildAppBarAction(
              tooltip: "اظهار بينات العملاء",
              icon: Icons.table_chart_rounded,
              color: Colors.blue.shade600,
              onPressed: () {
                Get.to(InfoTablePage(), transition: Transition.rightToLeft);
              },
            ),
          ],
          leading: _buildAppBarAction(
            tooltip: "عرض الاحصائيات",
            icon: FontAwesomeIcons.chartPie,
            color: Colors.purple.shade600,
            onPressed: () {
              Get.to(ChartsPage(), transition: Transition.leftToRight);
            },
          ),
        ),
        body: Stack(
          children: [
            // Background design elements
            Positioned.fill(
              child: CustomPaint(
                painter: BackgroundPainter(),
              ),
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: (controller.isLoading.value)
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.blue),
                            strokeWidth: 5,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "جاري تحميل البيانات...",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.1),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: useVerticalLayout
                          ? _buildVerticalLayout(data, screenWidth, size)
                          : _buildGridLayout(data, screenWidth, minWidth),
                    ),
            ),

            // Welcome overlay
            _buildWelcomeOverlay(),
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(),
      );
    });
  }

  Widget _buildAppBarAction({
    required String tooltip,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Tooltip(
        message: tooltip,
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            splashRadius: 24,
            onPressed: onPressed,
            icon: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showLogoutConfirmation(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('تأكيد تسجيل الخروج'),
          content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
          actions: <Widget>[
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'تسجيل الخروج',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await BackendServices.instance.supabaseAuthentication.signOut();
                html.window.location.reload();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildVerticalLayout(
      List<Account> data, double screenWidth, Size size) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: data.map((account) {
          return SizedBox(
            width: screenWidth * 0.9, // 90% of screen width
            height: size.height * 0.40, // 40% of screen height
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: AccountCard(
                width: screenWidth * 0.9,
                account: account,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGridLayout(
      List<Account> data, double screenWidth, double minWidth) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        itemCount: data.length,
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: max(
              (screenWidth ~/ minWidth != 0) ? screenWidth ~/ minWidth : 1, 2),
          childAspectRatio: 0.95,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemBuilder: (context, index) {
          double cardWidth = screenWidth /
              max((screenWidth ~/ minWidth != 0) ? screenWidth ~/ minWidth : 1,
                  2);
          return AccountCard(
            width: cardWidth,
            account: data[index],
          );
        },
      ),
    );
  }

  Widget _buildWelcomeOverlay() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 2),
      curve: Curves.easeOutCubic,
      onEnd: () {
        Future.delayed(const Duration(seconds: 3), () {
          controller.showWelcome.value = false;
        });
      },
      builder: (context, value, child) {
        return Obx(
          () => controller.showWelcome.value
              ? GestureDetector(
                  onTapDown: (_) => controller.showWelcome.value = false,
                  child: Container(
                    color: Colors.white,
                    child: Stack(
                      children: [
                        // Background particles
                        ...List.generate(20, (index) {
                          final size = Random().nextDouble() * 20 + 5;
                          return Positioned(
                            left: Random().nextDouble() * Get.width,
                            top: Random().nextDouble() * Get.height,
                            child: Opacity(
                              opacity: 0.1 + Random().nextDouble() * 0.2,
                              child: Container(
                                width: size,
                                height: size,
                                decoration: BoxDecoration(
                                  color: [
                                    Colors.blue.shade300,
                                    Colors.purple.shade300,
                                    Colors.pink.shade300,
                                  ][Random().nextInt(3)],
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          );
                        }),

                        // Main content
                        Center(
                          child: Transform.scale(
                            scale: 0.8 + (value * 0.2),
                            child: Opacity(
                              opacity: value,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Avatar with animated border
                                  Container(
                                    width: 160,
                                    height: 160,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: SweepGradient(
                                        colors: [
                                          Colors.blue.shade400,
                                          Colors.purple.shade400,
                                          Colors.pink.shade400,
                                          Colors.blue.shade400,
                                        ],
                                        stops: const [0.0, 0.33, 0.66, 1.0],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blue.withOpacity(0.3),
                                          spreadRadius: 5,
                                          blurRadius: 15,
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(
                                          5), // Border width
                                      child: ClipOval(
                                        child: Image.asset(
                                          'assets/images/owner.png',
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                  ShaderMask(
                                    shaderCallback: (bounds) => LinearGradient(
                                      colors: [
                                        Colors.blue.shade500,
                                        Colors.purple.shade500
                                      ],
                                    ).createShader(bounds),
                                    child: const Text(
                                      'اهلا بك كابتن اسلام النني',
                                      style: TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.2),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      'نتمني لك يوما سعيدا',
                                      style: TextStyle(
                                        fontSize: 22,
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                  ElevatedButton(
                                    onPressed: () {
                                      controller.showWelcome.value = false;
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade600,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 32,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      elevation: 5,
                                    ),
                                    child: const Text(
                                      'ابدأ الآن',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildFloatingActionButton() {
    return const SizedBox.shrink();
  }
}

// Background patterns
class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.shade100.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    // Draw top-right circle
    canvas.drawCircle(
      Offset(size.width - 50, 50),
      100,
      paint..color = Colors.purple.shade100.withOpacity(0.2),
    );

    // Draw bottom-left circle
    canvas.drawCircle(
      Offset(50, size.height - 100),
      120,
      paint..color = Colors.blue.shade100.withOpacity(0.2),
    );

    // Draw center-right oval
    final rectPaint = Paint()
      ..color = Colors.pink.shade100.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width - 100, size.height / 2),
        width: 100,
        height: 200,
      ),
      rectPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AccountCard extends StatefulWidget {
  final Account account;
  final double width;

  const AccountCard({super.key, required this.width, required this.account});

  @override
  _AccountCardState createState() => _AccountCardState();
}

class _AccountCardState extends State<AccountCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? Colors.blue.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: _isHovered ? 20 : 10,
              spreadRadius: _isHovered ? 5 : 0,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Modern background pattern
            Positioned.fill(
              child: CustomPaint(
                painter: ModernBackgroundPainter(
                  isHovered: _isHovered,
                ),
              ),
            ),

            // Center the account icon and name
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade100.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.account_balance,
                      size: 50,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 25),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      widget.account.name!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Clickable overlay
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    if (Get.currentRoute != '/accountDetails') {
                      Get.put(
                          AccountClientInfo(currentAccount: widget.account));
                      final p = Get.put(ProfitController());
                      p.updateTheProfitByAccount(widget.account);
                      Get.to(
                        AccountDetails(),
                        arguments: widget.account,
                        transition: Transition.fadeIn,
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ModernBackgroundPainter extends CustomPainter {
  final bool isHovered;

  ModernBackgroundPainter({required this.isHovered});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.shade50.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // Draw subtle geometric patterns
    final path = Path()
      ..moveTo(size.width * 0.8, 0)
      ..quadraticBezierTo(
        size.width,
        size.height * 0.3,
        size.width * 0.8,
        size.height * 0.6,
      );

    canvas.drawPath(path, paint);

    // Draw accent circle
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.9),
      20,
      Paint()..color = Colors.purple.shade50.withOpacity(0.3),
    );
  }

  @override
  bool shouldRepaint(ModernBackgroundPainter oldDelegate) =>
      isHovered != oldDelegate.isHovered;
}
