import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/services/backend/auth.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';
import 'package:phone_system_app/views/account_view.dart';
import 'package:phone_system_app/views/pages/login_page.dart';
import 'package:phone_system_app/controllers/account_details_controller.dart';

class WelcomeOverlay extends StatefulWidget {
  @override
  State<WelcomeOverlay> createState() => _WelcomeOverlayState();
}

class _WelcomeOverlayState extends State<WelcomeOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Auto dismiss after 3 seconds
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        _controller.reverse().then((_) => Navigator.of(context).pop());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountDetailsController = Get.put(AccountDetailsController());

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Material(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[200],
                          image: accountDetailsController.userImages.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(accountDetailsController
                                      .getLatestImageFromBucket() as String),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: accountDetailsController.userImages.isEmpty
                            ? Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey[400],
                              )
                            : null,
                      ),
                      SizedBox(height: 20),
                      Text(
                        ' النني مرحباً بك كابتن إسلام',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      Text(
                        'نتمنى لك يوماً سعيداً',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade700,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final SupabaseAuthentication controller = Get.put(SupabaseAuthentication());
  bool _hasShownWelcome = false;

  void _showWelcomeMessage(BuildContext context) {
    if (!_hasShownWelcome && SupabaseAuthentication.myUser?.role == 1) {
      _hasShownWelcome = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => WelcomeOverlay(),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (SupabaseAuthentication.userSession.value.accessToken != '') {
        _showWelcomeMessage(context);
        return AccountsView();
      }
      return LoginPage();
    });
  }
}
