import 'package:flutter/material.dart';
import '../constants/user_management_colors.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isPassword;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final String? helperText;
  final Widget? suffixIcon;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.isPassword = false,
    this.validator,
    this.keyboardType,
    this.helperText,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Theme(
        data: Theme.of(context).copyWith(
          textSelectionTheme: TextSelectionThemeData(
            selectionColor: UserManagementColors.primary.withValues(alpha: 0.3),
            cursorColor: UserManagementColors.primary,
            selectionHandleColor: UserManagementColors.primary,
          ),
        ),
        child: TextFormField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          validator: validator,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          cursorColor: UserManagementColors.primary,
          style: const TextStyle(
            color: UserManagementColors.textPrimary,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            labelText: label,
            helperText: helperText,
            labelStyle: const TextStyle(
              color: UserManagementColors.textSecondary,
              fontSize: 14,
            ),
            helperStyle: TextStyle(
              color: UserManagementColors.textSecondary.withValues(alpha: 0.7),
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
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
              borderSide: const BorderSide(
                color: UserManagementColors.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: UserManagementColors.accent,
                width: 1.5,
              ),
            ),
            filled: true,
            fillColor: UserManagementColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }
}
