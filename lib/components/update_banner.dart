import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/components/update_dialog.dart';
import 'package:phone_system_app/controllers/update_controller.dart';

/// Banner يظهر في أعلى الشاشة عند وجود تحديث
class UpdateBanner extends StatelessWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final updateController = Get.find<UpdateController>();

    return Obx(() {
      // إخفاء البانر إذا لم يكن هناك تحديث
      if (!updateController.isUpdateAvailable.value) {
        return const SizedBox.shrink();
      }

      return Material(
        elevation: 4,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade600,
                Colors.blue.shade400,
              ],
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.system_update,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'تحديث جديد متاح',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'اضغط للتحديث الآن',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _showUpdateDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue.shade600,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'تحديث',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const UpdateDialog(),
    );
  }
}

/// Floating Action Button للتحديث (يظهر في الزاوية)
class UpdateFloatingButton extends StatelessWidget {
  const UpdateFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    final updateController = Get.find<UpdateController>();

    return Obx(() {
      // إخفاء الزر إذا لم يكن هناك تحديث
      if (!updateController.isUpdateAvailable.value) {
        return const SizedBox.shrink();
      }

      return FloatingActionButton.extended(
        onPressed: () => _showUpdateDialog(context),
        backgroundColor: Colors.blue.shade600,
        icon: const Icon(Icons.system_update, color: Colors.white),
        label: const Text(
          'تحديث متاح',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    });
  }

  void _showUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const UpdateDialog(),
    );
  }
}
