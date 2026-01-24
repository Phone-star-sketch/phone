import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/models/client.dart';
import 'dart:math' as math;

class SuccessfulPaymentPage extends StatefulWidget {
  final String? amount;
  final String? transactionId;
  final String? paymentMethod;
  final Client? client;

  const SuccessfulPaymentPage({
    super.key,
    this.amount,
    this.transactionId,
    this.paymentMethod,
    this.client,
  });

  @override
  State<SuccessfulPaymentPage> createState() => _SuccessfulPaymentPageState();
}

class _SuccessfulPaymentPageState extends State<SuccessfulPaymentPage>
    with TickerProviderStateMixin {
  late AnimationController _checkmarkController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _confettiController;
  late AnimationController _shimmerController;

  late Animation<double> _checkmarkAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _checkmarkController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _checkmarkAnimation = CurvedAnimation(
      parent: _checkmarkController,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    );

    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _scaleController.forward();
    _confettiController.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    _checkmarkController.forward();

    await Future.delayed(const Duration(milliseconds: 200));
    _fadeController.forward();
  }

  void _navigateBack() {
    // Go back to the bottom sheet
    Get.back();
  }

  @override
  void dispose() {
    _checkmarkController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _confettiController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF667eea),
              const Color(0xFF764ba2),
              const Color(0xFFf093fb),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated background particles
            ...List.generate(20, (index) => _buildFloatingParticle(index)),

            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Close button at top
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: GestureDetector(
                            onTap: _navigateBack,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Main content
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Success Icon with Confetti
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                // Confetti effect
                                AnimatedBuilder(
                                  animation: _confettiController,
                                  builder: (context, child) {
                                    return CustomPaint(
                                      size: const Size(200, 200),
                                      painter: ConfettiPainter(
                                          _confettiController.value),
                                    );
                                  },
                                ),

                                // Success circle
                                ScaleTransition(
                                  scale: _scaleAnimation,
                                  child: Container(
                                    width: 140,
                                    height: 140,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFF11998e),
                                          Color(0xFF38ef7d),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF38ef7d)
                                              .withValues(alpha: 0.5),
                                          blurRadius: 30,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: AnimatedBuilder(
                                      animation: _checkmarkAnimation,
                                      builder: (context, child) {
                                        return Transform.scale(
                                          scale: _checkmarkAnimation.value,
                                          child: const Icon(
                                            Icons.check_rounded,
                                            color: Colors.white,
                                            size: 70,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 40),

                            // Success Title with shimmer
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: AnimatedBuilder(
                                animation: _shimmerController,
                                builder: (context, child) {
                                  return ShaderMask(
                                    shaderCallback: (bounds) {
                                      return LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: const [
                                          Colors.white,
                                          Color(0xFFffeaa7),
                                          Colors.white,
                                        ],
                                        stops: [
                                          _shimmerController.value - 0.3,
                                          _shimmerController.value,
                                          _shimmerController.value + 0.3,
                                        ],
                                      ).createShader(bounds);
                                    },
                                    child: const Text(
                                      '🎉 تم الدفع بنجاح!',
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Success Subtitle
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: Text(
                                'تمت معالجة عملية الدفع الخاصة بك بنجاح',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                            const SizedBox(height: 50),

                            // Payment Details Card with glassmorphism
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: Container(
                                width: double.infinity,
                                constraints:
                                    const BoxConstraints(maxWidth: 500),
                                padding: const EdgeInsets.all(28),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 30,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    _buildDetailRow(
                                      icon: Icons.payments_rounded,
                                      label: 'المبلغ',
                                      value: widget.amount ?? '٩٩.٩٩ ج.م',
                                      isHighlighted: true,
                                    ),
                                    const SizedBox(height: 20),
                                    _buildDivider(),
                                    const SizedBox(height: 20),
                                    _buildDetailRow(
                                      icon: Icons.receipt_long_rounded,
                                      label: 'رقم المعاملة',
                                      value: widget.transactionId ??
                                          'TXN123456789',
                                    ),
                                    const SizedBox(height: 20),
                                    _buildDetailRow(
                                      icon: Icons.credit_card_rounded,
                                      label: 'طريقة الدفع',
                                      value: widget.paymentMethod ??
                                          'بطاقة ائتمان',
                                    ),
                                    const SizedBox(height: 20),
                                    _buildDetailRow(
                                      icon: Icons.access_time_rounded,
                                      label: 'التاريخ',
                                      value: _formatDate(),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 40),

                            // Return button
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: GestureDetector(
                                onTap: _navigateBack,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 40,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF11998e),
                                        Color(0xFF38ef7d),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF38ef7d)
                                            .withValues(alpha: 0.4),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.arrow_back_rounded,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'العودة للحسابات',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
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
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingParticle(int index) {
    final random = math.Random(index);
    final size = random.nextDouble() * 8 + 4;
    final duration = random.nextInt(3000) + 2000;
    final delay = random.nextInt(1000);

    return Positioned(
      left: random.nextDouble() * 400,
      top: random.nextDouble() * 800,
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: 1),
        duration: Duration(milliseconds: duration),
        builder: (context, double value, child) {
          return Transform.translate(
            offset: Offset(
              math.sin(value * math.pi * 2) * 20,
              value * 100,
            ),
            child: Opacity(
              opacity: (1 - value) * 0.6,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isHighlighted = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: isHighlighted ? 20 : 15,
                  fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: 0.3),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  String _toArabicNumbers(String englishNumber) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

    String result = englishNumber;
    for (int i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], arabic[i]);
    }
    return result;
  }

  String _getArabicMonth(int month) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];
    return months[month - 1];
  }

  String _formatDate() {
    final now = DateTime.now();
    final day = _toArabicNumbers(now.day.toString());
    final month = _getArabicMonth(now.month);
    final year = _toArabicNumbers(now.year.toString());
    final hour = _toArabicNumbers(now.hour.toString());
    final minute = _toArabicNumbers(now.minute.toString().padLeft(2, '0'));

    return '$day $month $year في $hour:$minute';
  }
}

// Custom painter for confetti effect
class ConfettiPainter extends CustomPainter {
  final double progress;

  ConfettiPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 30; i++) {
      final angle = (i / 30) * math.pi * 2;
      final distance = progress * 100;
      final x = size.width / 2 + math.cos(angle) * distance;
      final y = size.height / 2 + math.sin(angle) * distance + (progress * 50);

      paint.color = [
        const Color(0xFFffeaa7),
        const Color(0xFFff6b6b),
        const Color(0xFF4ecdc4),
        const Color(0xFF45b7d1),
        const Color(0xFFf093fb),
      ][random.nextInt(5)]
          .withValues(alpha: 1 - progress);

      canvas.drawCircle(
        Offset(x, y),
        random.nextDouble() * 4 + 2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) => true;
}
