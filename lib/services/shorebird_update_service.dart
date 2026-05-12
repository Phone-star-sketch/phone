import 'package:flutter/foundation.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

/// خدمة إدارة التحديثات عبر Shorebird
///
/// توفر هذه الخدمة:
/// - فحص وجود تحديثات جديدة
/// - تحميل التحديثات
/// - الحصول على معلومات التحديث الحالي
class ShorebirdUpdateService {
  static final ShorebirdUpdateService _instance =
      ShorebirdUpdateService._internal();
  factory ShorebirdUpdateService() => _instance;
  ShorebirdUpdateService._internal();

  final ShorebirdCodePush _shorebirdCodePush = ShorebirdCodePush();

  /// التحقق من وجود تحديث جديد متاح
  ///
  /// Returns:
  /// - `true` إذا كان هناك تحديث متاح
  /// - `false` إذا لم يكن هناك تحديث أو حدث خطأ
  Future<bool> checkForUpdate() async {
    try {
      // تحقق من أن Shorebird مفعّل
      final isAvailable = await _shorebirdCodePush.isShorebirdAvailable();
      if (!isAvailable) {
        debugPrint(
            '🔄 Shorebird: Not available (probably running in debug mode)');
        return false;
      }

      // تحقق من وجود تحديث
      final isUpdateAvailable =
          await _shorebirdCodePush.isNewPatchAvailableForDownload();

      if (isUpdateAvailable) {
        debugPrint('🔄 Shorebird: Update available!');
      } else {
        debugPrint('🔄 Shorebird: App is up to date');
      }

      return isUpdateAvailable;
    } catch (e) {
      debugPrint('🔄 Shorebird: Error checking for update: $e');
      return false;
    }
  }

  /// تحميل التحديث المتاح
  ///
  /// يجب استدعاء [checkForUpdate] أولاً للتأكد من وجود تحديث
  ///
  /// Returns:
  /// - `true` إذا تم التحميل بنجاح
  /// - `false` إذا فشل التحميل
  Future<bool> downloadUpdate() async {
    try {
      debugPrint('🔄 Shorebird: Starting download...');

      await _shorebirdCodePush.downloadUpdateIfAvailable();

      debugPrint('🔄 Shorebird: Download completed successfully');
      return true;
    } catch (e) {
      debugPrint('🔄 Shorebird: Error downloading update: $e');
      return false;
    }
  }

  /// الحصول على رقم الـ patch الحالي
  ///
  /// Returns:
  /// - رقم الـ patch (مثل: 1, 2, 3...)
  /// - `null` إذا لم يكن هناك patch مطبق
  Future<int?> getCurrentPatchNumber() async {
    try {
      final patchNumber = await _shorebirdCodePush.currentPatchNumber();
      return patchNumber;
    } catch (e) {
      debugPrint('🔄 Shorebird: Error getting patch number: $e');
      return null;
    }
  }

  /// التحقق من أن Shorebird متاح ويعمل
  Future<bool> isShorebirdAvailable() async {
    try {
      return await _shorebirdCodePush.isShorebirdAvailable();
    } catch (e) {
      debugPrint('🔄 Shorebird: Error checking availability: $e');
      return false;
    }
  }

  /// فحص وتحميل التحديث تلقائياً (صامت)
  ///
  /// يستخدم عند بدء التطبيق للتحديث الصامت في الخلفية
  Future<void> checkAndDownloadSilently() async {
    try {
      final isUpdateAvailable = await checkForUpdate();

      if (isUpdateAvailable) {
        debugPrint('🔄 Shorebird: Downloading update silently...');
        await downloadUpdate();
        debugPrint('🔄 Shorebird: Update will be applied on next restart');
      }
    } catch (e) {
      debugPrint('🔄 Shorebird: Error in silent update: $e');
    }
  }
}
