import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'package:phone_system_app/views/pages/auth_raper.dart';
import 'package:phone_system_app/views/pages/login_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _backgroundController;
  late AnimationController _floatingController;
  late AnimationController _morphController;
  late AnimationController _sparkleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _morphAnimation;
  late Animation<double> _sparkleAnimation;
  final List<FloatingOrb> _orbs = [];
  final List<SparkleParticle> _sparkles = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateOrbs();
    _generateSparkles();
  }

  void _initializeAnimations() {
    _controller = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this);

    _backgroundController =
        AnimationController(duration: const Duration(seconds: 15), vsync: this)
          ..repeat();

    _floatingController =
        AnimationController(duration: const Duration(seconds: 3), vsync: this)
          ..repeat(reverse: true);

    _morphController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.8),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack),
    ));

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.7, curve: Curves.elasticOut),
      ),
    );

    _morphAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _morphController, curve: Curves.easeInOut),
    );

    _sparkleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.easeInOut),
    );

    _controller.forward();
  }

  void _generateOrbs() {
    final random = math.Random();
    for (int i = 0; i < 4; i++) {
      // Reduced from 8 to 4
      _orbs.add(FloatingOrb(random));
    }
  }

  void _generateSparkles() {
    final random = math.Random();
    for (int i = 0; i < 6; i++) {
      // Reduced from 15 to 6
      _sparkles.add(SparkleParticle(random));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _backgroundController.dispose();
    _floatingController.dispose();
    _morphController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge(
            [_backgroundController, _morphController, _sparkleController]),
        builder: (context, child) {
          return Stack(
            children: [
              // Dynamic gradient background
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF667eea),
                      Color(0xFF764ba2),
                      Color(0xFF6B73FF),
                      Color(0xFF000DFF),
                    ],
                    stops: [
                      0.0,
                      _morphAnimation.value * 0.5,
                      0.7 + _morphAnimation.value * 0.2,
                      1.0,
                    ],
                    transform: GradientRotation(
                        _backgroundController.value * 2 * math.pi * 0.3),
                  ),
                ),
              ),

              // Mesh gradient overlay
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(
                      math.sin(_morphAnimation.value * 2 * math.pi) * 0.3,
                      math.cos(_morphAnimation.value * 2 * math.pi) * 0.3,
                    ),
                    radius: 1.5,
                    colors: [
                      Colors.cyan.withValues(alpha: 0.1),
                      Colors.purple.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              // Floating orbs
              ..._orbs.asMap().entries.map((entry) {
                final i = entry.key;
                final orb = entry.value;
                final progress =
                    (_backgroundController.value + orb.offset) % 1.0;
                final float = math.sin((progress + i * 0.3) * 2 * math.pi) * 20;

                return Positioned(
                  left: orb.x * size.width +
                      math.sin(progress * 2 * math.pi + i) * 50,
                  top: orb.y * size.height + float,
                  child: Transform.scale(
                    scale: 0.5 + math.sin(progress * math.pi) * 0.5,
                    child: Container(
                      width: orb.size,
                      height: orb.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            orb.color.withValues(alpha: 0.3),
                            orb.color.withValues(alpha: 0.1),
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: orb.color.withValues(alpha: 0.2),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),

              // Sparkle particles
              ..._sparkles.map((sparkle) {
                final progress =
                    (_sparkleAnimation.value + sparkle.offset) % 1.0;
                final opacity = math.sin(progress * math.pi);

                return Positioned(
                  left: sparkle.x * size.width,
                  top: sparkle.y * size.height,
                  child: Transform.rotate(
                    angle: progress * 4 * math.pi,
                    child: Opacity(
                      opacity: opacity * 0.8,
                      child: Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: sparkle.size,
                      ),
                    ),
                  ),
                );
              }).toList(),

              // Main content
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Floating logo with glassmorphism
                      AnimatedBuilder(
                        animation: _floatingController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(
                                0,
                                15 *
                                    math.sin(
                                        _floatingController.value * math.pi)),
                            child: ScaleTransition(
                              scale: _scaleAnimation,
                              child: Container(
                                height: 180,
                                width: 180,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withValues(alpha: 0.2),
                                      Colors.white.withValues(alpha: 0.1),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 30,
                                      spreadRadius: 5,
                                    ),
                                    BoxShadow(
                                      color:
                                          Colors.white.withValues(alpha: 0.1),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                      offset: const Offset(-5, -5),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.smartphone,
                                  size: 90,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 60),

                      // Title with premium typography
                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: [
                                    Colors.white,
                                    Colors.white70,
                                    Colors.white,
                                  ],
                                  stops: [0.0, 0.5, 1.0],
                                ).createShader(bounds),
                                child: Text(
                                  'مرحباً بك',
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -1,
                                    shadows: [
                                      Shadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'نظام إدارة الهواتف المتطور',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  color: Colors.white.withValues(alpha: 0.85),
                                  letterSpacing: 0.5,
                                  fontWeight: FontWeight.w300,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 80),

                      // Premium buttons
                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            children: [
                              _buildPremiumButton(
                                'ابدأ رحلتك',
                                primary: true,
                                onPressed: () {
                                  _controller.reverse().then((_) {
                                    Get.off(() => AuthRaper());
                                  });
                                },
                              ),
                              const SizedBox(height: 24),
                              _buildPremiumButton(
                                'لديك حساب؟ سجل دخول',
                                primary: false,
                                onPressed: () {
                                  _controller.reverse().then((_) {
                                    Get.off(() => const LoginPage());
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPremiumButton(String text,
      {required bool primary, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 65,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: primary
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(35),
              side: BorderSide(
                color: Colors.white.withValues(alpha: primary ? 0.4 : 0.2),
                width: primary ? 2 : 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
          ).copyWith(
            overlayColor: WidgetStateProperty.all(
              Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Container(
            decoration: primary
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(35),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.1),
                        Colors.white.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  )
                : null,
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: primary ? 20 : 16,
                  fontWeight: primary ? FontWeight.bold : FontWeight.w500,
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

class FloatingOrb {
  final double x;
  final double y;
  final double size;
  final double offset;
  final Color color;

  FloatingOrb(math.Random random)
      : x = random.nextDouble(),
        y = random.nextDouble(),
        size = random.nextDouble() * 80 + 40,
        offset = random.nextDouble(),
        color = [
          Colors.cyan,
          Colors.purple,
          Colors.pink,
          Colors.blue,
          Colors.indigo,
        ][random.nextInt(5)];
}

class SparkleParticle {
  final double x;
  final double y;
  final double size;
  final double offset;

  SparkleParticle(math.Random random)
      : x = random.nextDouble(),
        y = random.nextDouble(),
        size = random.nextDouble() * 16 + 8,
        offset = random.nextDouble();
}
