import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'user_management/constants/user_management_colors.dart';
import 'user_management/controllers/user_management_controller.dart';
import 'user_management/tabs/create_user_tab.dart';
import 'user_management/tabs/user_list_tab.dart';

class UserManagementPage extends StatelessWidget {
  final controller = Get.put(UserManagementController());
  final currentUserEmail = Supabase.instance.client.auth.currentUser?.email;

  UserManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    _setSystemUIOverlay();

    if (!_hasAccess) {
      return _buildAccessDenied();
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: UserManagementColors.background,
        appBar: _buildAppBar(),
        body: TabBarView(
          children: [
            UserListTab(controller: controller),
            CreateUserTab(controller: controller),
          ],
        ),
      ),
    );
  }

  bool get _hasAccess => currentUserEmail == 'eslam.elnini@km.com';

  void _setSystemUIOverlay() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(120),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              UserManagementColors.primary,
              UserManagementColors.secondary,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: UserManagementColors.primary.withValues(alpha: 0.3),
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
              Icon(
                Icons.admin_panel_settings_rounded,
                color: Colors.white,
                size: 28,
              ),
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
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: Colors.white,
            unselectedLabelColor: Color(0x99FFFFFF),
            labelStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
            tabs: [
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
    );
  }

  Widget _buildAccessDenied() {
    return Scaffold(
      backgroundColor: UserManagementColors.background,
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: UserManagementColors.surface,
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
                  color: UserManagementColors.accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  size: 48,
                  color: UserManagementColors.accent,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'غير مصرح لك بالدخول',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: UserManagementColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'ليس لديك صلاحية الوصول لهذه الصفحة',
                style: TextStyle(
                  fontSize: 14,
                  color: UserManagementColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
