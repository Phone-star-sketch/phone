import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/models/account.dart';
import 'package:phone_system_app/models/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:phone_system_app/controllers/account_client_info_data.dart';
import 'package:image_picker/image_picker.dart';

// Modern Color Palette
const Color primaryColor = Color(0xFF6366F1);
const Color secondaryColor = Color(0xFF8B5CF6);
const Color accentColor = Color(0xFFEC4899);
const Color backgroundColor = Color(0xFFF8FAFC);
const Color surfaceColor = Color(0xFFFFFFFF);
const Color textPrimary = Color(0xFF1E293B);
const Color textSecondary = Color(0xFF64748B);

// Legacy colors for compatibility
const Color mainColor = primaryColor;
const Color mainColorLight = Color(0x406366F1);
const Color mainColorLighter = Color(0x106366F1);

class UserManagementController extends GetxController {
  final accountInfo =
      Get.put(AccountClientInfo(currentAccount: Account.empty()));
  final RxList<AppUser> users = <AppUser>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final ImagePicker _picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    try {
      isLoading.value = true;
      final response = await Supabase.instance.client.from('users').select();

      if (response.isEmpty) {
        error.value = 'No data returned from server';
        return;
      }

      var usersList = (response as List)
          .where((user) => user != null)
          .map((user) => AppUser.fromJson(user))
          .toList();

      usersList.sort((a, b) {
        if (a.role == 1 && b.role != 1) return -1;
        if (a.role != 1 && b.role == 1) return 1;
        return (a.name ?? '').compareTo(b.name ?? '');
      });

      users.value = usersList;
    } catch (e) {
      print('Error fetching users: $e');
      error.value = e.toString();
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

      await Supabase.instance.client.storage
          .from('images')
          .uploadBinary(filePath, bytes);

      final imageUrl = Supabase.instance.client.storage
          .from('images')
          .getPublicUrl(filePath);

      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      Fluttertoast.showToast(
        msg: "حدث خطأ أثناء رفع الصورة",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return null;
    }
  }

