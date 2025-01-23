import 'dart:math';
import 'dart:async';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:phone_system_app/controllers/account_client_info_data.dart';
import 'package:phone_system_app/controllers/account_profit_controller.dart';
import 'package:phone_system_app/controllers/account_view_controller.dart';
import 'package:phone_system_app/models/account.dart';
import 'package:phone_system_app/services/backend/backend_services.dart';
import 'package:phone_system_app/views/account_details.dart';
import 'package:phone_system_app/views/pages/charts_page.dart';
import 'package:phone_system_app/views/pages/table_page.dart';

class AccountsView extends StatelessWidget {
  AccountsView({super.key});
  final controller = Get.put(AccountViewController());

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    double screenWidth = size.width;
    double minWidth = 200;

    return Obx(() {
      final data = controller.getCurrentAccounts();
      
      // Determine if we should use vertical layout
      final bool useVerticalLayout = data.length == 2;

      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          centerTitle: true,
          title: const Text("الاكونتات المتاحة"),
          actions: [
            IconButton(
              tooltip: "تسجيل الخروج",
              onPressed: () async {
                await BackendServices.instance.supabaseAuthentication.signOut();
                html.window.location.reload();
              },
              icon: const Icon(
                Icons.door_back_door,
                color: Colors.red,
              ),
            ),
            IconButton(
              tooltip: "اظهار بينات العملاء",
              onPressed: () {
                Get.to(InfoTablePage());
              },
              icon: const Icon(
                Icons.table_chart,
                color: Colors.blue,
              ),
            ),
          ],
          leading: IconButton(
            onPressed: () {
              Get.to(ChartsPage());
            },
            icon: const Icon(
              FontAwesomeIcons.chartPie,
              color: Colors.red,
            ),
          ),
        ),
        body: (controller.isLoading.value)
            ? Center(child: CircularProgressIndicator())
            : useVerticalLayout
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: data.map((account) {
                        return SizedBox(
                          width: screenWidth * 0.8, // 80% of screen width
                          height: size.height * 0.35, // 35% of screen height
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: AccountCard(
                              width: screenWidth * 0.8,
                              account: account,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  )
                : GridView.builder(
                    itemCount: data.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          max((screenWidth ~/ minWidth != 0) ? screenWidth ~/ minWidth : 1, 2),
                      childAspectRatio: 1.1,
                    ),
                    itemBuilder: (context, index) {
                      double cardWidth = screenWidth / max((screenWidth ~/ minWidth != 0) ? screenWidth ~/ minWidth : 1, 2);
                      return Padding(
                        padding: const EdgeInsets.all(10),
                        child: AccountCard(
                          width: cardWidth,
                          account: data[index],
                        ),
                      );
                    },
                  ),
      );
    });
  }
}

class AccountCard extends StatefulWidget {
  final Account account;
  final double width;

  AccountCard({super.key, required this.width, required this.account});

  @override
  _AccountCardState createState() => _AccountCardState();
}

class _AccountCardState extends State<AccountCard> with TickerProviderStateMixin {
  bool _isHovered = false;
  bool _isNavigating = false;
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _particleController;
  final List<Particle> particles = [];
  Timer? _particleTimer;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _particleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();

    // Generate particles periodically when hovered
    _particleTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (_isHovered && mounted) {
        setState(() {
          if (particles.length < 10) {
            particles.add(Particle(
              position: Offset(
                Random().nextDouble() * 60 - 30, // Centered spread
                Random().nextDouble() * 60 - 30, // Centered spread
              ),
              velocity: Offset(
                Random().nextDouble() * 2 - 1,
                Random().nextDouble() * 2 - 1,
              ),
            ));
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    _particleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Get.theme.colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) {
        setState(() {
          _isHovered = false;
          particles.clear();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: _isHovered ? Colors.black45 : Colors.black38,
              blurRadius: _isHovered ? 8 : 2,
              blurStyle: BlurStyle.outer,
              spreadRadius: _isHovered ? 4 : 2
            )
          ]
        ),
        child: Stack(
          children: [
            // Centered floating main icon
            AnimatedBuilder(
              animation: _mainController,
              builder: (context, child) {
                return Center(
                  child: Transform.translate(
                    offset: Offset(
                      cos(_mainController.value * 2 * pi) * 5,
                      sin(_mainController.value * 2 * pi) * 10,
                    ),
                    child: Transform.rotate(
                      angle: sin(_mainController.value * pi) * 0.1,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Pulse effect
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: 1.0 + sin(_pulseController.value * pi) * 0.2,
                                child: ShaderMask(
                                  shaderCallback: (Rect bounds) {
                                    return LinearGradient(
                                      colors: [
                                        Colors.blue.withOpacity(_isHovered ? 1 : 0.5),
                                        Colors.purple.withOpacity(_isHovered ? 1 : 0.5),
                                      ],
                                      stops: const [0.0, 1.0],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ).createShader(bounds);
                                  },
                                  child: const Icon(
                                    Icons.account_balance,
                                    size: 60, // Slightly larger size
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                          ),
                          
                          // Centered particles
                          if (_isHovered)
                            ...particles.map((particle) {
                              return AnimatedBuilder(
                                animation: _particleController,
                                builder: (context, child) {
                                  particle.update();
                                  return Transform.translate(
                                    offset: Offset(
                                      particle.position.dx - 30, // Adjust for center
                                      particle.position.dy - 30, // Adjust for center
                                    ),
                                    child: Opacity(
                                      opacity: (1 - _particleController.value),
                                      child: Container(
                                        width: 4,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.blue.withOpacity(0.6),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              bottom: 0,
              left: -5,
              child: Container(
                width: widget.width,
                height: 50,
                decoration: BoxDecoration(
                  color: colors.background,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  )
                ),
                child: Center(
                  child: Text(
                    widget.account.name!,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              )
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(width: 1.5, color: Colors.black87)
                ),
              )
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  overlayColor: MaterialStateProperty.all(Colors.black87.withAlpha(10)),
                  focusColor: Colors.green,
                  hoverColor: Colors.white,
                  onTap: () async {
                    if (_isNavigating) return; // Prevent multiple taps
                    _isNavigating = true; // Set navigating state

                    // Delay the reset of the navigation state to ensure navigation happens first
                    Future.delayed(const Duration(milliseconds: 300), () {
                      _isNavigating = false; // Reset navigating state after the navigation
                    });

                    // Ensure we don't navigate to the same page again
                    if (Get.currentRoute != '/accountDetails') {
                      Get.put(AccountClientInfo(currentAccount: widget.account));
                      final p = Get.put(ProfitController());
                      await p.updateTheProfitByAccount(widget.account);

                      // Navigate to AccountDetails
                      Get.to(AccountDetails(), arguments: widget.account);
                    }
                  },
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Particle {
  Offset position;
  Offset velocity;
  
  Particle({
    required this.position,
    required this.velocity,
  });

  void update() {
    position += velocity;
    velocity += const Offset(0, 0.1); // Add gravity effect
  }
}
