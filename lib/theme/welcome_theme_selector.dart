import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/entry_page.dart' as ramadan;
import '../pages/Eid_page.dart' as eid;
import '../pages/general_ui.dart' as general;

enum WelcomeTheme {
  ramadan,
  eid,
  general,
}

class WelcomeThemeController extends GetxController {
  static WelcomeThemeController get to => Get.find();
  final _theme = WelcomeTheme.general.obs;
  final _prefs = SharedPreferences.getInstance();

  WelcomeTheme get currentTheme => _theme.value;

  @override
  void onInit() {
    super.onInit();
    loadSavedTheme();
  }

  Future<void> loadSavedTheme() async {
    final prefs = await _prefs;
    final savedTheme = prefs.getString('welcome_theme') ?? 'general';
    _theme.value = WelcomeTheme.values.firstWhere(
      (e) => e.toString().split('.').last == savedTheme,
      orElse: () => WelcomeTheme.general,
    );
  }

  Future<void> setTheme(WelcomeTheme theme) async {
    _theme.value = theme;
    final prefs = await _prefs;
    await prefs.setString('welcome_theme', theme.toString().split('.').last);
  }

  Widget getCurrentWelcomePage() {
    switch (_theme.value) {
      case WelcomeTheme.ramadan:
        return ramadan.WelcomePage(); // Ramadan theme (entry_page.dart)
      case WelcomeTheme.eid:
        return eid.WelcomePage(); // Eid theme (Eid_page.dart)
      case WelcomeTheme.general:
        return general.WelcomePage(); // General theme (general_ui.dart)
    }
  }
}
