import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:phone_system_app/firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:phone_system_app/repositories/system/supabase_system_repository.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';
import 'package:phone_system_app/services/fcm_service.dart';
import 'package:phone_system_app/services/transaction_notification_service.dart';
import 'package:phone_system_app/controllers/update_controller.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/theme/welcome_theme_selector.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@pragma('vm:entry-point')
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Web-specific initialization
  if (kIsWeb) {
    FlutterError.onError = (FlutterErrorDetails details) {
      if (kDebugMode) {
        debugPrint('Web error: ${details.exception}');
      }
    };

    // Skip mobile-only initialization
    if (kDebugMode) {
      debugPrint('Running on web - mobile services disabled');
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
        debugPrint('Mobile setup failed: $e');
      }
    }
  }

  // Initialize theme controller with web-safe approach
  try {
    Get.put(WelcomeThemeController());
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Theme controller failed: $e');
    }
  }

  // Web-safe image cache setup
  if (!kIsWeb) {
    try {
      PaintingBinding.instance.imageCache.maximumSize = 100;
      PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Image cache setup failed: $e');
      }
    }
  }

  // Initialize services with error handling
  try {
    await BackendServices.instance.initialize();
    Get.put(SupabaseSystemRepository());
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Services initialization failed: $e');
    }
  }

  // Initialize notification service
  try {
    if (kIsWeb) {
      // Web: Initialize Firebase only (no FCM)
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('✅ Firebase initialized for Web');
    } else {
      // Mobile: Initialize Firebase + FCM + Notifications
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await FcmService.instance.initialize();
      await TransactionNotificationService.instance.initialize();

      // ✅ Auto-register FCM token on app start
      try {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          debugPrint('🔔 FCM Token obtained: ${token.substring(0, 20)}...');

          // Register token in database automatically
          final supabase = Supabase.instance.client;
          await supabase.from('fcm_tokens').upsert({
            'device': 'manager',
            'token': token,
            'updated_at': DateTime.now().toIso8601String(),
          });

          debugPrint('✅ FCM Token registered automatically in database');
        } else {
          debugPrint('⚠️ FCM Token is null');
        }

        // ✅ Listen for token refresh (when token changes)
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
          debugPrint('🔔 FCM Token refreshed: ${newToken.substring(0, 20)}...');

          try {
            final supabase = Supabase.instance.client;
            await supabase.from('fcm_tokens').upsert({
              'device': 'manager',
              'token': newToken,
              'updated_at': DateTime.now().toIso8601String(),
            });

            debugPrint('✅ New FCM Token registered in database');
          } catch (e) {
            debugPrint('❌ Error registering refreshed token: $e');
          }
        });
      } catch (e) {
        debugPrint('❌ Error auto-registering FCM token: $e');
      }

      debugPrint('✅ Firebase, FCM, and Notifications initialized for Mobile');

      // ✅ Check for Shorebird updates automatically
      _checkForShorebirdUpdate();
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ Initialization failed: $e');
    }
  }

  runApp(const MainApp());
}

/// Check for Shorebird updates and download silently in background
/// Check for Shorebird updates and download silently in background
Future<void> _checkForShorebirdUpdate() async {
  try {
    // Import the service dynamically to avoid issues
    final updateService = Get.put(UpdateController());

    // Check silently in background
    await updateService.checkAndDownloadSilently();
  } catch (e) {
    debugPrint('🔄 Shorebird: Error in background check: $e');
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = const ColorScheme.light(
            surface: Colors.black87, brightness: Brightness.dark)
        .copyWith(
      primary: Colors.white54,
      onPrimary: Colors.greenAccent,
      secondary: Colors.blueAccent,
      onSurface: Colors.black,
      surface: Colors.red,
      surfaceTint: const Color.fromARGB(255, 249, 249, 249),
      error: const Color(0xFFd62828),
    );

    final textTheme = Theme.of(context).textTheme.apply(
          fontFamily: "Cairo",
          bodyColor: Colors.black,
          displayColor: colorScheme.onSurface,
          decorationColor: colorScheme.onSurface,
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
          headerBackgroundColor: colorScheme.surface,
          cancelButtonStyle:
              ElevatedButton.styleFrom(backgroundColor: Colors.black),
          confirmButtonStyle:
              ElevatedButton.styleFrom(backgroundColor: Colors.red),
          dividerColor: colorScheme.surface,
        ),
        splashFactory: kIsWeb ? NoSplash.splashFactory : null,
      ),
      home: Stack(
        children: [
          GetX<WelcomeThemeController>(
            builder: (controller) {
              try {
                return controller.getCurrentWelcomePage();
              } catch (e) {
                return const _ErrorFallbackWidget();
              }
            },
          ),
          const Positioned(
            top: 40,
            right: 16,
            child: _ThemeSelectorButton(),
          ),
        ],
      ),
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 150),
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      popGesture: true,
      enableLog: false,
      opaqueRoute: true,
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: const _CustomScrollBehavior(),
          child: child!,
        );
      },
    );
  }

  static void showThemeSelector(BuildContext context) {
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
                    if (kDebugMode) debugPrint('Theme set error: $e');
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
                    if (kDebugMode) debugPrint('Theme set error: $e');
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
                    if (kDebugMode) debugPrint('Theme set error: $e');
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

  static Widget _buildThemeOption(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required LinearGradient gradient,
    required VoidCallback onTap,
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
              color: color.withValues(alpha: 0.3),
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

// Optimized Custom Widgets
class _ErrorFallbackWidget extends StatelessWidget {
  const _ErrorFallbackWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue,
      child: const Center(
        child: Text(
          'مرحباً',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
    );
  }
}

class _ThemeSelectorButton extends StatelessWidget {
  const _ThemeSelectorButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.palette_outlined, color: Colors.white),
      onPressed: () => MainApp.showThemeSelector(context),
    );
  }
}

class _CustomScrollBehavior extends ScrollBehavior {
  const _CustomScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}
