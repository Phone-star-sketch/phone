import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'package:phone_system_app/views/pages/auth_raper.dart';
import 'package:phone_system_app/views/pages/login_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _meshController;
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late AnimationController _orbController;

  late Animation<double> _fadeIn;
  late Animation<double> _slideUp;
  late Animation<double> _scaleIn;

  final List<FloatingOrb> _orbs = [];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _generateOrbs();
  }

  void _initAnimations() {
    // Main entrance animation
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Mesh gradient rotation
    _meshController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    // Floating animation for elements
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    // Pulse animation for glow effects
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    // Orb movement
    _orbController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideUp = Tween<double>(begin: 60.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _scaleIn = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _mainController.forward();
  }

  void _generateOrbs() {
    final random = math.Random();
    for (int i = 0; i < 6; i++) {
      _orbs.add(FloatingOrb(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: random.nextDouble() * 150 + 80,
        speed: random.nextDouble() * 0.5 + 0.3,
        color: _getOrbColor(i),
      ));
    }
  }

  Color _getOrbColor(int index) {
    final colors = [
      const Color(0xFF667eea),
      const Color(0xFF764ba2),
      const Color(0xFF00d4ff),
      const Color(0xFFf093fb),
      const Color(0xFF4facfe),
      const Color(0xFF43e97b),
    ];
    return colors[index % colors.length];
  }

  @override
  void dispose() {
    _mainController.dispose();
    _meshController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    _orbController.dispose();
    super.dispose();
  }

  void _navigateToAuth() async {
    await _mainController.reverse();
    Get.off(() => const AuthRaper());
  }

  void _navigateToLogin() async {
    await _mainController.reverse();
    Get.off(() => const LoginPage());
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          _buildImageBackground(),

          // Dark Overlay
          _buildDarkOverlay(),

          // Floating Orbs (subtle)
          ..._buildFloatingOrbs(size),

          // Main Content
          _buildMainContent(size, isDark),
        ],
      ),
    );
  }

  Widget _buildImageBackground() {
    return Positioned.fill(
      child: Image.asset(
        'assets/images/bg-logo.png',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to gradient if image not found
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0a0a0f),
                  Color(0xFF1a1a2e),
                  Color(0xFF16213e),
                  Color(0xFF0f0f23),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDarkOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.4),
              Colors.black.withValues(alpha: 0.7),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFloatingOrbs(Size size) {
    return _orbs.asMap().entries.map((entry) {
      final index = entry.key;
      final orb = entry.value;

      return AnimatedBuilder(
        animation: _orbController,
        builder: (context, child) {
          final progress = (_orbController.value + orb.speed) % 1.0;
          final xOffset = math.sin(progress * 2 * math.pi + index) * 30;
          final yOffset = math.cos(progress * 2 * math.pi + index * 0.5) * 40;

          return Positioned(
            left: orb.x * size.width + xOffset - orb.size / 2,
            top: orb.y * size.height + yOffset - orb.size / 2,
            child: Container(
              width: orb.size,
              height: orb.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    orb.color.withValues(alpha: 0.4),
                    orb.color.withValues(alpha: 0.1),
                    orb.color.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(),
              ),
            ),
          );
        },
      );
    }).toList();
  }

  Widget _buildMainContent(Size size, bool isDark) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: _mainController,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeIn.value,
            child: Transform.translate(
              offset: Offset(0, _slideUp.value),
              child: Transform.scale(
                scale: _scaleIn.value,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),

                      // Logo Section
                      _buildLogoSection(isDark),

                      const SizedBox(height: 48),

                      // Welcome Text
                      _buildWelcomeText(isDark),

                      const Spacer(flex: 2),

                      // Action Buttons
                      _buildActionButtons(isDark),

                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogoSection(bool isDark) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        final floatOffset = math.sin(_floatController.value * math.pi) * 8;

        return Transform.translate(
          offset: Offset(0, floatOffset),
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final glowIntensity = 0.3 + (_pulseController.value * 0.2);

              return Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667eea)
                          .withValues(alpha: glowIntensity),
                      blurRadius: 60,
                      spreadRadius: 10,
                    ),
                    BoxShadow(
                      color: const Color(0xFF764ba2)
                          .withValues(alpha: glowIntensity * 0.5),
                      blurRadius: 80,
                      spreadRadius: 20,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/bg-logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: ShaderMask(
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                  colors: [
                                    Color(0xFF667eea),
                                    Color(0xFF764ba2)
                                  ],
                                ).createShader(bounds),
                                child: const Icon(
                                  Icons.phone_android_rounded,
                                  size: 70,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildWelcomeText(bool isDark) {
    return Column(
      children: [
        // Main Title with Gradient
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
              Color(0xFFf093fb),
            ],
          ).createShader(bounds),
          child: const Text(
            'مرحباً بك',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 2,
              height: 1.2,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Subtitle
        const Text(
          'نظام إدارة الهواتف المتطور',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),

        const SizedBox(height: 24),

        // Feature Pills
        _buildFeaturePills(isDark),
      ],
    );
  }

  Widget _buildFeaturePills(bool isDark) {
    final features = ['سريع', 'آمن', 'سهل الاستخدام'];

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: features.map((feature) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withValues(alpha: 0.15),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                feature,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Column(
      children: [
        // Primary Button - Glass Effect
        _buildPrimaryButton(isDark),

        const SizedBox(height: 16),

        // Secondary Button
        _buildSecondaryButton(isDark),
      ],
    );
  }

  Widget _buildPrimaryButton(bool isDark) {
    return GestureDetector(
      onTap: _navigateToAuth,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final glowIntensity = 0.4 + (_pulseController.value * 0.2);

          return Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      const Color(0xFF667eea).withValues(alpha: glowIntensity),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                  spreadRadius: -5,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'ابدأ رحلتك',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(width: 12),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSecondaryButton(bool isDark) {
    return GestureDetector(
      onTap: _navigateToLogin,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white.withValues(alpha: 0.15),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: const Center(
              child: Text(
                'لديك حساب؟ سجل دخول',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Floating Orb Model
class FloatingOrb {
  final double x;
  final double y;
  final double size;
  final double speed;
  final Color color;

  FloatingOrb({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.color,
  });
}
