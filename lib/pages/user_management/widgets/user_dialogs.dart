import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:phone_system_app/models/user.dart';
import '../constants/user_management_colors.dart';
import '../controllers/user_management_controller.dart';
import 'gradient_button.dart';

class UserDialogs {
  UserDialogs._();

  static void showEditName(
    BuildContext context,
    AppUser user,
    UserManagementController controller,
  ) {
    final nameController = TextEditingController(text: user.name);

    showDialog(
      context: context,
      builder: (context) => _buildDialog(
        context: context,
        title: 'تعديل الاسم',
        content: _buildTextField(
          controller: nameController,
          label: 'الاسم الجديد',
        ),
        onSave: () {
          if (nameController.text.isNotEmpty) {
            controller.updateUserName(user.uid!, nameController.text);
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  static void showEditPassword(
    BuildContext context,
    AppUser user,
    UserManagementController controller,
  ) {
    final passwordController = TextEditingController();
    bool showPassword = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => _buildDialog(
          context: context,
          title: 'تعديل كلمة المرور',
          content: _buildTextField(
            controller: passwordController,
            label: 'كلمة المرور الجديدة',
            obscureText: !showPassword,
            suffixIcon: IconButton(
              icon: Icon(
                showPassword
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                color: UserManagementColors.textSecondary,
              ),
              onPressed: () => setState(() => showPassword = !showPassword),
            ),
          ),
          onSave: () {
            if (passwordController.text.length >= 6) {
              controller.updateUserPassword(user.uid!, passwordController.text);
              Navigator.pop(context);
            } else {
              Fluttertoast.showToast(
                msg: "كلمة المرور يجب أن تكون 6 أحرف على الأقل",
                backgroundColor: Colors.red,
                textColor: Colors.white,
              );
            }
          },
        ),
      ),
    );
  }

  static void showEditSecpass(
    BuildContext context,
    AppUser user,
    UserManagementController controller,
  ) {
    final secpassController = TextEditingController(
      text: user.secpass?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => _buildDialog(
        context: context,
        title: 'تعديل كلمة المرور الثانية',
        content: _buildTextField(
          controller: secpassController,
          label: 'كلمة المرور الثانية الجديدة',
          keyboardType: TextInputType.number,
        ),
        onSave: () {
          int? newSecpass = int.tryParse(secpassController.text);
          if (newSecpass != null) {
            controller.updateUserSecpass(user.uid!, newSecpass);
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  static void showFullEdit(
    BuildContext context,
    AppUser user,
    UserManagementController controller,
  ) {
    final nameController = TextEditingController(text: user.name);
    final secpassController = TextEditingController(
      text: user.secpass?.toString() ?? '',
    );
    int selectedRole = user.role ?? 2;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => _buildDialog(
          context: context,
          title: 'تعديل بيانات المستخدم',
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(
                  controller: nameController,
                  label: 'الاسم',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: secpassController,
                  label: 'كلمة المرور الثانية',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                _buildRoleSelector(
                  selectedRole: selectedRole,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedRole = value);
                    }
                  },
                ),
              ],
            ),
          ),
          onSave: () async {
            final navigator = Navigator.of(context);
            if (nameController.text.isNotEmpty) {
              await controller.updateUserName(user.uid!, nameController.text);
            }
            int? newSecpass = int.tryParse(secpassController.text);
            if (newSecpass != null) {
              await controller.updateUserSecpass(user.uid!, newSecpass);
            }
            if (selectedRole != user.role) {
              await controller.updateUserRole(user.uid!, selectedRole);
            }
            navigator.pop();
          },
          saveButtonText: 'حفظ الكل',
        ),
      ),
    );
  }

  static void showDeleteConfirmation(
    BuildContext context,
    AppUser user,
    UserManagementController controller,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: UserManagementColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'تأكيد الحذف',
          style: TextStyle(
            color: UserManagementColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'هل أنت متأكد من حذف المستخدم ${user.name}؟',
          style: const TextStyle(color: UserManagementColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'إلغاء',
              style: TextStyle(color: UserManagementColors.textSecondary),
            ),
          ),
          GradientButton(
            onPressed: () async {
              try {
                Navigator.pop(dialogContext);
                await controller.deleteUser(user.uid!);
              } catch (e) {
                debugPrint('Error in delete confirmation: $e');
              }
            },
            text: 'حذف',
            gradientColors: const [
              UserManagementColors.accent,
              UserManagementColors.accent,
            ],
            height: 40,
          ),
        ],
      ),
    );
  }

  static void showImageOptions(
    BuildContext context,
    AppUser user,
    UserManagementController controller,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: UserManagementColors.surface,
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
                color: UserManagementColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      UserManagementColors.primary,
                      UserManagementColors.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.photo_library_rounded,
                  color: Colors.white,
                  size: 20,
                ),
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
                    color: UserManagementColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.delete_rounded,
                    color: UserManagementColors.accent,
                    size: 20,
                  ),
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

  // Private helper widgets
  static Widget _buildDialog({
    required BuildContext context,
    required String title,
    required Widget content,
    required VoidCallback onSave,
    String saveButtonText = 'حفظ',
  }) {
    return AlertDialog(
      backgroundColor: UserManagementColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: UserManagementColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: content,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'إلغاء',
            style: TextStyle(color: UserManagementColors.textSecondary),
          ),
        ),
        GradientButton(
          onPressed: onSave,
          text: saveButtonText,
          height: 40,
        ),
      ],
    );
  }

  static Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: UserManagementColors.primary,
            width: 2,
          ),
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }

  static Widget _buildRoleSelector({
    required int selectedRole,
    required ValueChanged<int?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الصلاحية',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: UserManagementColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          CupertinoSlidingSegmentedControl<int>(
            backgroundColor: UserManagementColors.background,
            thumbColor: UserManagementColors.primary,
            groupValue: selectedRole,
            children: {
              2: _buildSegmentChild('مساعد', selectedRole == 2),
              1: _buildSegmentChild('مشرف', selectedRole == 1),
            },
            onValueChanged: onChanged,
          ),
        ],
      ),
    );
  }

  static Widget _buildSegmentChild(String text, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(
        text,
        style: TextStyle(
          color: isSelected ? Colors.white : UserManagementColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}
