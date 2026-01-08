import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'package:phone_system_app/views/pages/auth_raper.dart';
import 'package:phone_system_app/views/pages/login_page.dart';
import 'package:audioplayers/audioplayers.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _entryController;
  late AnimationController _bounceController;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();

    _waveController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _entryController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveController.dispose();
    _entryController.dispose();
    _bounceController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/button_click.wav'));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      body: Stack(
        children: [
          // Animated Gradient Waves
          _buildAnimatedWaves(),

          // Grid Pattern
          _buildGridPattern(),

          // Main Content
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildAnimatedWaves() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return CustomPaint(
          painter: WavePainter(
            animation: _waveController.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildGridPattern() {
    return Opacity(
      opacity: 0.03,
      child: CustomPaint(
        painter: GridPainter(),
        size: Size.infinite,
      ),
    );
  }

  Widget _buildContent() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            const Spacer(),

            // Animated Logo
            _buildLogo(),

            const SizedBox(height: 60),

            // Title Section
            _buildTitle(),

            const SizedBox(height: 16),

            // Subtitle
            _buildSubtitle(),

            const Spacer(),

            // Buttons
            _buildButtons(),

            const SizedBox(height: 40),

            // Bottom Indicator
            _buildBottomIndicator(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _entryController,
      builder: (context, child) {
        final scale = Curves.elasticOut.transform(_entryController.value);

        return Transform.scale(
          scale: scale,
          child: AnimatedBuilder(
            animation: _bounceController,
            builder: (context, child) {
              final bounce = math.sin(_bounceController.value * math.pi) * 6;

              return Transform.translate(
                offset: Offset(0, bounce),
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFff6b6b),
                        Color(0xFFfeca57),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFff6b6b).withValues(alpha: 0.5),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Inner glow
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      // Icon
                      const Icon(
                        Icons.smartphone_rounded,
                        size: 60,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTitle() {
    return AnimatedBuilder(
      animation: _entryController,
      builder: (context, child) {
        final opacity = Curves.easeOut.transform(
          (_entryController.value - 0.3).clamp(0.0, 1.0) / 0.7,
        );
        final slide = (1 - opacity) * 30;

        return Transform.translate(
          offset: Offset(0, slide),
          child: Opacity(
            opacity: opacity,
            child: const Column(
              children: [
                Text(
                  'مرحباً بك',
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubtitle() {
    return AnimatedBuilder(
      animation: _entryController,
      builder: (context, child) {
        final opacity = Curves.easeOut.transform(
          (_entryController.value - 0.4).clamp(0.0, 1.0) / 0.6,
        );

        return Opacity(
          opacity: opacity,
          child: Text(
            'نظام إدارة الهواتف المتطور',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.6),
              letterSpacing: 1,
            ),
          ),
        );
      },
    );
  }

  Widget _buildButtons() {
    return AnimatedBuilder(
      animation: _entryController,
      builder: (context, child) {
        final opacity = Curves.easeOut.transform(
          (_entryController.value - 0.5).clamp(0.0, 1.0) / 0.5,
        );
        final slide = (1 - opacity) * 40;

        return Transform.translate(
          offset: Offset(0, slide),
          child: Opacity(
            opacity: opacity,
            child: Column(
              children: [
                // Primary Button
                GestureDetector(
                  onTap: () async {
                    await _playSound();
                    await _entryController.reverse();
                    Get.off(() => AuthRaper());
                  },
                  child: Container(
                    width: double.infinity,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFff6b6b), Color(0xFFfeca57)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFff6b6b).withValues(alpha: 0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'ابدأ رحلتك',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Secondary Button
                GestureDetector(
                  onTap: () async {
                    await _playSound();
                    await _entryController.reverse();
                    Get.off(() => const LoginPage());
                  },
                  child: Container(
                    width: double.infinity,
                    height: 58,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'لديك حساب؟ سجل دخول',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomIndicator() {
    return AnimatedBuilder(
      animation: _bounceController,
      builder: (context, child) {
        final opacity = 0.3 + (_bounceController.value * 0.4);

        return Container(
          width: 40,
          height: 5,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: Colors.white.withValues(alpha: opacity),
          ),
        );
      },
    );
  }
}

// Wave Painter for animated background
class WavePainter extends CustomPainter {
  final double animation;

  WavePainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // First wave - Orange/Red
    paint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFFff6b6b).withValues(alpha: 0.3),
        const Color(0xFFff6b6b).withValues(alpha: 0.0),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path1 = Path();
    path1.moveTo(0, size.height * 0.7);

    for (double i = 0; i <= size.width; i++) {
      final y = size.height * 0.7 +
          math.sin((i / size.width * 2 * math.pi) + (animation * 2 * math.pi)) *
              40 +
          math.sin((i / size.width * 4 * math.pi) +
                  (animation * 2 * math.pi * 1.5)) *
              20;
      path1.lineTo(i, y);
    }

    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();

    canvas.drawPath(path1, paint);

    // Second wave - Yellow
    paint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFFfeca57).withValues(alpha: 0.2),
        const Color(0xFFfeca57).withValues(alpha: 0.0),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path2 = Path();
    path2.moveTo(0, size.height * 0.75);

    for (double i = 0; i <= size.width; i++) {
      final y = size.height * 0.75 +
          math.sin((i / size.width * 2 * math.pi) +
                  (animation * 2 * math.pi) +
                  1) *
              30 +
          math.cos((i / size.width * 3 * math.pi) +
                  (animation * 2 * math.pi * 0.8)) *
              15;
      path2.lineTo(i, y);
    }

    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();

    canvas.drawPath(path2, paint);

    // Top gradient glow
    paint.shader = RadialGradient(
      center: const Alignment(0.5, -0.3),
      radius: 1.2,
      colors: [
        const Color(0xFFff6b6b).withValues(alpha: 0.15),
        const Color(0xFFff6b6b).withValues(alpha: 0.0),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.5), paint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) =>
      animation != oldDelegate.animation;
}

// Grid Pattern Painter
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1;

    const spacing = 30.0;

    // Vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) => false;
}
