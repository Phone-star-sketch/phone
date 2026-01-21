/// User Management Module
///
/// This module provides a complete user management system with:
/// - User creation and deletion
/// - User profile editing
/// - Password management
/// - Role management
/// - Avatar upload
///
/// Usage:
/// ```dart
/// import 'package:phone_system_app/pages/user_management/user_management.dart';
///
/// Navigator.push(
///   context,
///   MaterialPageRoute(builder: (context) => UserManagementPage()),
/// );
/// ```

library user_management;

// Main page
export '../user_management_page.dart';

// Constants
export 'constants/user_management_colors.dart';

// Controllers
export 'controllers/user_management_controller.dart';

// Tabs
export 'tabs/create_user_tab.dart';
export 'tabs/user_list_tab.dart';

// Widgets
export 'widgets/custom_text_field.dart';
export 'widgets/gradient_button.dart';
export 'widgets/user_card.dart';
export 'widgets/user_dialogs.dart';
