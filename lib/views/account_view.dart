import 'dart:math';
import 'dart:async';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    double minWidth = 280;

    return Obx(() {
      final data = controller.getCurrentAccounts();
      final bool useVerticalLayout = data.length == 2;

      return Scaffold(
        backgroundColor: const Color(0xFF0A0B0F),
        extendBodyBehindAppBar: true,
        appBar: _buildModernAppBar(),
        body: Stack(
          children: [
            // Animated background
            _buildAnimatedBackground(),

            // Floating particles
            _buildFloatingParticles(),

            // Main content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: (controller.isLoading.value)
                    ? _buildModernLoader()
                    : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 800),
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.3),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              )),
                              child: child,
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            _buildPageHeader(),
                            const SizedBox(height: 30),
                            Expanded(
                              child: useVerticalLayout
                                  ? _buildVerticalLayout(
                                      data, screenWidth, size)
                                  : _buildGridLayout(
                                      data, screenWidth, minWidth),
                            ),
                          ],
                        ),
                      ),
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

  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.purple.shade900.withOpacity(0.6),
              Colors.blue.shade900.withOpacity(0.4),
            ],
          ),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(30),
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
      ),
      actions: [
        _buildGlassButton(
          tooltip: "اظهار بينات العملاء",
          icon: Icons.table_chart_rounded,
          gradient: [Colors.blue.shade400, Colors.cyan.shade300],
          onPressed: () {
            Get.to(InfoTablePage(), transition: Transition.rightToLeft);
          },
        ),
        _buildGlassButton(
          tooltip: "تسجيل الخروج",
          icon: Icons.logout_rounded,
          gradient: [Colors.red.shade400, Colors.pink.shade300],
          onPressed: () async {
            await _showLogoutConfirmation(Get.context!);
          },
        ),
        const SizedBox(width: 16),
      ],
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: _buildGlassButton(
          tooltip: "عرض الاحصائيات",
          icon: FontAwesomeIcons.chartPie,
          gradient: [Colors.purple.shade400, Colors.indigo.shade300],
          onPressed: () {
            Get.to(ChartsPage(), transition: Transition.leftToRight);
          },
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required String tooltip,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(colors: gradient),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withOpacity(0.1),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: IconButton(
            splashRadius: 20,
            onPressed: onPressed,
            icon: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Positioned.fill(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(seconds: 20),
        builder: (context, value, child) {
          return CustomPaint(
            painter: ModernBackgroundPainter(animationValue: value),
          );
        },
      ),
    );
  }

  Widget _buildFloatingParticles() {
    return Positioned.fill(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 2 * pi),
        duration: const Duration(seconds: 30),
        builder: (context, rotation, child) {
          return Stack(
            children: List.generate(15, (index) {
              final size = Random(index).nextDouble() * 6 + 2;
              final speed = Random(index + 100).nextDouble() * 0.5 + 0.2;
              final offsetX = sin(rotation * speed + index) * 50;
              final offsetY = cos(rotation * speed * 0.7 + index) * 30;

              return Positioned(
                left: Get.width * Random(index + 50).nextDouble() + offsetX,
                top: Get.height * Random(index + 25).nextDouble() + offsetY,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: [
                      Colors.blue.shade300,
                      Colors.purple.shade300,
                      Colors.cyan.shade300,
                      Colors.pink.shade300,
                    ][index % 4]
                        .withOpacity(0.4),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: [
                          Colors.blue.shade300,
                          Colors.purple.shade300,
                          Colors.cyan.shade300,
                          Colors.pink.shade300,
                        ][index % 4]
                            .withOpacity(0.2),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildPageHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
      ),
    );
  }

  Widget _buildModernLoader() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.purple.shade400],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 30),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [Colors.blue.shade300, Colors.purple.shade300],
            ).createShader(bounds),
            child: const Text(
              "جاري تحميل البيانات...",
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showLogoutConfirmation(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1B23),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          title: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [Colors.white, Colors.blue.shade200],
            ).createShader(bounds),
            child: const Text(
              'تأكيد تسجيل الخروج',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          content: Text(
            'هل أنت متأكد من رغبتك في تسجيل الخروج؟',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'إلغاء',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade400, Colors.pink.shade400],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'تسجيل الخروج',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await BackendServices.instance.supabaseAuthentication
                      .signOut();
                  html.window.location.reload();
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVerticalLayout(
      List<Account> data, double screenWidth, Size size) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: data.asMap().entries.map((entry) {
          int index = entry.key;
          Account account = entry.value;

          return Expanded(
            child: Container(
              margin: EdgeInsets.only(
                bottom: index < data.length - 1 ? 20 : 0,
              ),
              child: ModernAccountCard(
                account: account,
                index: index,
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
      padding: const EdgeInsets.all(20),
      child: GridView.builder(
        itemCount: data.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: max((screenWidth ~/ minWidth).clamp(1, 4), 2),
          childAspectRatio: 0.85,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
        ),
        itemBuilder: (context, index) {
          return ModernAccountCard(
            account: data[index],
            index: index,
          );
        },
      ),
    );
  }

  Widget _buildWelcomeOverlay() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1500),
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
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF0A0B0F),
                          Colors.purple.shade900.withOpacity(0.8),
                          Colors.blue.shade900.withOpacity(0.6),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Animated background particles
                        ...List.generate(25, (index) {
                          final size = Random().nextDouble() * 15 + 3;
                          return Positioned(
                            left: Random().nextDouble() * Get.width,
                            top: Random().nextDouble() * Get.height,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: Duration(
                                milliseconds: 2000 + Random().nextInt(3000),
                              ),
                              builder: (context, animValue, child) {
                                return Transform.scale(
                                  scale: animValue,
                                  child: Opacity(
                                    opacity:
                                        (0.1 + Random().nextDouble() * 0.3) *
                                            animValue,
                                    child: Container(
                                      width: size,
                                      height: size,
                                      decoration: BoxDecoration(
                                        gradient: RadialGradient(
                                          colors: [
                                            [
                                              Colors.blue.shade300,
                                              Colors.purple.shade300,
                                              Colors.cyan.shade300,
                                              Colors.pink.shade300,
                                            ][Random().nextInt(4)],
                                            Colors.transparent,
                                          ],
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }),

                        // Main welcome content
                        Center(
                          child: Transform.scale(
                            scale: 0.7 + (value * 0.3),
                            child: Opacity(
                              opacity: value,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Avatar with modern design
                                  Container(
                                    width: 180,
                                    height: 180,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: SweepGradient(
                                        colors: [
                                          Colors.blue.shade400,
                                          Colors.purple.shade400,
                                          Colors.cyan.shade400,
                                          Colors.pink.shade400,
                                          Colors.blue.shade400,
                                        ],
                                        stops: const [
                                          0.0,
                                          0.25,
                                          0.5,
                                          0.75,
                                          1.0
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blue.withOpacity(0.4),
                                          spreadRadius: 8,
                                          blurRadius: 20,
                                        ),
                                      ],
                                    ),
                                    child: Container(
                                      margin: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFF1A1B23),
                                      ),
                                      child: Container(
                                        margin: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          image: DecorationImage(
                                            image: AssetImage(
                                                'assets/images/owner.png'),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 40),

                                  // Welcome text with gradient effect
                                  ShaderMask(
                                    shaderCallback: (bounds) => LinearGradient(
                                      colors: [
                                        Colors.white,
                                        Colors.blue.shade200,
                                        Colors.purple.shade200,
                                      ],
                                    ).createShader(bounds),
                                    child: const Text(
                                      'اهلا بك كابتن اسلام النني',
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Subtitle with glass effect
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 30,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(25),
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withOpacity(0.1),
                                          Colors.white.withOpacity(0.05),
                                        ],
                                      ),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 10,
                                          spreadRadius: 0,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      'نتمني لك يوما سعيدا',
                                      style: TextStyle(
                                        fontSize: 24,
                                        color: Colors.white.withOpacity(0.9),
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 40),

                                  // Modern CTA button
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.blue.shade600,
                                          Colors.purple.shade600,
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blue.withOpacity(0.4),
                                          blurRadius: 15,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        controller.showWelcome.value = false;
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 40,
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                      ),
                                      child: const Text(
                                        'ابدأ الآن',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
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
    return Container(
      
      child: FloatingActionButton(
        backgroundColor: Colors.transparent,
        elevation: 0,
        onPressed: () {
          // Add refresh functionality here
          controller.refreshAccounts();
        },
        
    ),
    );
  }
}

// Modern background painter with animated gradients
class ModernBackgroundPainter extends CustomPainter {
  final double animationValue;

  ModernBackgroundPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    // Animated gradient background
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF0A0B0F),
          Colors.purple.shade900.withOpacity(0.3),
          Colors.blue.shade900.withOpacity(0.2),
          const Color(0xFF0A0B0F),
        ],
        stops: [
          0.0,
          0.3 + sin(animationValue) * 0.1,
          0.7 + cos(animationValue) * 0.1,
          1.0,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Floating geometric shapes
    final shapePaint = Paint()
      ..color = Colors.blue.shade300.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Animated circle
    canvas.drawCircle(
      Offset(
        size.width * 0.8 + sin(animationValue * 2) * 50,
        size.height * 0.2 + cos(animationValue) * 30,
      ),
      80 + sin(animationValue * 3) * 20,
      shapePaint..color = Colors.purple.shade300.withOpacity(0.1),
    );

    // Animated polygon
    final path = Path();
    final center = Offset(
      size.width * 0.2 + cos(animationValue) * 40,
      size.height * 0.7 + sin(animationValue * 1.5) * 60,
    );
    final radius = 60.0;
    final sides = 6;

    for (int i = 0; i < sides; i++) {
      final angle = (i * 2 * pi / sides) + animationValue;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(
      path,
      shapePaint..color = Colors.cyan.shade300.withOpacity(0.08),
    );
  }

  @override
  bool shouldRepaint(ModernBackgroundPainter oldDelegate) =>
      animationValue != oldDelegate.animationValue;
}

// Modern account card with glassmorphism and advanced animations
class ModernAccountCard extends StatefulWidget {
  final Account account;
  final int index;

  const ModernAccountCard({
    super.key,
    required this.account,
    required this.index,
  });

  @override
  _ModernAccountCardState createState() => _ModernAccountCardState();
}

class _ModernAccountCardState extends State<ModernAccountCard>
    with TickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween(begin: 0.0, end: 2 * pi).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnimation, _rotationAnimation]),
        builder: (context, child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            transform: Matrix4.identity()
              ..scale(_isHovered ? 1.05 : 1.0)
              ..rotateZ(_isHovered ? 0.02 : 0.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _isHovered
                    ? [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.1),
                        Colors.blue.shade400.withOpacity(0.1),
                      ]
                    : [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                        Colors.transparent,
                      ],
              ),
              border: Border.all(
                color: _isHovered
                    ? Colors.blue.shade300.withOpacity(0.5)
                    : Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isHovered
                      ? Colors.blue.withOpacity(0.3)
                      : Colors.black.withOpacity(0.1),
                  blurRadius: _isHovered ? 25 : 10,
                  spreadRadius: _isHovered ? 5 : 0,
                  offset: const Offset(0, 8),
                ),
                if (_isHovered)
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: -5,
                    offset: const Offset(0, 20),
                  ),
              ],
            ),
            child: Stack(
              children: [
                // Animated background effects
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: CustomPaint(
                      painter: CardBackgroundPainter(
                        animationValue: _rotationAnimation.value,
                        isHovered: _isHovered,
                      ),
                    ),
                  ),
                ),

                // Main card content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Company logo with modern styling
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.blue.shade400.withOpacity(0.8),
                                Colors.purple.shade400.withOpacity(0.6),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.7, 1.0],
                            ),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 15,
                                spreadRadius: _isHovered ? 5 : 2,
                              ),
                            ],
                          ),
                          child: Transform.scale(
                            scale: _isHovered ? _pulseAnimation.value : 1.0,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.1),
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/logo1.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.business,
                                      size: 75,
                                      color: Colors.white.withOpacity(0.8),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Account name with gradient text
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.1),
                                Colors.white.withOpacity(0.05),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                Colors.white,
                                Colors.blue.shade200,
                              ],
                            ).createShader(bounds),
                            child: Text(
                              widget.account.name ?? 'حساب غير محدد',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Status indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          
                          
                        ),
                      ],
                    ),
                  ),
                ),

                // Clickable overlay with ripple effect
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(28),
                      splashColor: Colors.blue.withOpacity(0.3),
                      highlightColor: Colors.purple.withOpacity(0.2),
                      onTap: () {
                        if (Get.currentRoute != '/accountDetails') {
                          // Add haptic feedback
                          HapticFeedback.lightImpact();

                          Get.put(
                            AccountClientInfo(currentAccount: widget.account),
                          );
                          final p = Get.put(ProfitController());
                          p.updateTheProfitByAccount(widget.account);
                          Get.to(
                            AccountDetails(),
                            arguments: widget.account,
                            transition: Transition.fadeIn,
                            duration: const Duration(milliseconds: 400),
                          );
                        }
                      },
                    ),
                  ),
                ),

                // Floating action indicator
                if (_isHovered)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade400,
                            Colors.purple.shade400,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Custom painter for card background effects
