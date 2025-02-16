import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/models/profit.dart';
import 'package:lottie/lottie.dart';
import 'package:phone_system_app/services/pdf_service.dart';
import 'package:phone_system_app/controllers/account_profit_controller.dart';

class ProfitDetailsDialog extends StatelessWidget {
  final MonthlyProfit profit;
  final String monthName;
  final profitController = Get.find<ProfitController>();

  ProfitDetailsDialog({
    Key? key,
    required this.profit,
    required this.monthName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width:
            MediaQuery.of(context).size.width * 0.9, // Changed from fixed 500
        height: MediaQuery.of(context).size.height * 0.8, // Changed from 0.7
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[700]!, Colors.blue[500]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "حسابات الربح",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ).animate().fadeIn().scale(),
                        Text(
                          "لشهر $monthName",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                          ),
                        ).animate().fadeIn().moveY(begin: 10, delay: 200.ms),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: ListView(
                  children: [
                    _buildProfitCard(
                      "حساب الشركة قبل الخصم",
                      profit.totalIncome,
                      Icons.account_balance,
                      Colors.blue[700]!,
                      0,
                    ),
                    _buildProfitCard(
                      "المبلغ المتوقع جمعه",
                      profitController.calculateTotalDues(),
                      Icons.trending_up,
                      Colors.green[600]!,
                      200,
                    ),
                    _buildProfitCard(
                      "حساب الفاتورة بعد الخصم",
                      profit.totalIncome - profit.totalIncome * profit.discount,
                      Icons.receipt_long,
                      Colors.orange[700]!,
                      400,
                    ),
                    _buildProfitCard(
                      "صافي الربح الشهري",
                      profit.expectedToBeCollected -
                          (profit.totalIncome -
                              profit.totalIncome * profit.discount),
                      Icons.savings,
                      Colors.purple[700]!,
                      600,
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () =>
                        PdfService.generateProfitReport(profit, monthName),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text(
                      "تصدير PDF",
                      style: TextStyle(fontSize: 18),
                    ),
                  ).animate().fadeIn().scale(delay: 800.ms),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () => Get.back(),
                    child: const Text(
                      "تم",
                      style: TextStyle(fontSize: 18),
                    ),
                  ).animate().fadeIn().scale(delay: 800.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfitCard(
      String title, double value, IconData icon, Color color, int delay) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shadowColor: color.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.1),
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${value.toStringAsFixed(2)} ج.م",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn()
        .slideX(begin: 0.2)
        .shimmer(duration: 1200.ms, color: color.withOpacity(0.3));
  }
}
