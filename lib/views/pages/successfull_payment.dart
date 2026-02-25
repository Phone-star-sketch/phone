import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/models/client.dart';
import 'dart:ui';

/// Shows a success payment modal popup (not a full-screen page).
void showSuccessfulPayment({
  required String amount,
  required String transactionId,
  required String paymentMethod,
  Client? client,
}) {
  if (Get.isDialogOpen ?? false) Get.back();

  Get.dialog(
    _SuccessModal(
      amount: amount,
      transactionId: transactionId,
      paymentMethod: paymentMethod,
    ),
    barrierDismissible: true,
    barrierColor: Colors.black54,
  );
}

class _SuccessModal extends StatefulWidget {
  final String amount;
  final String transactionId;
  final String paymentMethod;

  const _SuccessModal({
    required this.amount,
    required this.transactionId,
    required this.paymentMethod,
  });

  @override
  State<_SuccessModal> createState() => _SuccessModalState();
}

class _SuccessModalState extends State<_SuccessModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  late final Animation<double> _checkmark;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 800),
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

    Future.delayed(const Duration(seconds: 1), _close);
  }

  void _close() {
    if (!mounted) return;
    if (Get.isDialogOpen ?? false) Get.back();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _formatDate() {
    final now = DateTime.now();
    const months = [
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

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Center(
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            constraints: const BoxConstraints(maxWidth: 420),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF764ba2).withOpacity(0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Close button
                    Align(
                      alignment: Alignment.topLeft,
                      child: FadeTransition(
                        opacity: _fade,
                        child: GestureDetector(
                          onTap: _close,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Check circle
                    AnimatedBuilder(
                      animation: _checkmark,
                      builder: (_, __) => Transform.scale(
                        scale: _checkmark.value,
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF38ef7d).withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.check_rounded,
                              color: Colors.white, size: 48),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    FadeTransition(
                      opacity: _fade,
                      child: const Text(
                        '🎉 تم الدفع بنجاح!',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          decoration: TextDecoration.none,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 6),
                    FadeTransition(
                      opacity: _fade,
                      child: Text(
                        'تمت معالجة عملية الدفع بنجاح',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.8),
                          decoration: TextDecoration.none,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Details card
                    FadeTransition(
                      opacity: _fade,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.18),
                          ),
                        ),
                        child: Column(
                          children: [
                            _row(Icons.payments_rounded, 'المبلغ',
                                widget.amount, big: true),
                            _divider(),
                            _row(Icons.receipt_long_rounded, 'رقم المعاملة',
                                widget.transactionId),
                            _divider(),
                            _row(Icons.credit_card_rounded, 'طريقة الدفع',
                                widget.paymentMethod),
                            _divider(),
                            _row(Icons.access_time_rounded, 'التاريخ',
                                _formatDate()),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Close button
                    FadeTransition(
                      opacity: _fade,
                      child: SizedBox(
                        width: double.infinity,
                        child: GestureDetector(
                          onTap: _close,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF38ef7d).withOpacity(0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Text(
                              'تم ✓',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value, {bool big = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.6),
                      decoration: TextDecoration.none,
                    )),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: big ? 17 : 13,
                    fontWeight: big ? FontWeight.bold : FontWeight.w600,
                    color: Colors.white,
                    decoration: TextDecoration.none,
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
            Colors.white.withOpacity(0.2),
            Colors.transparent,
          ]),
        ),
      );
}
