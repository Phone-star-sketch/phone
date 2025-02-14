import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'package:phone_system_app/views/pages/auth_raper.dart';
import 'package:phone_system_app/views/pages/login_page.dart';
import 'package:audioplayers/audioplayers.dart';

class WelcomePage extends StatefulWidget {
  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _backgroundController;
  late AnimationController _floatingController;
  late AnimationController _supermanController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _supermanSlideAnimation;
  late Animation<double> _supermanScaleAnimation;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<Particle> _particles = [];
  bool _showSuperman = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateParticles();
  }

  void _initializeAnimations() {
    _controller = AnimationController(
        duration: Duration(milliseconds: 1500), vsync: this);

    _backgroundController =
        AnimationController(duration: Duration(seconds: 10), vsync: this)
          ..repeat();

    _floatingController =
        AnimationController(duration: Duration(seconds: 2), vsync: this)
          ..repeat(reverse: true);

    _supermanController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.3, 0.8, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _supermanSlideAnimation = Tween<Offset>(
      begin: Offset(-1, 0.5), // Updated start position
      end: Offset(1.5, -0.5), // Updated end position
    ).animate(CurvedAnimation(
      parent: _supermanController,
      curve: Curves.easeInOut,
    ));

    _supermanScaleAnimation = Tween<double>(
      begin: 1.2, // Increased starting scale
      end: 0.2, // Updated end scale
    ).animate(CurvedAnimation(
      parent: _supermanController,
      curve: Curves.easeIn,
    ));

    _controller.forward();
  }

  void _generateParticles() {
    final random = math.Random();
    for (int i = 0; i < 20; i++) {
      _particles.add(Particle(random));
    }
  }

  void _startSupermanAnimation() async {
    setState(() => _showSuperman = true);
    await _supermanController.forward();
    setState(() => _showSuperman = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    _backgroundController.dispose();
    _floatingController.dispose();
    _supermanController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playButtonSound() async {
    await _audioPlayer.play(AssetSource('sounds/button_click.wav'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundController,
        builder: (context, child) {
          return Stack(
            children: [
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF87CEEB), // Light sky blue
                      Color(0xFF00BFFF), // Deep sky blue
                      Color(0xFF1E90FF), // Dodger blue
                    ],
                    transform: GradientRotation(
                        _backgroundController.value * 2 * math.pi),
                  ),
                ),
                child: Stack(
                  children: [
                    ..._particles.map((particle) {
                      final progress =
                          (_backgroundController.value + particle.offset) % 1.0;
                      return Positioned(
                        left: particle.x * MediaQuery.of(context).size.width,
                        top: particle.y * MediaQuery.of(context).size.height,
                        child: Transform.scale(
                          scale: progress,
                          child: Opacity(
                            opacity: 1 - progress,
                            child: Container(
                              width: particle.size,
                              height: particle.size,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _floatingController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(
                                0,
                                10 *
                                    math.sin(
                                        _floatingController.value * math.pi)),
                            child: ScaleTransition(
                              scale: _scaleAnimation,
                              child: Container(
                                height: 150,
                                width: 150,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.5)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.2),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.phone_android,
                                  size: 80,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 48),
                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            children: [
                              Text(
                                'مرحباً بك',
                                style: TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      blurRadius: 10,
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'نظام إدارة الهواتف',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 24,
                                  color: Colors.white.withOpacity(0.9),
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 48),
                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            children: [
                              _buildGlassButton(
                                'ابدأ الآن',
                                onPressed: () async {
                                  await _playButtonSound();
                                  _startSupermanAnimation();
                                  _controller.reverse().then((_) {
                                    Get.off(() => AuthRaper());
                                  });
                                },
                              ),
                              SizedBox(height: 24),
                              _buildTextButton(
                                'لديك حساب بالفعل؟ سجل دخول',
                                onPressed: () async {
                                  await _playButtonSound();
                                  _controller.reverse().then((_) {
                                    Get.off(() => LoginPage());
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
              if (_showSuperman)
                AnimatedBuilder(
                  animation: _supermanController,
                  builder: (context, child) {
                    final size = MediaQuery.of(context).size;
                    return Positioned(
                      left: size.width * 0.5 - 150, // Center horizontally
                      top: size.height * 0.4, // Position from top
                      child: Transform.translate(
                        offset:
                            _supermanSlideAnimation.value * size.width * 0.5,
                        child: Transform.scale(
                          scale: _supermanScaleAnimation.value,
                          child: Opacity(
                            opacity: 1 - (_supermanController.value * 0.7),
                            child: Image.asset(
                              'assets/images/logo.png', // Correct asset path
                              width: 150,
                              height: 150,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                print('Error loading image: $error');
                                return Container(
                                  width: 300,
                                  height: 300,
                                  child: Icon(
                                    Icons
                                        .rocket_launch, // Changed to a rocket icon as fallback
                                    color: Colors.white,
                                    size: 80,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGlassButton(String text, {required VoidCallback onPressed}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: Colors.white.withOpacity(0.2),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextButton(String text, {required VoidCallback onPressed}) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontSize: 16,
          decoration: TextDecoration.underline,
          decorationColor: Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }
}

class Particle {
  final double x;
  final double y;
  final double size;
  final double offset;

  Particle(math.Random random)
      : x = random.nextDouble(),
        y = random.nextDouble(),
        size = random.nextDouble() * 4 + 2,
        offset = random.nextDouble();
}
