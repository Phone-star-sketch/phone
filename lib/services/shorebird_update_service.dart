import 'package:flutter/foundation.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

class ShorebirdUpdateService {
  static final ShorebirdCodePush _shorebirdCodePush = ShorebirdCodePush();

  /// التحقق من وجود تحديث متاح
  static Future<bool> checkForUpdate() async {
    if (kIsWeb) return false; // Shorebird لا يعمل على Web

    try {
      final isUpdateAvailable =
          await _shorebirdCodePush.isNewPatchAvailableForDownload();
      return isUpdateAvailable;
    } catch (e) {
      if (kDebugMode) {
        print('Shorebird check failed: $e');
      }
      return false;
    }
  }

  /// الحصول على رقم الإصدار الحالي
  static Future<String?> getCurrentPatchNumber() async {
    if (kIsWeb) return null;

    try {
      final patchNumber = await _shorebirdCodePush.currentPatchNumber();
      return patchNumber?.toString();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get patch number: $e');
      }
      return null;
    }
  }
}
