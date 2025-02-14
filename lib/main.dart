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
import 'package:phone_system_app/views/pages/auth_wrapper.dart'; // Update import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Add performance optimizations
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
  }

  // Enable image caching
  PaintingBinding.instance.imageCache.maximumSize = 100;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20; // 50 MB

  // Initialize services
  await BackendServices.instance.initialize();

  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

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
      home: WelcomePage(), // Changed from AuthWrapper() to EntryPage()
      defaultTransition: Transition.fadeIn,
      transitionDuration:
          const Duration(milliseconds: 150), // Faster transitions
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light, // Reduce theme switches
      popGesture: true, // Enable swipe to go back
      enableLog: false, // Disable GetX logs
      opaqueRoute: true, // Make routes opaque for better performance
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: ScrollBehavior().copyWith(
            physics:
                const ClampingScrollPhysics(), // More performant than BouncingScrollPhysics
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
