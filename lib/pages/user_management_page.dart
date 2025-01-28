import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';
import 'package:phone_system_app/models/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';  // Add this import

class UserManagementController extends GetxController {
  final RxList<AppUser> users = <AppUser>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    try {
      isLoading.value = true;
      final response = await Supabase.instance.client.from('users').select();
      var usersList = (response as List).map((user) => AppUser.fromJson(user)).toList();
      
      // Sort users: role 1 first, then by name
      usersList.sort((a, b) {
        if (a.role == 1 && b.role != 1) return -1;
        if (a.role != 1 && b.role == 1) return 1;
        // If roles are same, sort by name
        return (a.name ?? '').compareTo(b.name ?? '');
      });
      
      users.value = usersList;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateUserPassword(String uid, String newPassword) async {
    try {
      isLoading.value = true;
      await Supabase.instance.client
          .from('users')
          .update({'password': newPassword})
          .eq('uid', uid)
          .select();
      await fetchUsers();
      Fluttertoast.showToast(
        msg: "تم تحديث كلمة المرور بنجاح",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      error.value = e.toString();
      Fluttertoast.showToast(
        msg: "حدث خطأ أثناء تحديث كلمة المرور",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
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
          .update({'secpass': newSecpass})
          .eq('uid', uid)
          .select();
      await fetchUsers();
      Fluttertoast.showToast(
        msg: "تم تحديث كلمة المرور الثانية بنجاح",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      error.value = e.toString();
      Fluttertoast.showToast(
        msg: "حدث خطأ أثناء تحديث كلمة المرور الثانية",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
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
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      // Insert additional user data into the users table
      final userId = response.user?.id;
      if (userId != null) {
        final insertResponse =
            await Supabase.instance.client.from('users').insert({
          'uid': userId,
          'name': name,
          'role': role,
          'secpass': secpass,  // Add secpass here
        }).select();
      }

      await fetchUsers();
      Fluttertoast.showToast(
        msg: "تم إنشاء المستخدم بنجاح",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      error.value = e.toString();
      Fluttertoast.showToast(
        msg: "حدث خطأ أثناء إنشاء المستخدم: ${e.toString()}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}

class UserManagementPage extends StatelessWidget {
  final controller = Get.put(UserManagementController());
  final currentUserEmail =
      Supabase.instance.client.auth.currentUser?.email;

  @override
  Widget build(BuildContext context) {
    if (currentUserEmail != 'eslam.elnini@km.com') {
      return Scaffold(
        body: Center(
          child: Text('غير مصرح لك بالدخول لهذه الصفحة',
              style: TextStyle(fontSize: 18, color: Colors.red)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('إدارة المستخدمين'),
      ),
      body: _BuildUserList(controller: controller),
    );
  }
}

class _BuildUserList extends StatelessWidget {
  final UserManagementController controller;
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController secpassController = TextEditingController();

  _BuildUserList({required this.controller});

  Widget _buildUserCard(AppUser user, BuildContext context) {
    final isOwner = user.role == 1;

    return AnimationConfiguration.staggeredList(
      position: controller.users.indexOf(user),
      duration: const Duration(milliseconds: 375),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Card(
            elevation: isOwner ? 12 : 8,
            margin: EdgeInsets.symmetric(
              horizontal: isOwner ? 12 : 16,
              vertical: isOwner ? 16 : 8,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: isOwner 
                ? BorderSide(color: Colors.red.shade300, width: 2)
                : BorderSide.none,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: isOwner
                    ? [
                        Colors.red.shade50,
                        Colors.white,
                        Colors.red.shade50,
                      ]
                    : [
                        Colors.white,
                        Colors.red.withOpacity(0.1),
                      ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: isOwner
                  ? [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.2),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
              ),
              child: Padding(
                padding: EdgeInsets.all(isOwner ? 20.0 : 16.0),
                child: Column(
                  children: [
                    if (isOwner)
                      const Chip(
                        label: Text(
                          "المالك",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      ),
                    Row(
                      children: [
                        // Enhanced User Image
                        Hero(
                          tag: 'user_${user.uid}',
                          child: Container(
                            width: isOwner ? 100 : 80,
                            height: isOwner ? 100 : 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isOwner ? Colors.red : Colors.red.shade200,
                                width: isOwner ? 3 : 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (isOwner ? Colors.red : Colors.black)
                                      .withOpacity(0.2),
                                  blurRadius: isOwner ? 15 : 10,
                                  spreadRadius: isOwner ? 3 : 2,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: isOwner
                                ? Stack(
                                    children: [
                                      Image.asset(
                                        'assets/images/owner.png',
                                        fit: BoxFit.cover,
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.red.withOpacity(0.3),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Image.asset(
                                    'assets/images/logo.png',
                                    fit: BoxFit.cover,
                                  ),
                            ),
                          ),
                        ),
                        SizedBox(width: isOwner ? 24 : 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name ?? '',
                                style: TextStyle(
                                  fontSize: isOwner ? 24 : 20,
                                  fontWeight: FontWeight.bold,
                                  color: isOwner ? Colors.red : Colors.red.shade700,
                                  letterSpacing: isOwner ? 0.5 : 0,
                                ),
                              ),
                              SizedBox(height: isOwner ? 8 : 4),
                              Container(
                                padding: isOwner 
                                  ? EdgeInsets.symmetric(horizontal: 12, vertical: 6)
                                  : null,
                                decoration: isOwner
                                  ? BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(20),
                                    )
                                  : null,
                                child: Text(
                                  'كلمة المرور الثانية: ${user.secpass ?? 'غير محدد'}',
                                  style: TextStyle(
                                    fontSize: isOwner ? 18 : 16,
                                    color: isOwner 
                                      ? Colors.red.shade700
                                      : Colors.grey[600],
                                    fontWeight: isOwner 
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isOwner ? 24 : 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          icon: Icon(
                            isOwner ? Icons.admin_panel_settings : Icons.edit,
                            color: Colors.white,
                          ),
                          label: Text(
                            'تعديل كلمة المرور الثانية',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isOwner ? 16 : 14,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isOwner 
                              ? Colors.red
                              : Colors.red.shade400,
                            padding: isOwner
                              ? EdgeInsets.symmetric(horizontal: 24, vertical: 16)
                              : EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(isOwner ? 16 : 12),
                            ),
                            elevation: isOwner ? 6 : 4,
                          ),
                          onPressed: () => _showEditDialog(context, user),
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
    );
  }

  void _showEditDialog(BuildContext context, AppUser user) {
    secpassController.text = user.secpass?.toString() ?? '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text('تعديل كلمة المرور الثانية'),
        content: TextField(
          controller: secpassController,
          decoration: InputDecoration(
            labelText: 'كلمة المرور الثانية الجديدة',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
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
            child: Text('حفظ', style: TextStyle(color: Colors.white)),
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
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
          ),
        );
      }

      return AnimationLimiter(
        child: ListView.builder(
          padding: EdgeInsets.symmetric(vertical: 16),
          itemCount: controller.users.length,
          itemBuilder: (context, index) {
            return _buildUserCard(controller.users[index], context);
          },
        ),
      );
    });
  }
}
