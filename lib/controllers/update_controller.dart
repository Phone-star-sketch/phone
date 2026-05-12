import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/services/shorebird_update_service.dart';

/// Controller لإدارة حالة التحديثات
class UpdateController extends GetxController {
  final ShorebirdUpdateService _updateService = ShorebirdUpdateService();

  // حالة التحديث
  final RxBool isUpdateAvailable = false.obs;
  final RxBool isCheckingForUpdate = false.obs;
  final RxBool isDownloading = false.obs;
  final RxInt currentPatchNumber = 0.obs;
  final RxBool isShorebirdAvailable = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeShorebird();
  }

  /// تهيئة Shorebird والتحقق من التوفر
  Future<void> _initializeShorebird() async {
    try {
      isShorebirdAvailable.value = await _updateService.isShorebirdAvailable();

      if (isShorebirdAvailable.value) {
        // الحصول على رقم الـ patch الحالي
        final patchNumber = await _updateService.getCurrentPatchNumber();
        if (patchNumber != null) {
          currentPatchNumber.value = patchNumber;
        }

        debugPrint(
            '🔄 Shorebird: Initialized (Patch: ${currentPatchNumber.value})');
      } else {
        debugPrint(
            '🔄 Shorebird: Not available (debug mode or not configured)');
      }
    } catch (e) {
      debugPrint('🔄 Shorebird: Error initializing: $e');
    }
  }

  /// التحقق من وجود تحديث
  Future<bool> checkForUpdate() async {
    if (!isShorebirdAvailable.value) {
      debugPrint('🔄 Shorebird: Cannot check - not available');
      return false;
    }

    try {
      isCheckingForUpdate.value = true;

      final hasUpdate = await _updateService.checkForUpdate();
      isUpdateAvailable.value = hasUpdate;

      return hasUpdate;
    } catch (e) {
      debugPrint('🔄 Shorebird: Error checking for update: $e');
      return false;
    } finally {
      isCheckingForUpdate.value = false;
    }
  }

  /// تحميل التحديث
  Future<bool> downloadUpdate() async {
    if (!isUpdateAvailable.value) {
      debugPrint('🔄 Shorebird: No update available to download');
      return false;
    }

    try {
      isDownloading.value = true;

      final success = await _updateService.downloadUpdate();

      if (success) {
        isUpdateAvailable.value = false; // التحديث تم تحميله
        debugPrint('🔄 Shorebird: Update downloaded successfully');
      }

      return success;
    } catch (e) {
      debugPrint('🔄 Shorebird: Error downloading update: $e');
      return false;
    } finally {
      isDownloading.value = false;
    }
  }

  /// فحص وتحميل التحديث تلقائياً (صامت)
  Future<void> checkAndDownloadSilently() async {
    if (!isShorebirdAvailable.value) return;

    try {
      await _updateService.checkAndDownloadSilently();
    } catch (e) {
      debugPrint('🔄 Shorebird: Error in silent update: $e');
    }
  }

  /// الحصول على معلومات التحديث الحالي
  String getUpdateInfo() {
    if (!isShorebirdAvailable.value) {
      return 'Shorebird غير متاح';
    }

    if (currentPatchNumber.value > 0) {
      return 'Patch رقم: ${currentPatchNumber.value}';
    }

    return 'الإصدار الأساسي (بدون patches)';
  }
}
