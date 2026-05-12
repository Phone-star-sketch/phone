import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/services/shorebird_update_service.dart';

/// Dialog لعرض إشعار التحديث للمستخدم
class UpdateDialog extends StatefulWidget {
  const UpdateDialog({super.key});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Icon(
            Icons.system_update,
            color: Theme.of(context).primaryColor,
            size: 30,
          ),
          const SizedBox(width: 10),
          const Text(
            'تحديث متاح',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'يوجد تحديث جديد للتطبيق يحتوي على تحسينات وإصلاحات.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 15),
          const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text('حجم صغير (1-5 MB)'),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.speed, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text('تحديث سريع'),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.restart_alt, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text('يتطلب إعادة تشغيل التطبيق'),
            ],
          ),
          if (_isDownloading) ...[
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: _downloadProgress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                'جاري التحميل... ${(_downloadProgress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (!_isDownloading) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'لاحقاً',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _downloadAndRestart,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(
                horizontal: 30,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'تحديث الآن',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _downloadAndRestart() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      // محاكاة التقدم (لأن Shorebird لا يوفر progress callback)
      _simulateProgress();

      // تحميل التحديث
      final success = await ShorebirdUpdateService().downloadUpdate();

      if (success) {
        setState(() {
          _downloadProgress = 1.0;
        });

        // انتظر قليلاً لعرض اكتمال التحميل
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.of(context).pop(true);

          // عرض رسالة نجاح
          Get.snackbar(
            'تم التحديث',
            'سيتم تطبيق التحديث عند إعادة تشغيل التطبيق',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
            icon: const Icon(Icons.check_circle, color: Colors.white),
          );

          // اقتراح إعادة التشغيل
          _showRestartDialog();
        }
      } else {
        if (mounted) {
          Navigator.of(context).pop(false);
          Get.snackbar(
            'خطأ',
            'فشل تحميل التحديث. حاول مرة أخرى.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(false);
        Get.snackbar(
          'خطأ',
          'حدث خطأ أثناء التحديث: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  void _simulateProgress() {
    // محاكاة التقدم لتحسين تجربة المستخدم
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _isDownloading) {
        setState(() => _downloadProgress = 0.3);
      }
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted && _isDownloading) {
        setState(() => _downloadProgress = 0.6);
      }
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && _isDownloading) {
        setState(() => _downloadProgress = 0.9);
      }
    });
  }

  void _showRestartDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.restart_alt, color: Colors.orange, size: 30),
            SizedBox(width: 10),
            Text('إعادة تشغيل التطبيق'),
          ],
        ),
        content: const Text(
          'تم تحميل التحديث بنجاح. هل تريد إعادة تشغيل التطبيق الآن لتطبيق التحديث؟',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'لاحقاً',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // إغلاق التطبيق (المستخدم سيعيد فتحه)
              // في Flutter، لا يمكن إعادة التشغيل برمجياً بشكل آمن
              // لذلك نطلب من المستخدم إغلاق وإعادة فتح التطبيق
              Get.back();
              Get.snackbar(
                'تنبيه',
                'الرجاء إغلاق التطبيق وإعادة فتحه لتطبيق التحديث',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.orange,
                colorText: Colors.white,
                duration: const Duration(seconds: 5),
                icon: const Icon(Icons.info, color: Colors.white),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(
                horizontal: 30,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'حسناً',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}

/// عرض dialog التحديث إذا كان متاحاً
Future<void> showUpdateDialogIfAvailable(BuildContext context) async {
  final updateService = ShorebirdUpdateService();

  // تحقق من وجود تحديث
  final isUpdateAvailable = await updateService.checkForUpdate();

  if (isUpdateAvailable && context.mounted) {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const UpdateDialog(),
    );
  }
}
