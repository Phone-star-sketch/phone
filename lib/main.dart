import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// Remove problematic imports for web
// import 'package:phone_system_app/components/money_display.dart';
// import 'package:phone_system_app/models/log.dart';
import 'package:phone_system_app/repositories/system/supabase_system_repository.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';
// import 'package:phone_system_app/views/account_view.dart';
// import 'package:phone_system_app/views/pages/auth_raper.dart';
// import 'package:phone_system_app/views/pages/for_sale_number.dart';
// import 'package:phone_system_app/views/pages/login_page.dart';
// import 'package:phone_system_app/views/print_clients_receipts.dart';
// import 'package:phone_system_app/views/stats_view.dart';
// import 'package:phone_system_app/pages/entry_page.dart';
// import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
// import 'package:phone_system_app/views/pages/auth_wrapper.dart';
import 'package:phone_system_app/theme/welcome_theme_selector.dart';
// import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Web-specific initialization
  if (kIsWeb) {
    FlutterError.onError = (FlutterErrorDetails details) {
      if (kDebugMode) {
        print('Web error: ${details.exception}');
      }
    };

    // Skip mobile-only initialization
    if (kDebugMode) {
      print('Running on web - mobile services disabled');
    }
  } else {
    // Mobile initialization only when not on web
    try {
      await SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
    } catch (e) {
      if (kDebugMode) {
        print('Mobile setup failed: $e');
      }
    }
  }

  // Initialize theme controller with web-safe approach
  try {
    Get.put(WelcomeThemeController());
  } catch (e) {
    if (kDebugMode) {
      print('Theme controller failed: $e');
    }
  }

  // Web-safe image cache setup
  if (!kIsWeb) {
    try {
      PaintingBinding.instance.imageCache.maximumSize = 100;
      PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20;
    } catch (e) {
      if (kDebugMode) {
        print('Image cache setup failed: $e');
      }
    }
  }

  // Initialize services with error handling
  try {
    await BackendServices.instance.initialize();
    Get.put(SupabaseSystemRepository());
  } catch (e) {
    if (kDebugMode) {
      print('Services initialization failed: $e');
    }
  }

  runApp(const MainApp());
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
      home: Stack(
        children: [
          GetX<WelcomeThemeController>(
            builder: (controller) {
              // Add null check for web safety
              try {
                return controller.getCurrentWelcomePage();
              } catch (e) {
                return Container(
                  color: Colors.blue,
                  child: Center(
                    child: Text(
                      'مرحباً',
                      style: TextStyle(color: Colors.white, fontSize: 24),
                    ),
                  ),
                );
              }
            },
          ),
          Positioned(
            top: 40,
            right: 16,
            child: Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.palette_outlined, color: Colors.white),
                onPressed: () => _showThemeSelector(context),
              ),
            ),
          ),
        ],
      ),
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

  void _showThemeSelector(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 5,
        backgroundColor: Colors.white,
        child: Container(
          width: screenSize.width * 0.8,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title with decorative elements
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.palette_outlined,
                      color: Colors.purple[700], size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'اختر المظهر',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.palette_outlined,
                      color: Colors.purple[700], size: 24),
                ],
              ),

              const SizedBox(height: 6),
              Container(
                width: 100,
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade200, Colors.purple.shade800],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),

              _buildThemeOption(
                context,
                title: 'رمضان',
                icon: Icons.mosque,
                color: Colors.green,
                gradient: const LinearGradient(
                  colors: [Color(0xFF1F8B4C), Color(0xFF3A6978)],
                ),
                onTap: () {
                  try {
                    WelcomeThemeController.to.setTheme(WelcomeTheme.ramadan);
                  } catch (e) {
                    if (kDebugMode) print('Theme set error: $e');
                  }
                  Navigator.pop(context);
                },
              ),

              const SizedBox(height: 12),

              _buildThemeOption(
                context,
                title: 'عيد',
                icon: Icons.celebration,
                color: Colors.amber,
                gradient: const LinearGradient(
                  colors: [Color(0xFFF9A825), Color(0xFFFF7043)],
                ),
                onTap: () {
                  try {
                    WelcomeThemeController.to.setTheme(WelcomeTheme.eid);
                  } catch (e) {
                    if (kDebugMode) print('Theme set error: $e');
                  }
                  Navigator.pop(context);
                },
              ),

              const SizedBox(height: 12),

              _buildThemeOption(
                context,
                title: 'عام',
                icon: Icons.dashboard_customize,
                color: Colors.blue,
                gradient: const LinearGradient(
                  colors: [Color(0xFF2196F3), Color(0xFF673AB7)],
                ),
                onTap: () {
                  try {
                    WelcomeThemeController.to.setTheme(WelcomeTheme.general);
                  } catch (e) {
                    if (kDebugMode) print('Theme set error: $e');
                  }
                  Navigator.pop(context);
                },
              ),

              const SizedBox(height: 20),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'إلغاء',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required LinearGradient gradient,
    required void Function() onTap, // Fix method signature
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white70,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