class CardBackgroundPainter extends CustomPainter {
  final double animationValue;
  final bool isHovered;

  CardBackgroundPainter({
    required this.animationValue,
    required this.isHovered,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isHovered) return;

    // Animated gradient waves
    final paint = Paint()..style = PaintingStyle.fill;

    // Wave 1
    final path1 = Path();
    path1.moveTo(0, size.height * 0.3);
    for (double i = 0; i <= size.width; i++) {
      path1.lineTo(
        i,
        size.height * 0.3 +
            sin((i / size.width * 2 * pi) + animationValue * 2) * 20,
      );
    }
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();

    paint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.blue.shade400.withOpacity(0.1),
        Colors.transparent,
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path1, paint);

    // Wave 2
    final path2 = Path();
    path2.moveTo(0, size.height * 0.7);
    for (double i = 0; i <= size.width; i++) {
      path2.lineTo(
        i,
        size.height * 0.7 +
            cos((i / size.width * 2 * pi) + animationValue * 3) * 15,
      );
    }
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();

    paint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.purple.shade400.withOpacity(0.08),
        Colors.transparent,
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path2, paint);

    // Floating particles
    final particlePaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 8; i++) {
      final x = (size.width / 8) * i + sin(animationValue + i) * 10;
      final y = size.height * 0.8 + cos(animationValue * 2 + i) * 20;
      final radius = 2 + sin(animationValue * 3 + i) * 1;

      particlePaint.color = [
        Colors.blue.shade300,
        Colors.purple.shade300,
        Colors.cyan.shade300,
      ][i % 3]
          .withOpacity(0.3);

      canvas.drawCircle(Offset(x, y), radius, particlePaint);
    }
  }

  bool shouldRepaint(CardBackgroundPainter oldDelegate) =>
      animationValue != oldDelegate.animationValue ||
      isHovered != oldDelegate.isHovered;
}