  Future<void> updateUserAvatar(String uid, String avatarUrl) async {
    try {
      isLoading.value = true;
      await Supabase.instance.client
          .from('users')
          .update({'avatar_url': avatarUrl}).eq('uid', uid);
      await fetchUsers();
      Fluttertoast.showToast(
        msg: "تم تحديث الصورة بنجاح",
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      error.value = e.toString();
      Fluttertoast.showToast(
        msg: "حدث خطأ أثناء تحديث الصورة",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateUserName(String uid, String newName) async {
    try {
      isLoading.value = true;
      await Supabase.instance.client
          .from('users')
          .update({'name': newName}).eq('uid', uid);
      await fetchUsers();
      Fluttertoast.showToast(
        msg: "تم تحديث الاسم بنجاح",
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      error.value = e.toString();
      Fluttertoast.showToast(
        msg: "حدث خطأ أثناء تحديث الاسم",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateUserPassword(String uid, String newPassword) async {
    try {
      isLoading.value = true;

      await Supabase.instance.client.auth.admin.updateUserById(
        uid,
        attributes: AdminUserAttributes(password: newPassword),
      );

      Fluttertoast.showToast(
        msg: "تم تحديث كلمة المرور بنجاح",
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      error.value = e.toString();
      Fluttertoast.showToast(
        msg: "حدث خطأ أثناء تحديث كلمة المرور",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateUserSecpass(String uid, int newSecpass) async {
    try {
      isLoading.value = true;
      await Supabase.instance.client
          .from('users')
          .update({'secpass': newSecpass}).eq('uid', uid);
      await fetchUsers();
      Fluttertoast.showToast(
        msg: "تم تحديث كلمة المرور الثانية بنجاح",
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      error.value = e.toString();
      Fluttertoast.showToast(
        msg: "حدث خطأ أثناء تحديث كلمة المرور الثانية",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateUserRole(String uid, int newRole) async {
    try {
      isLoading.value = true;
      await Supabase.instance.client
          .from('users')
          .update({'role': newRole}).eq('uid', uid);
      await fetchUsers();
      Fluttertoast.showToast(
        msg: "تم تحديث الصلاحية بنجاح",
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      error.value = e.toString();
      Fluttertoast.showToast(
        msg: "حدث خطأ أثناء تحديث الصلاحية",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createUser(
      String email, String password, String name, int role, int secpass) async {
    try {
      isLoading.value = true;

      final authResponse = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Failed to create user authentication');
      }

      final userId = authResponse.user!.id;

      await Supabase.instance.client.from('users').insert({
        'uid': userId,
        'name': name,
        'role': role,
        'secpass': secpass,
        'created_at': DateTime.now().toIso8601String(),
      });

      await fetchUsers();
      Fluttertoast.showToast(
        msg: "تم إنشاء المستخدم بنجاح",
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      error.value = e.toString();
      Fluttertoast.showToast(
        msg: "حدث خطأ أثناء إنشاء المستخدم: ${e.toString()}",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteUser(String uid) async {
    try {
      isLoading.value = true;

      final deleteResponse = await Supabase.instance.client
          .from('users')
          .delete()
          .eq('uid', uid)
          .select('uid');

      if (deleteResponse.isEmpty) {
        throw Exception('Failed to delete user from database');
      }

      users.removeWhere((user) => user.uid == uid);

      Fluttertoast.showToast(
        msg: "تم حذف المستخدم بنجاح",
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      print('Error deleting user: $e');
      error.value = e.toString();
      Fluttertoast.showToast(
        msg: "حدث خطأ أثناء حذف المستخدم",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }
}

class UserManagementPage extends StatelessWidget {
  final controller = Get.put(UserManagementController());
  final currentUserEmail = Supabase.instance.client.auth.currentUser?.email;

  UserManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    if (currentUserEmail != 'eslam.elnini@km.com') {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    size: 48,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'غير مصرح لك بالدخول',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ليس لديك صلاحية الوصول لهذه الصفحة',
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryColor, secondaryColor],
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              title: const Row(
                children: [
                  Icon(Icons.admin_panel_settings_rounded,
                      color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'إدارة المستخدمين',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
              bottom: TabBar(
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.people_rounded, size: 24),
                    text: 'المستخدمين',
                  ),
                  Tab(
                    icon: Icon(Icons.person_add_rounded, size: 24),
                    text: 'إضافة مستخدم',
                  ),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _BuildUserList(controller: controller),
            CreateUserTab(controller: controller),
          ],
        ),
      ),
    );
  }
}

class CreateUserTab extends StatefulWidget {
  final UserManagementController controller;

  const CreateUserTab({super.key, required this.controller});

  @override
  _CreateUserTabState createState() => _CreateUserTabState();
}

class _CreateUserTabState extends State<CreateUserTab> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _secpassController = TextEditingController();
  int _selectedRole = 2;
  bool _showPassword = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _secpassController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'البريد الإلكتروني مطلوب';
    }
    return null;
  }

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    String? helperText,
    Widget? suffixIcon,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Theme(
        data: Theme.of(context).copyWith(
          textSelectionTheme: TextSelectionThemeData(
            selectionColor: primaryColor.withValues(alpha: 0.3),
            cursorColor: primaryColor,
            selectionHandleColor: primaryColor,
          ),
        ),
        child: TextFormField(
          controller: controller,
          obscureText: isPassword ? !_showPassword : false,
          keyboardType: keyboardType,
          validator: validator,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          cursorColor: primaryColor,
          style: const TextStyle(color: textPrimary, fontSize: 15),
          decoration: InputDecoration(
            labelText: label,
            helperText: helperText,
            labelStyle: TextStyle(color: textSecondary, fontSize: 14),
            helperStyle: TextStyle(color: textSecondary.withValues(alpha: 0.7)),
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, secondaryColor],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: accentColor, width: 1.5),
            ),
            filled: true,
            fillColor: surfaceColor,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [primaryColor, secondaryColor],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.person_add_rounded,
                          color: Colors.white, size: 32),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'إضافة مستخدم جديد',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildAnimatedTextField(
                  controller: _nameController,
                  label: 'اسم المستخدم',
                  icon: Icons.person_rounded,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'يرجى إدخال اسم المستخدم' : null,
                ),
                _buildAnimatedTextField(
                  controller: _emailController,
                  label: 'البريد الإلكتروني',
                  icon: Icons.email_rounded,
                  validator: _validateEmail,
                  helperText: 'مثال: username@km.com',
                ),
                _buildAnimatedTextField(
                  controller: _passwordController,
                  label: 'كلمة المرور',
                  icon: Icons.lock_rounded,
                  isPassword: true,
                  validator: (value) =>
                      value!.length < 6 ? 'كلمة المرور قصيرة جداً' : null,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      color: textSecondary,
                    ),
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                  ),
                ),
                _buildAnimatedTextField(
                  controller: _secpassController,
                  label: 'كلمة المرور الثانية',
                  icon: Icons.security_rounded,
                  keyboardType: TextInputType.number,
                  validator: (value) => int.tryParse(value ?? '') == null
                      ? 'أدخل رقماً صحيحاً'
                      : null,
                ),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [primaryColor, secondaryColor],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                                Icons.admin_panel_settings_rounded,
                                color: Colors.white,
                                size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'نوع المستخدم',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CupertinoSlidingSegmentedControl<int>(
                        backgroundColor: backgroundColor,
                        thumbColor: primaryColor,
                        groupValue: _selectedRole,
                        children: {
                          2: _buildSegmentChild('مساعد', _selectedRole == 2),
                          1: _buildSegmentChild('مشرف', _selectedRole == 1),
                        },
                        onValueChanged: (value) {
                          if (value != null)
                            setState(() => _selectedRole = value);
                        },
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [primaryColor, secondaryColor],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _submitForm,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_rounded,
                            color: Colors.white, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'إنشاء المستخدم',
                          style: TextStyle(
                            fontSize: 17,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentChild(String text, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(
        text,
        style: TextStyle(
          color: isSelected ? Colors.white : textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        await widget.controller.createUser(
          _emailController.text,
          _passwordController.text,
          _nameController.text,
          _selectedRole,
          int.parse(_secpassController.text),
        );
        _nameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _secpassController.clear();
      } catch (e) {
        // Error handled in controller
      }
    }
  }
}

class _BuildUserList extends StatelessWidget {
  final UserManagementController controller;

  const _BuildUserList({required this.controller});

  Widget _buildUserCard(AppUser user, BuildContext context) {
    final isOwner = user.role == 1;

    return AnimationConfiguration.staggeredList(
      position: controller.users.indexOf(user),
      duration: const Duration(milliseconds: 500),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Container(
            margin: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 10,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: isOwner
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                      )
                    : null,
                color: isOwner ? null : surfaceColor,
                boxShadow: [
                  BoxShadow(
                    color: isOwner
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isOwner
                            ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
                            : Colors.grey.withValues(alpha: 0.1),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        // Header Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (isOwner)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFF59E0B),
                                      Color(0xFFEF4444)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFF59E0B)
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star_rounded,
                                        color: Colors.white, size: 16),
                                    SizedBox(width: 6),
                                    Text(
                                      "المالك",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (!isOwner) const SizedBox(),
                            Row(
                              children: [
                                _buildIconButton(
                                  icon: Icons.edit_rounded,
                                  color: primaryColor,
                                  onPressed: () =>
                                      _showFullEditDialog(context, user),
                                ),
                                const SizedBox(width: 8),
                                if (!isOwner)
                                  _buildIconButton(
                                    icon: Icons.delete_rounded,
                                    color: accentColor,
                                    onPressed: () =>
                                        _showDeleteConfirmation(context, user),
                                  ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // User Info Row
                        Row(
                          children: [
                            // Avatar
                            GestureDetector(
                              onTap: () => _showImageOptions(context, user),
                              child: Hero(
                                tag: 'user_${user.uid}',
                                child: Container(
                                  width: isOwner ? 90 : 80,
                                  height: isOwner ? 90 : 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: isOwner
                                          ? [
                                              const Color(0xFFF59E0B),
                                              const Color(0xFFEF4444)
                                            ]
                                          : [primaryColor, secondaryColor],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isOwner
                                                ? const Color(0xFFF59E0B)
                                                : primaryColor)
                                            .withValues(alpha: 0.4),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(3),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                    padding: const EdgeInsets.all(3),
                                    child: ClipOval(
                                      child: user.avatarUrl != null
                                          ? Image.network(
                                              user.avatarUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  _buildDefaultAvatar(isOwner),
                                            )
                                          : _buildDefaultAvatar(isOwner),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 16),

                            // User Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name ?? 'غير محدد',
                                    style: TextStyle(
                                      fontSize: isOwner ? 22 : 20,
                                      fontWeight: FontWeight.bold,
                                      color: isOwner
                                          ? const Color(0xFF92400E)
                                          : textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isOwner
                                          ? const Color(0xFFFEF3C7)
                                          : primaryColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isOwner
                                            ? const Color(0xFFF59E0B)
                                            : primaryColor,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.security_rounded,
                                          size: 14,
                                          color: isOwner
                                              ? const Color(0xFFF59E0B)
                                              : primaryColor,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'كلمة المرور: ${user.secpass ?? 'غير محدد'}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isOwner
                                                ? const Color(0xFF92400E)
                                                : primaryColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Action Buttons
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.end,
                          children: [
                            _buildActionChip(
                              icon: Icons.person_rounded,
                              label: 'تعديل الاسم',
                              onPressed: () =>
                                  _showEditNameDialog(context, user),
                            ),
                            _buildActionChip(
                              icon: Icons.security_rounded,
                              label: 'كلمة المرور الثانية',
                              onPressed: () =>
                                  _showEditSecpassDialog(context, user),
                            ),
                            _buildActionChip(
                              icon: Icons.lock_rounded,
                              label: 'كلمة المرور',
                              onPressed: () =>
                                  _showEditPasswordDialog(context, user),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onPressed,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: textSecondary, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(bool isOwner) {
    return Image.asset(
      isOwner ? 'assets/images/owner.png' : 'assets/images/MKQ.png',
      fit: BoxFit.cover,
    );
  }

  void _showImageOptions(BuildContext context, AppUser user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'تعديل الصورة',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, secondaryColor],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library_rounded,
                    color: Colors.white, size: 20),
              ),
              title: const Text('اختيار من المعرض'),
              onTap: () async {
                Navigator.pop(context);
                final imageUrl = await controller.uploadUserImage(user.uid!);
                if (imageUrl != null) {
                  await controller.updateUserAvatar(user.uid!, imageUrl);
                }
              },
            ),
            if (user.avatarUrl != null)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete_rounded,
                      color: accentColor, size: 20),
                ),
                title: const Text('حذف الصورة'),
                onTap: () async {
                  Navigator.pop(context);
                  await controller.updateUserAvatar(user.uid!, '');
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showEditNameDialog(BuildContext context, AppUser user) {
    final nameController = TextEditingController(text: user.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تعديل الاسم',
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'الاسم الجديد',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryColor, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: textSecondary)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, secondaryColor],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  controller.updateUserName(user.uid!, nameController.text);
                  Navigator.pop(context);
                }
              },
              child: const Text('حفظ', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditPasswordDialog(BuildContext context, AppUser user) {
    final passwordController = TextEditingController();
    bool showPassword = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: surfaceColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('تعديل كلمة المرور',
              style:
                  TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: passwordController,
            obscureText: !showPassword,
            decoration: InputDecoration(
              labelText: 'كلمة المرور الجديدة',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primaryColor, width: 2),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                    showPassword
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    color: textSecondary),
                onPressed: () => setState(() => showPassword = !showPassword),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('إلغاء', style: TextStyle(color: textSecondary)),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, secondaryColor],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  if (passwordController.text.length >= 6) {
                    controller.updateUserPassword(
                        user.uid!, passwordController.text);
                    Navigator.pop(context);
                  } else {
                    Fluttertoast.showToast(
                      msg: "كلمة المرور يجب أن تكون 6 أحرف على الأقل",
                      backgroundColor: Colors.red,
                      textColor: Colors.white,
                    );
                  }
                },
                child: const Text('حفظ', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSecpassDialog(BuildContext context, AppUser user) {
    final secpassController =
        TextEditingController(text: user.secpass?.toString() ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تعديل كلمة المرور الثانية',
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: secpassController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'كلمة المرور الثانية الجديدة',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryColor, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: textSecondary)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, secondaryColor],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                int? newSecpass = int.tryParse(secpassController.text);
                if (newSecpass != null) {
                  controller.updateUserSecpass(user.uid!, newSecpass);
                  Navigator.pop(context);
                }
              },
              child: const Text('حفظ', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullEditDialog(BuildContext context, AppUser user) {
    final nameController = TextEditingController(text: user.name);
    final secpassController =
        TextEditingController(text: user.secpass?.toString() ?? '');
    int selectedRole = user.role ?? 2;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: surfaceColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('تعديل بيانات المستخدم',
              style:
                  TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'الاسم',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: primaryColor, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: secpassController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور الثانية',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: primaryColor, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('الصلاحية',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: textPrimary)),
                      const SizedBox(height: 8),
                      CupertinoSlidingSegmentedControl<int>(
                        backgroundColor: backgroundColor,
                        thumbColor: primaryColor,
                        groupValue: selectedRole,
                        children: {
                          2: _buildSegmentChild('مساعد', selectedRole == 2),
                          1: _buildSegmentChild('مشرف', selectedRole == 1),
                        },
                        onValueChanged: (value) {
                          if (value != null) {
                            setState(() => selectedRole = value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('إلغاء', style: TextStyle(color: textSecondary)),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, secondaryColor],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  if (nameController.text.isNotEmpty) {
                    await controller.updateUserName(
                        user.uid!, nameController.text);
                  }
                  int? newSecpass = int.tryParse(secpassController.text);
                  if (newSecpass != null) {
                    await controller.updateUserSecpass(user.uid!, newSecpass);
                  }
                  if (selectedRole != user.role) {
                    await controller.updateUserRole(user.uid!, selectedRole);
                  }
                  Navigator.pop(context);
                },
                child: const Text('حفظ الكل',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentChild(String text, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(
        text,
        style: TextStyle(
          color: isSelected ? Colors.white : textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, AppUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تأكيد الحذف',
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
        content: Text('هل أنت متأكد من حذف المستخدم ${user.name}؟',
            style: const TextStyle(color: textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: textSecondary)),
          ),
          Container(
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                try {
                  Navigator.pop(context);
                  await controller.deleteUser(user.uid!);
                } catch (e) {
                  print('Error in delete confirmation: $e');
                }
              },
              child: const Text('حذف', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, secondaryColor],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'جاري التحميل...',
                style: TextStyle(
                  fontSize: 16,
                  color: textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        color: backgroundColor,
        child: AnimationLimiter(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 4),
            itemCount: controller.users.length,
            itemBuilder: (context, index) {
              return _buildUserCard(controller.users[index], context);
            },
          ),
        ),
      );
    });
  }
}
