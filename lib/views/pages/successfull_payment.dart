import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/views/pages/all_clinets_page.dart';

class SuccessfulPaymentPage extends StatefulWidget {
  final String? amount;
  final String? transactionId;
  final String? paymentMethod;

  const SuccessfulPaymentPage({
    Key? key,
    this.amount,
    this.transactionId,
    this.paymentMethod,
  }) : super(key: key);

  @override
  State<SuccessfulPaymentPage> createState() => _SuccessfulPaymentPageState();
}

class _SuccessfulPaymentPageState extends State<SuccessfulPaymentPage>
    with TickerProviderStateMixin {
  late AnimationController _checkmarkController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;

  late Animation<double> _checkmarkAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _checkmarkController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _checkmarkAnimation = CurvedAnimation(
      parent: _checkmarkController,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.bounceOut,
    );

    _startAnimations();
    _startNavigationTimer();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _scaleController.forward();

    await Future.delayed(const Duration(milliseconds: 200));
    _checkmarkController.forward();

    await Future.delayed(const Duration(milliseconds: 100));
    _fadeController.forward();
  }

  void _startNavigationTimer() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Get.off(() => const AllClientsPage());
      }
    });
  }

  @override
  void dispose() {
    _checkmarkController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Success Icon with Animation
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 20,
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
                                size: 60,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Success Title
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        'تم الدفع بنجاح!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Success Subtitle
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        'تمت معالجة عملية الدفع الخاصة بك بنجاح',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Payment Details Card
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow(
                                'المبلغ', widget.amount ?? '٩٩.٩٩ ج.م'),
                            const SizedBox(height: 16),
                            _buildDetailRow('رقم المعاملة',
                                widget.transactionId ?? 'TXN123456789'),
                            const SizedBox(height: 16),
                            _buildDetailRow('طريقة الدفع',
                                widget.paymentMethod ?? 'بطاقة ائتمان'),
                            const SizedBox(height: 16),
                            _buildDetailRow('التاريخ', _formatDate()),
                          ],
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

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
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
