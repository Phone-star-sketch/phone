import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/models/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';

class UserManagementController extends GetxController {
  final RxList<AppUser> users = <AppUser>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final ImagePicker _picker = ImagePicker();

  final _supabase = Supabase.instance.client;

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    try {
      isLoading.value = true;
      error.value = '';

      final response = await _supabase.from('users').select();

      if (response.isEmpty) {
        error.value = 'No data returned from server';
        return;
      }

      var usersList = (response as List)
          .where((user) => user != null)
          .map((user) => AppUser.fromJson(user))
          .toList();

      // Sort: Owners first, then by name
      usersList.sort((a, b) {
        if (a.role == 1 && b.role != 1) return -1;
        if (a.role != 1 && b.role == 1) return 1;
        return (a.name ?? '').compareTo(b.name ?? '');
      });

      users.value = usersList;
    } catch (e) {
      _handleError('Error fetching users', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<String?> uploadUserImage(String userId) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return null;

      final bytes = await image.readAsBytes();
      final fileExt = image.path.split('.').last;
      final fileName =
          'user_${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'user_avatars/$fileName';

      await _supabase.storage.from('images').uploadBinary(filePath, bytes);

      return _supabase.storage.from('images').getPublicUrl(filePath);
    } catch (e) {
      _showToast("حدث خطأ أثناء رفع الصورة", isError: true);
      return null;
    }
  }

  Future<void> updateUserAvatar(String uid, String avatarUrl) async {
    await _updateUser(
      uid: uid,
      data: {'avatar_url': avatarUrl},
      successMessage: "تم تحديث الصورة بنجاح",
      errorMessage: "حدث خطأ أثناء تحديث الصورة",
    );
  }

  Future<void> updateUserName(String uid, String newName) async {
    await _updateUser(
      uid: uid,
      data: {'name': newName},
      successMessage: "تم تحديث الاسم بنجاح",
      errorMessage: "حدث خطأ أثناء تحديث الاسم",
    );
  }

  Future<void> updateUserPassword(String uid, String newPassword) async {
    try {
      isLoading.value = true;

      await _supabase.auth.admin.updateUserById(
        uid,
        attributes: AdminUserAttributes(password: newPassword),
      );

      _showToast("تم تحديث كلمة المرور بنجاح");
    } catch (e) {
      _handleError("حدث خطأ أثناء تحديث كلمة المرور", e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateUserSecpass(String uid, int newSecpass) async {
    await _updateUser(
      uid: uid,
      data: {'secpass': newSecpass},
      successMessage: "تم تحديث كلمة المرور الثانية بنجاح",
      errorMessage: "حدث خطأ أثناء تحديث كلمة المرور الثانية",
    );
  }

  Future<void> updateUserRole(String uid, int newRole) async {
    await _updateUser(
      uid: uid,
      data: {'role': newRole},
      successMessage: "تم تحديث الصلاحية بنجاح",
      errorMessage: "حدث خطأ أثناء تحديث الصلاحية",
    );
  }

  Future<void> createUser(
    String email,
    String password,
    String name,
    int role,
    int secpass,
  ) async {
    try {
      isLoading.value = true;

      // Step 1: Create auth user with metadata
      // The trigger will automatically create the public.users entry
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'role': role,
          'secpass': secpass,
        },
      );

      if (authResponse.user == null) {
        throw Exception('فشل إنشاء حساب المستخدم');
      }

      // Step 2: Wait a moment for trigger to complete
      await Future.delayed(const Duration(milliseconds: 300));

      // Step 3: Refresh the list
      await fetchUsers();

      _showToast("تم إنشاء المستخدم بنجاح");
    } on AuthException catch (e) {
      _handleAuthException(e);
      rethrow;
    } catch (e) {
      _handleError("حدث خطأ أثناء إنشاء المستخدم", e);
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteUser(String uid) async {
    try {
      isLoading.value = true;

      // Step 1: Delete from public.users first
      await _supabase.from('users').delete().eq('uid', uid);

      // Step 2: Delete from auth.users
      // Note: This requires admin privileges, which we don't have with anon key
      // So we'll just delete from public.users and let the admin manually clean up auth.users
      // Or we can use a database trigger to handle this

      // Remove from local list
      users.removeWhere((user) => user.uid == uid);

      _showToast("تم حذف المستخدم بنجاح");
    } catch (e) {
      await fetchUsers(); // Refresh to ensure consistency
      _handleError("حدث خطأ أثناء حذف المستخدم", e);
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  // Private helper methods
  Future<void> _updateUser({
    required String uid,
    required Map<String, dynamic> data,
    required String successMessage,
    required String errorMessage,
  }) async {
    try {
      isLoading.value = true;
      await _supabase.from('users').update(data).eq('uid', uid);
      await fetchUsers();
      _showToast(successMessage);
    } catch (e) {
      _handleError(errorMessage, e);
    } finally {
      isLoading.value = false;
    }
  }

  void _handleError(String message, dynamic err) {
    // Log error for debugging
    if (err != null) {
      debugPrint('$message: $err');
    }
    error.value = err?.toString() ?? message;
    _showToast(message, isError: true);
  }

  void _handleAuthException(AuthException e) {
    String errorMessage = 'حدث خطأ أثناء إنشاء المستخدم';

    if (e.message.contains('already registered') ||
        e.message.contains('already exists') ||
        e.statusCode == '422') {
      errorMessage =
          'هذا البريد الإلكتروني مستخدم بالفعل. الرجاء استخدام بريد آخر.';
    } else if (e.message.contains('Invalid email')) {
      errorMessage = 'البريد الإلكتروني غير صحيح';
    } else if (e.message.contains('Password')) {
      errorMessage = 'كلمة المرور ضعيفة جداً';
    } else {
      errorMessage = 'خطأ: ${e.message}';
    }

    error.value = errorMessage;
    _showToast(errorMessage, isError: true);
  }

  void _showToast(String message, {bool isError = false}) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: isError ? Colors.red : Colors.green,
      textColor: Colors.white,
      toastLength: Toast.LENGTH_LONG,
    );
  }
}
