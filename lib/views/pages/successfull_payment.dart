import 'package:flutter/material.dart';

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
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _scaleController.forward();

    await Future.delayed(const Duration(milliseconds: 200));
    _checkmarkController.forward();

    await Future.delayed(const Duration(milliseconds: 100));
    _fadeController.forward();
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
                      child: const Text(
                        'Payment Successful!',
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
                        'Your payment has been processed successfully',
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
                                'Amount', widget.amount ?? '\$99.99'),
                            const SizedBox(height: 16),
                            _buildDetailRow('Transaction ID',
                                widget.transactionId ?? 'TXN123456789'),
                            const SizedBox(height: 16),
                            _buildDetailRow('Payment Method',
                                widget.paymentMethod ?? 'Credit Card'),
                            const SizedBox(height: 16),
                            _buildDetailRow('Date', _formatDate()),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Action Buttons
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Continue Shopping',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () {
                          // Add receipt/download functionality
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Download Receipt',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
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

  String _formatDate() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year} at ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
  }
}
