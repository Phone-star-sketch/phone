import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:phone_system_app/pages/user_management/constants/user_management_colors.dart';
import 'package:phone_system_app/pages/user_management/controllers/user_management_controller.dart';
import 'package:phone_system_app/pages/user_management/widgets/custom_text_field.dart';
import 'package:phone_system_app/pages/user_management/widgets/gradient_button.dart';

class CreateUserTab extends StatefulWidget {
  final UserManagementController controller;

  const CreateUserTab({super.key, required this.controller});

  @override
  State<CreateUserTab> createState() => _CreateUserTabState();
}

class _CreateUserTabState extends State<CreateUserTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _secpassController = TextEditingController();
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

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'البريد الإلكتروني غير صحيح';
    }

    if (!value.endsWith('@km.com')) {
      return 'يجب أن ينتهي البريد بـ @km.com';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'كلمة المرور مطلوبة';
    }
    if (value.length < 6) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }
    return null;
  }

  String? _validateSecpass(String? value) {
    if (int.tryParse(value ?? '') == null) {
      return 'أدخل رقماً صحيحاً';
    }
    return null;
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
        _clearForm();
      } catch (e) {
        // Error handled in controller
      }
    }
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _secpassController.clear();
    setState(() {
      _selectedRole = 2;
      _showPassword = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: UserManagementColors.background,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                CustomTextField(
                  controller: _nameController,
                  label: 'اسم المستخدم',
                  icon: Icons.person_rounded,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'يرجى إدخال اسم المستخدم' : null,
                ),
                CustomTextField(
                  controller: _emailController,
                  label: 'البريد الإلكتروني',
                  icon: Icons.email_rounded,
                  validator: _validateEmail,
                  keyboardType: TextInputType.emailAddress,
                  helperText: 'مثال: username@km.com (يجب أن ينتهي بـ @km.com)',
                ),
                CustomTextField(
                  controller: _passwordController,
                  label: 'كلمة المرور',
                  icon: Icons.lock_rounded,
                  isPassword: !_showPassword,
                  validator: _validatePassword,
                  helperText: 'يجب أن تكون 6 أحرف على الأقل',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      color: UserManagementColors.textSecondary,
                    ),
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                  ),
                ),
                CustomTextField(
                  controller: _secpassController,
                  label: 'كلمة المرور الثانية',
                  icon: Icons.security_rounded,
                  keyboardType: TextInputType.number,
                  validator: _validateSecpass,
                ),
                _buildRoleSelector(),
                const SizedBox(height: 20),
                GradientButton(
                  onPressed: _submitForm,
                  text: 'إنشاء المستخدم',
                  icon: Icons.add_circle_rounded,
                  width: double.infinity,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
      child: const Row(
        children: [
          Icon(Icons.person_add_rounded, color: Colors.white, size: 32),
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
    );
  }

  Widget _buildRoleSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: UserManagementColors.surface,
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
                  gradient: const LinearGradient(
                    colors: [
                      UserManagementColors.primary,
                      UserManagementColors.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'نوع المستخدم',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: UserManagementColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CupertinoSlidingSegmentedControl<int>(
            backgroundColor: UserManagementColors.background,
            thumbColor: UserManagementColors.primary,
            groupValue: _selectedRole,
            children: {
              2: _buildSegmentChild('مساعد', _selectedRole == 2),
              1: _buildSegmentChild('مشرف', _selectedRole == 1),
            },
            onValueChanged: (value) {
              if (value != null) setState(() => _selectedRole = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentChild(String text, bool isSelected) {
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
