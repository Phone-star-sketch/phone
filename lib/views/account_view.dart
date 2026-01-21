import 'dart:math' as math;
import 'dart:ui';
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

class AccountsView extends StatefulWidget {
  const AccountsView({super.key});

  @override
  State<AccountsView> createState() => _AccountsViewState();
}

class _AccountsViewState extends State<AccountsView>
    with TickerProviderStateMixin {
  final controller = Get.put(AccountViewController());
  late AnimationController _waveController;
  late AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _entryController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      body: Stack(
        children: [
          // Animated Background
          _buildAnimatedBackground(),

          // Grid Pattern
          _buildGridPattern(),

          // Main Content
          SafeArea(
            child: Obx(() {
              final data = controller.getCurrentAccounts();
              final isLoading = controller.isLoading.value;

              return Column(
                children: [
                  // App Bar
                  _buildAppBar(),

                  // Content
                  Expanded(
                    child:
                        isLoading ? _buildLoader() : _buildAccountsList(data),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return CustomPaint(
          painter: _WavePainter(animation: _waveController.value),
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

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Charts Button
          _buildIconButton(
            icon: FontAwesomeIcons.chartPie,
            onTap: () =>
                Get.to(const ChartsPage(), transition: Transition.leftToRight),
          ),

          const Spacer(),

          // Title
          AnimatedBuilder(
            animation: _entryController,
            builder: (context, child) {
              final opacity = _entryController.value;
              return Opacity(
                opacity: opacity,
                child: const Text(
                  'اختر الحساب',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),

          const Spacer(),

          // Table Button
          _buildIconButton(
            icon: Icons.table_chart_rounded,
            onTap: () => Get.to(const InfoTablePage(),
                transition: Transition.rightToLeft),
          ),

          const SizedBox(width: 12),

          // Logout Button
          _buildIconButton(
            icon: Icons.logout_rounded,
            color: const Color(0xFFff6b6b),
            onTap: () => _showLogoutDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withValues(alpha: 0.08),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Icon(
          icon,
          color: color ?? Colors.white.withValues(alpha: 0.8),
          size: 20,
        ),
      ),
    );
  }

  Widget _buildLoader() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
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
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'جاري التحميل...',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsList(List<Account> accounts) {
    return AnimatedBuilder(
      animation: _entryController,
      builder: (context, child) {
        final opacity = _entryController.value;
        final slide = (1 - opacity) * 50;

        return Transform.translate(
          offset: Offset(0, slide),
          child: Opacity(
            opacity: opacity,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: List.generate(accounts.length, (index) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: index < accounts.length - 1 ? 20 : 0,
                      ),
                      child: _AccountCard(
                        account: accounts[index],
                        index: index,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: const Text(
          'تسجيل الخروج',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'هل أنت متأكد من تسجيل الخروج؟',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
          ),
          GestureDetector(
            onTap: () async {
              Navigator.pop(context);
              await BackendServices.instance.supabaseAuthentication.signOut();
              html.window.location.reload();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Color(0xFFff6b6b), Color(0xFFfeca57)],
                ),
              ),
              child: const Text(
                'خروج',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Account Card Widget
class _AccountCard extends StatefulWidget {
  final Account account;
  final int index;

  const _AccountCard({
    required this.account,
    required this.index,
  });

  @override
  State<_AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends State<_AccountCard> {
  bool _isHovered = false;

  // Get unique background image for each account
  String _getBackgroundImage() {
    // Use account index to alternate between the two images
    final images = [
      'assets/images/bgaccounts.jpg', // Using existing image for testing
      'assets/images/bgaccounts2.png', // Using existing image for testing
    ];
    return images[widget.index % images.length];
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: _navigateToAccount,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          transform: Matrix4.identity()
            ..translate(0.0, _isHovered ? -8.0 : 0.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: _isHovered
                  ? const Color(0xFFff6b6b).withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.15),
              width: 2,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: const Color(0xFFff6b6b).withValues(alpha: 0.3),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                    BoxShadow(
                      color: const Color(0xFFfeca57).withValues(alpha: 0.2),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background Image from Assets
                Image.asset(
                  _getBackgroundImage(),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    // Debug: print error
                    debugPrint('Error loading image: $error');
                    return Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFff6b6b), Color(0xFFfeca57)],
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    );
                  },
                ),

                // Blur Overlay
                BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: _isHovered ? 1 : 1,
                    sigmaY: _isHovered ? 1 : 1,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ),

                // Gradient Overlay for better text visibility
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _isHovered
                          ? [
                              const Color(0xFFff6b6b).withValues(alpha: 0.2),
                              const Color(0xFFfeca57).withValues(alpha: 0.2),
                            ]
                          : [
                              Colors.transparent,
                              Colors.transparent,
                            ],
                    ),
                  ),
                ),

                // Content
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Company Name
                        Text(
                          widget.account.name ?? 'حساب غير محدد',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: _isHovered ? 42 : 38,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontFamily: 'Cairo',
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.6),
                                blurRadius: 25,
                                offset: const Offset(0, 4),
                              ),
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Status Badge
                        // AnimatedContainer(
                        //   duration: const Duration(milliseconds: 300),
                        //   padding: EdgeInsets.symmetric(
                        //     horizontal: _isHovered ? 32 : 28,
                        //     vertical: _isHovered ? 14 : 12,
                        //   ),
                        //   // decoration: BoxDecoration(
                        //   //   borderRadius: BorderRadius.circular(30),
                        //   //   gradient: const LinearGradient(
                        //   //     colors: [Color(0xFF10b981), Color(0xFF059669)],
                        //   //   ),
                        //   //   boxShadow: [
                        //   //     BoxShadow(
                        //   //       color: const Color(0xFF10b981)
                        //   //           .withValues(alpha: 0.5),
                        //   //       blurRadius: _isHovered ? 25 : 15,
                        //   //       offset: const Offset(0, 8),
                        //   //     ),
                        //   //   ],
                        //   // ),
                        //   // child: Text(
                        //   //   'نشط',
                        //   //   style: TextStyle(
                        //   //     fontSize: _isHovered ? 18 : 16,
                        //   //     fontWeight: FontWeight.w700,
                        //   //     color: Colors.white,
                        //   //     fontFamily: 'Cairo',
                        //   //     shadows: [
                        //   //       Shadow(
                        //   //         color: Colors.black.withValues(alpha: 0.3),
                        //   //         blurRadius: 8,
                        //   //       ),
                        //   //     ],
                        //   //   ),
                        //   // ),
                        // ),
                      ],
                    ),
                  ),
                ),

                // Hover Indicator (subtle corner accent)
                if (_isHovered)
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFff6b6b), Color(0xFFfeca57)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFff6b6b).withValues(alpha: 0.6),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToAccount() {
    HapticFeedback.lightImpact();

    // Delete old controllers if they exist
    if (Get.isRegistered<AccountClientInfo>()) {
      Get.delete<AccountClientInfo>(force: true);
    }
    if (Get.isRegistered<ProfitController>()) {
      Get.delete<ProfitController>(force: true);
    }

    // Create new controllers with the selected account
    Get.put(AccountClientInfo(currentAccount: widget.account));
    final p = Get.put(ProfitController());
    p.updateTheProfitByAccount(widget.account);

    Get.to(
      const AccountDetails(),
      arguments: widget.account,
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 400),
    );
  }
}

// Wave Painter
class _WavePainter extends CustomPainter {
  final double animation;

  _WavePainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Top glow
    paint.shader = RadialGradient(
      center: const Alignment(0.5, -0.5),
      radius: 1.5,
      colors: [
        const Color(0xFFff6b6b).withValues(alpha: 0.12),
        const Color(0xFFff6b6b).withValues(alpha: 0.0),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.5), paint);

    // Bottom wave
    paint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFFfeca57).withValues(alpha: 0.08),
        const Color(0xFFfeca57).withValues(alpha: 0.0),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    path.moveTo(0, size.height * 0.8);

    for (double i = 0; i <= size.width; i++) {
      final y = size.height * 0.8 +
          math.sin((i / size.width * 2 * math.pi) + (animation * 2 * math.pi)) *
              30;
      path.lineTo(i, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) =>
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
