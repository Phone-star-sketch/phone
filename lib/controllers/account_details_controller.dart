import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phone_system_app/services/backend/auth.dart';
import 'package:phone_system_app/views/pages/all_clinets_page.dart';
import 'package:phone_system_app/views/pages/dues_management.dart';
import 'package:phone_system_app/views/pages/follow.dart';
import 'package:phone_system_app/views/pages/for_sale_number.dart';
import 'package:phone_system_app/views/pages/offers.dart';
import 'package:phone_system_app/views/pages/profit_management_page.dart';
import 'package:phone_system_app/views/pages/system_list.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PageData {
  final String title;
  final Icon icon;
  final List<UserRoles> roles;
  final Widget? content;

  PageData({
    required this.title,
    required this.icon,
    required this.roles,
    this.content,
  });
}

class AccountDetailsController extends GetxController {
  static AccountDetailsController get to => Get.find();
  final RxInt selectedIndex = 0.obs;

  final Rx<String?> profileImage = Rx<String?>(null);
  final RxList<String> userImages = <String>[].obs;
  var lastBucketImage = ''.obs;

  final List<PageData> pages = [
    PageData(
      title: "بيانات العملاء",
      icon: const Icon(Icons.supervised_user_circle, color: Colors.black54),
      roles: [UserRoles.admin, UserRoles.manager],
    ),
    PageData(
      title: "المستحقات",
      icon: const Icon(Icons.payment, color: Colors.black54),
      roles: [UserRoles.admin, UserRoles.manager, UserRoles.assistant],
    ),
    PageData(
      title: "العروض المطلوبة",
      icon: const Icon(Icons.card_giftcard_rounded, color: Colors.black54),
      roles: [UserRoles.admin, UserRoles.manager],
    ),
    PageData(
      title: "الباقات المتاحة",
      icon: const Icon(Icons.play_lesson, color: Colors.black54),
      roles: [UserRoles.admin, UserRoles.manager],
    ),
    PageData(
      title: "الربح و الاحصاء",
      icon: const Icon(Icons.account_balance_wallet, color: Colors.black54),
      roles: [UserRoles.admin, UserRoles.manager],
    ),
    PageData(
      title: "أرقام للبيع",
      icon: const Icon(Icons.phone_android, color: Colors.black54),
      roles: [UserRoles.admin, UserRoles.manager],
    ),
    PageData(
      title: "المتابعة",
      icon: const Icon(Icons.toc_rounded, color: Colors.black54),
      roles: [UserRoles.admin, UserRoles.manager],
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    loadUserImages();
    fetchLastBucketImage();
  }

  Future<void> loadUserImages() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // List all files with the user's ID prefix
      final List<FileObject> files = await supabase.storage
          .from('images')
          .list(searchOptions: SearchOptions(limit: 100));

      // Filter files that belong to this user (by prefix)
      final userFiles =
          files.where((file) => file.name.startsWith('${userId}_'));

      // Get public URLs for all user images
      userImages.value = userFiles
          .map(
              (file) => supabase.storage.from('images').getPublicUrl(file.name))
          .toList();
    } catch (e) {
      print('Error loading user images: $e');
    }
  }

  Future<void> fetchLastBucketImage() async {
    try {
      final response = await supabase.storage.from('images').list();

      if (response.isNotEmpty) {
        // Sort files by created_at in descending order
        response
            .sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));

        // Get the public URL of the last image
        final String publicUrl =
            supabase.storage.from('images').getPublicUrl(response.first.name);

        lastBucketImage.value = publicUrl;
      }
    } catch (e) {
      print('Error fetching last bucket image: $e');
    }
  }

  Future<String> getLatestImageFromBucket() async {
    try {
      final storage = Supabase.instance.client.storage;
      final List<FileObject> files = await storage
          .from('images')
          .list();
      
      if (files.isEmpty) return '';
      
      // Sort files by created date in descending order
      files.sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
      
      // Get the URL for the most recent file
      final String publicUrl = storage
          .from('images')
          .getPublicUrl(files.first.name);
          
      return publicUrl;
    } catch (e) {
      print('Error fetching image from bucket: $e');
      return '';
    }
  }

  Future<void> uploadNewImage() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        Get.snackbar('خطأ', 'يرجى تسجيل الدخول أولاً',
            snackPosition: SnackPosition.BOTTOM);
        return;
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();

        // Generate unique filename using timestamp
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = '${userId}_$timestamp.jpg';

        await supabase.storage.from('images').uploadBinary(
              fileName,
              bytes,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: true,
              ),
            );

        // Get public URL and add to list
        final imageUrl = supabase.storage.from('images').getPublicUrl(fileName);
        userImages.add(imageUrl);

        Get.snackbar('نجاح', 'تم تحميل الصورة بنجاح',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white);
      }
    } catch (e) {
      print('Error uploading image: $e');
      Get.snackbar('خطأ', 'حدث خطأ في تحميل الصورة',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }
  }

  void handleNavigation(int index) {
    selectedIndex.value = index;
    switch (index) {
      case 0:
        Get.to(() => AllClientsPage());
        break;
      case 1:
        Get.to(() => DuesManagement());
        break;
      case 2:
        Get.to(() => OfferManagement());
        break;
      case 3:
        Get.to(() => SystemList());
        break;
      case 4:
        Get.to(() => ProfitManagement());
        break;
      case 5:
        Get.to(() => ForSaleNumbers());
        break;
      case 6:
        Get.to(() => Follow());
        break;
    }
  }
}
