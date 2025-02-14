import 'package:flutter/material.dart';

class AppColors {
  static const Color skyLight = Color(0xFF87CEEB);
  static const Color skyMedium = Color(0xFF00BFFF);
  static const Color skyDark = Color(0xFF1E90FF);

  static const LinearGradient skyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [skyLight, skyMedium, skyDark],
  );
}
