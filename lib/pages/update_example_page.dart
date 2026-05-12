import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/components/update_banner.dart';
import 'package:phone_system_app/components/update_dialog.dart';
import 'package:phone_system_app/controllers/update_controller.dart';

/// مثال على كيفية استخدام نظام التحديثات في أي صفحة
///
/// يمكنك نسخ هذا الكود في أي صفحة تريد عرض إشعار التحديث فيها
class UpdateExamplePage extends StatefulWidget {
  const UpdateExamplePage({super.key});

  @override
  State<UpdateExamplePage> createState() => _UpdateExamplePageState();
}

class _UpdateExamplePageState extends State<UpdateExamplePage> {
  final UpdateController _updateController = Get.find<UpdateController>();

  @override
  void initState() {
    super.initState();
    // فحص التحديثات عند فتح الصفحة
    _checkForUpdatesOnPageLoad();
  }

  /// فحص التحديثات وعرض dialog تلقائياً
  Future<void> _checkForUpdatesOnPageLoad() async {
    // انتظر قليلاً حتى تظهر الصفحة
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // فحص التحديثات
    final hasUpdate = await _updateController.checkForUpdate();

    if (hasUpdate && mounted) {
      // عرض dialog التحديث
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const UpdateDialog(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مثال على التحديثات'),
        actions: [
          // زر يدوي للتحقق من التحديثات
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _manualCheckForUpdates,
            tooltip: 'التحقق من التحديثات',
          ),
        ],
      ),
      body: Column(
        children: [
          // ✅ البانر يظهر تلقائياً عند وجود تحديث
          const UpdateBanner(),

          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // معلومات التحديث الحالي
                    _buildUpdateInfo(),

                    const SizedBox(height: 40),

                    // أزرار التحكم
                    _buildControlButtons(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // ✅ زر عائم يظهر عند وجود تحديث
      floatingActionButton: const UpdateFloatingButton(),
    );
  }

  Widget _buildUpdateInfo() {
    return Obx(() {
      return Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(
                Icons.info_outline,
                size: 48,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              Text(
                'معلومات التحديث',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                'حالة Shorebird',
                _updateController.isShorebirdAvailable.value
                    ? 'متاح ✅'
                    : 'غير متاح ❌',
              ),
              _buildInfoRow(
                'تحديث متاح',
                _updateController.isUpdateAvailable.value ? 'نعم 🔄' : 'لا ✅',
              ),
              _buildInfoRow(
                'الإصدار الحالي',
                _updateController.getUpdateInfo(),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Obx(() {
      return Column(
        children: [
          // زر التحقق من التحديثات
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _updateController.isCheckingForUpdate.value
                  ? null
                  : _manualCheckForUpdates,
              icon: _updateController.isCheckingForUpdate.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh),
              label: Text(
                _updateController.isCheckingForUpdate.value
                    ? 'جاري الفحص...'
                    : 'التحقق من التحديثات',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // زر التحديث (يظهر فقط عند وجود تحديث)
          if (_updateController.isUpdateAvailable.value)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showUpdateDialog(),
                icon: const Icon(Icons.system_update),
                label: const Text('تحديث الآن'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      );
    });
  }

  /// فحص يدوي للتحديثات
  Future<void> _manualCheckForUpdates() async {
    final hasUpdate = await _updateController.checkForUpdate();

    if (!mounted) return;

    if (hasUpdate) {
      Get.snackbar(
        'تحديث متاح',
        'يوجد تحديث جديد للتطبيق',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        icon: const Icon(Icons.system_update, color: Colors.white),
      );
    } else {
      Get.snackbar(
        'لا توجد تحديثات',
        'التطبيق محدث لأحدث إصدار',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
    }
  }

  /// عرض dialog التحديث
  void _showUpdateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const UpdateDialog(),
    );
  }
}
