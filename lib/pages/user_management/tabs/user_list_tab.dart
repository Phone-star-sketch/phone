import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:phone_system_app/pages/user_management/constants/user_management_colors.dart';
import 'package:phone_system_app/pages/user_management/controllers/user_management_controller.dart';
import 'package:phone_system_app/pages/user_management/widgets/user_card.dart';

class UserListTab extends StatelessWidget {
  final UserManagementController controller;

  const UserListTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return _buildLoadingState();
      }

      if (controller.users.isEmpty) {
        return _buildEmptyState();
      }

      return Container(
        color: UserManagementColors.background,
        child: AnimationLimiter(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 4),
            itemCount: controller.users.length,
            itemBuilder: (context, index) {
              return UserCard(
                user: controller.users[index],
                index: index,
                controller: controller,
              );
            },
          ),
        ),
      );
    });
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  UserManagementColors.primary,
                  UserManagementColors.secondary,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: UserManagementColors.primary.withValues(alpha: 0.3),
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
              color: UserManagementColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: UserManagementColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_outline_rounded,
              size: 64,
              color: UserManagementColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'لا يوجد مستخدمين',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: UserManagementColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'قم بإضافة مستخدم جديد من التبويب الثاني',
            style: TextStyle(
              fontSize: 14,
              color: UserManagementColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
