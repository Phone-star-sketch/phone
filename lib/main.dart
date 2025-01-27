import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:phone_system_app/components/money_display.dart';
import 'package:phone_system_app/models/log.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';
import 'package:phone_system_app/views/account_view.dart';
import 'package:phone_system_app/views/pages/auth_raper.dart';
import 'package:phone_system_app/views/pages/for_sale_number.dart';
import 'package:phone_system_app/views/pages/login_page.dart';
import 'package:phone_system_app/views/print_clients_receipts.dart';
import 'package:phone_system_app/views/stats_view.dart';
import 'package:phone_system_app/pages/entry_page.dart'; // Add this import
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/views/pages/auth_wrapper.dart';  // Update import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Add gesture binding configuration
  GestureBinding.instance.resamplingEnabled = true;

  await BackendServices.instance.initialize();

  // Add these configurations
  if (GetPlatform.isAndroid) {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
    SystemChrome.setSystemUIChangeCallback((systemOverlaysAreVisible) {
      // Handle system UI visibility changes
      return Future.value();
    });
  }

  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  MainApp({super.key});

  double value = 10;

  @override
  Widget build(BuildContext context) {
    final colorScheme = const ColorScheme.light(
            background: Colors.black87, brightness: Brightness.dark)
        .copyWith(
      primary: Colors.white54,
      onPrimary: Colors.greenAccent,
      secondary: Colors.blueAccent,
      onBackground: Colors.black,
      background: Colors.red,
      surfaceTint: Color.fromARGB(255, 249, 249, 249),
      error: const Color(0xFFd62828),
    );

    final textTheme = Theme.of(context).textTheme.apply(
          fontFamily: "Cairo",
          bodyColor: Colors.black,
          displayColor: colorScheme.onBackground,
          decorationColor: colorScheme.onBackground,
        );

    return GetMaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar')],
      theme: ThemeData(
        colorScheme: colorScheme,
        textTheme: textTheme,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
        datePickerTheme: DatePickerThemeData(
          surfaceTintColor: Colors.black,
          backgroundColor: Colors.white,
          headerBackgroundColor: colorScheme.background,
          cancelButtonStyle:
              ElevatedButton.styleFrom(backgroundColor: Colors.black),
          confirmButtonStyle:
              ElevatedButton.styleFrom(backgroundColor: Colors.red),
          dividerColor: colorScheme.background,
        ),
        splashFactory: kIsWeb ? NoSplash.splashFactory : null,
      ),
      home: AuthWrapper(), // Set AuthWrapper as initial route
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 200),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: ScrollBehavior().copyWith(
            physics: const BouncingScrollPhysics(),
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
            },
          ),
          child: child!,
        );
      },
    );
  }
}
