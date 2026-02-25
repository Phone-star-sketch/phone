import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/models/client.dart';

/// Shows the success payment overlay as a GetX dialog.
/// Using Get.dialog instead of Get.to() avoids all navigation-stack
/// conflicts when the user performs multiple consecutive payments.
void showSuccessfulPayment({
  required String amount,
  required String transactionId,
  required String paymentMethod,
  Client? client,
}) {
  // Guard: don't stack duplicates
  if (Get.isDialogOpen ?? false) Get.back();

  Get.dialog(
    _SuccessDialog(
      amount: amount,
      transactionId: transactionId,
      paymentMethod: paymentMethod,
    ),
    barrierDismissible: true,
    barrierColor: Colors.black54,
    useSafeArea: false,
  );
}

// ─────────────────────────────────────────────
// Internal dialog widget
// ─────────────────────────────────────────────

class _SuccessDialog extends StatefulWidget {
  final String amount;
  final String transactionId;
  final String paymentMethod;

  const _SuccessDialog({
    required this.amount,
    required this.transactionId,
    required this.paymentMethod,
  });

  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  late final Animation<double> _checkmark;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _scale = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
    );

    _checkmark = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.3, 0.8, curve: Curves.elasticOut),
    );

    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );

    _ctrl.forward();

    // Auto-close: wait for animation + a brief reading moment
    Future.delayed(const Duration(milliseconds: 2200), _close);
  }

  void _close() {
    if (!mounted) return;
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────

  String _formatDate() {
    final now = DateTime.now();
    final months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];
    String toAr(int n) {
      const e = ['0','1','2','3','4','5','6','7','8','9'];
      const a = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];
      return n.toString().split('').map((c) {
        final i = e.indexOf(c);
        return i >= 0 ? a[i] : c;
      }).join();
    }
    return '${toAr(now.day)} ${months[now.month - 1]} ${toAr(now.year)}'
        '  ${toAr(now.hour)}:${toAr(now.minute)}';
  }

  // ── Build ─────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: _close,
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF667eea), Color(0xFF764ba2), Color(0xFFf093fb)],
            ),
          ),
          child: Stack(
            children: [
              // Floating particles (lightweight – random but seeded)
              ..._particles(),

              // Main content
              SafeArea(
                child: Column(
                  children: [
                    // Close button
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: FadeTransition(
                          opacity: _fade,
                          child: GestureDetector(
                            onTap: _close,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.3)),
                              ),
                              child: const Icon(Icons.close_rounded,
                                  color: Colors.white, size: 22),
                            ),
                          ),
                        ),
                      ),
                    ),

                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // ── Check circle ──
                              ScaleTransition(
                                scale: _scale,
                                child: Container(
                                  width: 130,
                                  height: 130,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF11998e),
                                        Color(0xFF38ef7d)
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF38ef7d)
                                            .withOpacity(0.45),
                                        blurRadius: 28,
                                        spreadRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: AnimatedBuilder(
                                    animation: _checkmark,
                                    builder: (_, __) => Transform.scale(
                                      scale: _checkmark.value,
                                      child: const Icon(Icons.check_rounded,
                                          color: Colors.white, size: 68),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 32),

                              // ── Title ──
                              FadeTransition(
                                opacity: _fade,
                                child: const Text(
                                  '🎉 تم الدفع بنجاح!',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                              const SizedBox(height: 8),

                              FadeTransition(
                                opacity: _fade,
                                child: Text(
                                  'تمت معالجة عملية الدفع بنجاح',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.white.withOpacity(0.85),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                              const SizedBox(height: 36),

                              // ── Details card ──
                              FadeTransition(
                                opacity: _fade,
                                child: Container(
                                  width: double.infinity,
                                  constraints:
                                      const BoxConstraints(maxWidth: 480),
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.14),
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                        width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 24,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      _row(Icons.payments_rounded, 'المبلغ',
                                          widget.amount,
                                          big: true),
                                      _divider(),
                                      _row(Icons.receipt_long_rounded,
                                          'رقم المعاملة', widget.transactionId),
                                      _divider(),
                                      _row(Icons.credit_card_rounded,
                                          'طريقة الدفع', widget.paymentMethod),
                                      _divider(),
                                      _row(Icons.access_time_rounded,
                                          'التاريخ', _formatDate()),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 36),

                              // ── Back button ──
                              FadeTransition(
                                opacity: _fade,
                                child: GestureDetector(
                                  onTap: _close,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 36, vertical: 14),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [
                                        Color(0xFF11998e),
                                        Color(0xFF38ef7d)
                                      ]),
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF38ef7d)
                                              .withOpacity(0.4),
                                          blurRadius: 18,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.arrow_back_rounded,
                                            color: Colors.white, size: 20),
                                        SizedBox(width: 10),
                                        Text(
                                          'العودة للحسابات',
                                          style: TextStyle(
                                            fontSize: 15,
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
      ),
    );
  }

  // ── Sub-widgets ───────────────────────────────

  Widget _row(IconData icon, String label, String value,
      {bool big = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.65))),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: big ? 19 : 14,
                    fontWeight:
                        big ? FontWeight.bold : FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        height: 1,
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            Colors.transparent,
            Colors.white.withOpacity(0.25),
            Colors.transparent,
          ]),
        ),
      );

  List<Widget> _particles() {
    return List.generate(16, (i) {
      final rng = math.Random(i * 7);
      final size = rng.nextDouble() * 7 + 3.0;
      return Positioned(
        left: rng.nextDouble() * 420,
        top: rng.nextDouble() * 820,
        child: IgnorePointer(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 2200 + rng.nextInt(1800)),
            builder: (_, v, __) => Transform.translate(
              offset: Offset(math.sin(v * math.pi * 2) * 18, v * 90),
              child: Opacity(
                opacity: (1 - v) * 0.5,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}