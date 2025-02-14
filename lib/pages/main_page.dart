import 'package:flutter/material.dart';
import 'package:phone_system_app/theme/app_colors.dart';

// ...existing code...

@override
Widget build(BuildContext context) {
  return Scaffold(
    // ...existing code...
    bottomNavigationBar: Container(
      decoration: BoxDecoration(
        gradient: AppColors.skyGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        backgroundColor: Colors.transparent,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.6),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
    ),
    // ...existing code...
  );
}
