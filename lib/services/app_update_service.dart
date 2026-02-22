import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service للتحقق من التحديثات المتاحة
class AppUpdateService {
  // ✅ GitHub API URL للتحقق من التحديثات
  static const String githubApiUrl =
      'https://api.github.com/repos/Phone-star-sketch/phone/releases/latest';

  /// التحقق من وجود تحديث جديد
  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      // 1. Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // 2. Fetch latest version from GitHub
      final response = await http.get(Uri.parse(githubApiUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final latestVersion = data['tag_name']?.replaceAll('v', '') ?? '';
        final downloadUrl = _getApkDownloadUrl(data);
        final releaseNotes = data['body'] ?? '';

        // 3. Compare versions
        if (_isNewerVersion(currentVersion, latestVersion)) {
          return UpdateInfo(
            currentVersion: currentVersion,
            latestVersion: latestVersion,
            downloadUrl: downloadUrl,
            releaseNotes: releaseNotes,
          );
        }
      }

      return null;
    } catch (e) {
      print('Error checking for updates: $e');
      return null;
    }
  }

  /// عرض dialog التحديث
  static void showUpdateDialog(BuildContext context, UpdateInfo updateInfo) {
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false, // منع الإغلاق
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF3b82f6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.system_update,
                  color: Color(0xFF3b82f6),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'تحديث متاح',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Version info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الإصدار الحالي',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          updateInfo.currentVersion,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.arrow_forward, color: Color(0xFF3b82f6)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'الإصدار الجديد',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          updateInfo.latestVersion,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10b981),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Release notes
              if (updateInfo.releaseNotes.isNotEmpty) ...[
                Text(
                  'ما الجديد:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: SingleChildScrollView(
                    child: Text(
                      updateInfo.releaseNotes,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Warning
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'سيتم تنزيل التحديث وتثبيته تلقائياً',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                'لاحقاً',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Get.back();
                await _downloadAndInstall(updateInfo.downloadUrl);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3b82f6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.download, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'تحديث الآن',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// تنزيل وتثبيت التحديث
  static Future<void> _downloadAndInstall(String downloadUrl) async {
    try {
      // Show loading
      Get.dialog(
        WillPopScope(
          onWillPop: () async => false,
          child: const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: Color(0xFF3b82f6),
                    ),
                    SizedBox(height: 16),
                    Text('جاري تنزيل التحديث...'),
                  ],
                ),
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // Launch download URL
      final uri = Uri.parse(downloadUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        // Close loading
        Get.back();

        // Show success message
        Get.showSnackbar(const GetSnackBar(
          message: 'جاري تنزيل التحديث... سيتم التثبيت تلقائياً',
          duration: Duration(seconds: 3),
          backgroundColor: Color(0xFF10b981),
          borderRadius: 10,
          margin: EdgeInsets.all(12),
        ));
      } else {
        // Close loading
        Get.back();

        // Show error
        Get.showSnackbar(const GetSnackBar(
          message: 'فشل فتح رابط التحديث',
          duration: Duration(seconds: 3),
          backgroundColor: Color(0xFFef4444),
          borderRadius: 10,
          margin: EdgeInsets.all(12),
        ));
      }
    } catch (e) {
      // Close loading if still open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      // Show error
      Get.showSnackbar(GetSnackBar(
        message: 'حدث خطأ أثناء التحديث: ${e.toString()}',
        duration: const Duration(seconds: 3),
        backgroundColor: const Color(0xFFef4444),
        borderRadius: 10,
        margin: const EdgeInsets.all(12),
      ));
    }
  }

  /// استخراج رابط الـ APK من الـ release
  static String _getApkDownloadUrl(Map<String, dynamic> releaseData) {
    try {
      final assets = releaseData['assets'] as List;
      for (var asset in assets) {
        final name = asset['name'] as String;
        if (name.endsWith('.apk')) {
          return asset['browser_download_url'] as String;
        }
      }
    } catch (e) {
      print('Error extracting APK URL: $e');
    }
    return '';
  }

  /// مقارنة الإصدارات
  static bool _isNewerVersion(String current, String latest) {
    try {
      final currentParts = current.split('.').map(int.parse).toList();
      final latestParts = latest.split('.').map(int.parse).toList();

      for (int i = 0; i < 3; i++) {
        final currentPart = i < currentParts.length ? currentParts[i] : 0;
        final latestPart = i < latestParts.length ? latestParts[i] : 0;

        if (latestPart > currentPart) return true;
        if (latestPart < currentPart) return false;
      }

      return false;
    } catch (e) {
      print('Error comparing versions: $e');
      return false;
    }
  }
}

/// معلومات التحديث
class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String downloadUrl;
  final String releaseNotes;

  UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.downloadUrl,
    required this.releaseNotes,
  });
}
