import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';
import 'package:phone_system_app/models/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';

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
      users.value =
          (response as List).map((user) => AppUser.fromJson(user)).toList();
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

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(child: CircularProgressIndicator());
      }

      return ListView.builder(
        itemCount: controller.users.length,
        itemBuilder: (context, index) {
          final user = controller.users[index];
          return Card(
            margin: EdgeInsets.all(8),
            child: ListTile(
              title: Text(user.name ?? ''),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.uid ?? ''),
                  Text('كلمة المرور الثانية: ${user.secpass ?? 'غير محدد'}'),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('تغيير كلمة المرور الثانية'),
                          content: TextField(
                            controller: secpassController,
                            decoration: InputDecoration(
                              labelText: 'كلمة المرور الثانية الجديدة',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('إلغاء'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                int? newSecpass = int.tryParse(secpassController.text);
                                if (newSecpass != null) {
                                  controller.updateUserSecpass(
                                    user.uid!,
                                    newSecpass,
                                  );
                                  Navigator.pop(context);
                                }
                              },
                              child: Text('حفظ'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                ],
              ),
            ),
          );
        },
      );
    });
  }
}
