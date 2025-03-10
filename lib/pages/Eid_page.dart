import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'package:phone_system_app/views/pages/auth_raper.dart';
import 'package:phone_system_app/views/pages/login_page.dart';
import 'package:audioplayers/audioplayers.dart';

class WelcomePage extends StatefulWidget {
  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _backgroundController;
  late AnimationController _floatingController;
  late AnimationController _sheepController;
  late AnimationController _crescentController;
  late AnimationController _cloudsController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _sheepSlideAnimation;
  late Animation<double> _sheepScaleAnimation;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<Star> _stars = [];
  final List<Cloud> _clouds = [];
  final List<Sheep> _sheepFlock = [];
  bool _showJumpingSheep = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateStars();
    _generateClouds();
    _generateSheep();
  }

  void _initializeAnimations() {
    _controller = AnimationController(
        duration: Duration(milliseconds: 1500), vsync: this);

    _backgroundController = AnimationController(
        duration: Duration(seconds: 20), vsync: this)
      ..repeat();

    _floatingController =
        AnimationController(duration: Duration(seconds: 2), vsync: this)
          ..repeat(reverse: true);

    _sheepController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );

    _crescentController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _cloudsController = AnimationController(
      duration: Duration(seconds: 30),
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.3, 0.8, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _sheepSlideAnimation = Tween<Offset>(
      begin: Offset(-1, 0.3),
      end: Offset(1.5, 0.3),
    ).animate(CurvedAnimation(
      parent: _sheepController,
      curve: Curves.easeInOut,
    ));

    _sheepScaleAnimation = Tween<double>(
      begin: 1.2,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _sheepController,
      curve: Interval(0.2, 0.8, curve: Curves.elasticInOut),
    ));

    _controller.forward();

    // Start sheep movement animations
    Future.delayed(Duration(milliseconds: 500), () {
      for (var sheep in _sheepFlock) {
        sheep.startMoving();
      }
    });
  }

  void _generateStars() {
    final random = math.Random();
    for (int i = 0; i < 70; i++) {
      _stars.add(Star(random));
    }
  }

  void _generateClouds() {
    final random = math.Random();
    for (int i = 0; i < 6; i++) {
      _clouds.add(Cloud(random));
    }
  }

  void _generateSheep() {
    final random = math.Random();
    for (int i = 0; i < 5; i++) {
      _sheepFlock.add(Sheep(random, this));
    }
  }

  void _startJumpingSheepAnimation() async {
    setState(() => _showJumpingSheep = true);
    await _sheepController.forward();
    setState(() => _showJumpingSheep = false);
    _sheepController.reset();
  }

  @override
  void dispose() {
    _controller.dispose();
    _backgroundController.dispose();
    _floatingController.dispose();
    _sheepController.dispose();
    _crescentController.dispose();
    _cloudsController.dispose();
    _audioPlayer.dispose();
    for (var sheep in _sheepFlock) {
      sheep.dispose();
    }
    super.dispose();
  }

  Future<void> _playButtonSound() async {
    await _audioPlayer.play(AssetSource('sounds/button_click.wav'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundController,
        builder: (context, child) {
          return Stack(
            children: [
              // Sky background with gradient
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF1A237E), // Deep blue for sky
                      Color(0xFF3949AB), // Lighter blue
                      Color(0xFF5C6BC0), // Even lighter blue for horizon
                    ],
                  ),
                ),
              ),
              
              // Stars in the sky
              ..._stars.map((star) {
                final progress = (_backgroundController.value + star.offset) % 1.0;
                return Positioned(
                  left: star.x * MediaQuery.of(context).size.width,
                  top: star.y * MediaQuery.of(context).size.height * 0.7, // Only in upper 70% of screen
                  child: Opacity(
                    opacity: star.brightness * (0.3 + 0.7 * math.sin(progress * math.pi)),
                    child: Container(
                      width: star.size,
                      height: star.size,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.7),
                            blurRadius: star.size,
                            spreadRadius: star.size * 0.2,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
              
              // Green hill at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: MediaQuery.of(context).size.height * 0.3,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF388E3C), // Medium green
                        Color(0xFF2E7D32), // Darker green
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(80),
                      topRight: Radius.circular(80),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 15,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Animated clouds
              ..._clouds.map((cloud) {
                return Positioned(
                  left: ((cloud.x + _cloudsController.value) % 1.2 - 0.1) * 
                      MediaQuery.of(context).size.width,
                  top: cloud.y * MediaQuery.of(context).size.height * 0.5,
                  child: Opacity(
                    opacity: cloud.opacity,
                    child: _buildCloud(cloud.scale),
                  ),
                );
              }).toList(),
              
              // Grazing sheep
              ..._sheepFlock.map((sheep) {
                return AnimatedBuilder(
                  animation: sheep.controller,
                  builder: (context, child) {
                    return Positioned(
                      left: (sheep.x + sheep.moveAnimation.value * 0.1) * 
                          MediaQuery.of(context).size.width,
                      bottom: sheep.y * MediaQuery.of(context).size.height * 0.2 + 20,
                      child: Transform.scale(
                        scale: 0.8 + sheep.hopAnimation.value * 0.2,
                        child: Transform.translate(
                          offset: Offset(0, -sheep.hopAnimation.value * 10),
                          child: _buildSheep(),
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
                
              // Main content
              SafeArea(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _crescentController,
                          builder: (context, child) {
                            return Container(
                              height: 180,
                              width: 180,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Crescent moon or Eid symbol
                                  Transform.scale(
                                    scale: 1.0 + _crescentController.value * 0.05,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.amber.shade300,
                                            Colors.amber.shade600,
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.amber.withOpacity(0.3),
                                            blurRadius: 20,
                                            spreadRadius: 5,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.phone_android,
                                    size: 80,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 48),
                        SlideTransition(
                          position: _slideAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Column(
                              children: [
                                Text(
                                  'عيد مبارك',
                                  style: TextStyle(
                                    fontSize: 52,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade300,
                                    shadows: [
                                      Shadow(
                                        color: Colors.amber.withOpacity(0.8),
                                        blurRadius: 15,
                                        offset: Offset(0, 5),
                                      ),
                                      Shadow(
                                        color: Colors.amber.withOpacity(0.4),
                                        blurRadius: 25,
                                        offset: Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'نظام إدارة الهواتف',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: Colors.white.withOpacity(0.9),
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 48),
                        SlideTransition(
                          position: _slideAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Column(
                              children: [
                                _buildGlassButton(
                                  'ابدأ الآن',
                                  onPressed: () async {
                                    await _playButtonSound();
                                    _startJumpingSheepAnimation();
                                    _controller.reverse().then((_) {
                                      Get.off(() => AuthRaper());
                                    });
                                  },
                                ),
                                SizedBox(height: 24),
                                _buildTextButton(
                                  'لديك حساب بالفعل؟ سجل دخول',
                                  onPressed: () async {
                                    await _playButtonSound();
                                    _controller.reverse().then((_) {
                                      Get.off(() => LoginPage());
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Jumping sheep animation (shown on button press)
              if (_showJumpingSheep)
                AnimatedBuilder(
                  animation: _sheepController,
                  builder: (context, child) {
                    final size = MediaQuery.of(context).size;
                    return Positioned(
                      left: size.width * 0.5 - 75,
                      bottom: size.height * 0.3,
                      child: Transform.translate(
                        offset: _sheepSlideAnimation.value * size.width * 0.5,
                        child: Transform.scale(
                          scale: _sheepScaleAnimation.value,
                          child: Opacity(
                            opacity: 1 - (_sheepController.value * 0.5),
                            child: _buildJumpingSheep(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGlassButton(String text, {required VoidCallback onPressed}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: Colors.white.withOpacity(0.2),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextButton(String text, {required VoidCallback onPressed}) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontSize: 16,
          decoration: TextDecoration.underline,
          decorationColor: Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildCloud(double scale) {
    return Container(
      width: 120 * scale,
      height: 60 * scale,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 30 * scale,
            top: 10 * scale,
            child: Container(
              width: 50 * scale,
              height: 50 * scale,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 5 * scale,
            top: 20 * scale,
            child: Container(
              width: 40 * scale,
              height: 40 * scale,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 60 * scale,
            top: 15 * scale,
            child: Container(
              width: 45 * scale,
              height: 45 * scale,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSheep() {
    return Container(
      width: 70,
      height: 60,
      child: Stack(
        children: [
          // Sheep Body
          Positioned(
            top: 15,
            child: Container(
              width: 60,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          
          // Sheep Wool (fluffy texture)
          ..._generateWoolPuffs(),
          
          // Sheep Head
          Positioned(
            left: 5,
            top: 10,
            child: Container(
              width: 25,
              height: 25,
              decoration: BoxDecoration(
                color: Color(0xFF424242),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          
          // Sheep Eyes
          Positioned(
            left: 10,
            top: 15,
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          // Sheep Legs
          Positioned(
            left: 15,
            bottom: 0,
            child: Container(
              width: 4,
              height: 15,
              color: Color(0xFF616161),
            ),
          ),
          Positioned(
            left: 45,
            bottom: 0,
            child: Container(
              width: 4,
              height: 15,
              color: Color(0xFF616161),
            ),
          ),
        ],
      ),
    );
  }
  
  List<Widget> _generateWoolPuffs() {
    List<Widget> puffs = [];
    final random = math.Random(42); // Fixed seed for consistent look
    
    for (int i = 0; i < 12; i++) {
      double left = random.nextDouble() * 45 + 10;
      double top = random.nextDouble() * 20 + 5;
      double size = random.nextDouble() * 10 + 12;
      
      puffs.add(
        Positioned(
          left: left,
          top: top,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.8),
                  blurRadius: 2,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return puffs;
  }

  Widget _buildJumpingSheep() {
    return Transform.scale(
      scale: 1.8,
      child: Container(
        width: 100,
        height: 80,
        child: Stack(
          children: [
            // Jumping Sheep Body
            Positioned(
              top: 15,
              left: 20,
              child: Container(
                width: 60,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
            
            // Jumping Sheep Wool (more fluffy)
            ..._generateWoolPuffs().map((puff) => 
              Transform.scale(
                scale: 1.2,
                child: puff,
              )
            ).toList(),
            
            // Jumping Sheep Head
            Positioned(
              left: 15,
              top: 10,
              child: Container(
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  color: Color(0xFF424242),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
            
            // Jumping Sheep Eyes
            Positioned(
              left: 20,
              top: 15,
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            
            // Jumping Sheep Legs (tucked up for jumping)
            Positioned(
              left: 30,
              bottom: 5,
              child: Container(
                width: 4,
                height: 10,
                color: Color(0xFF616161),
                transform: Matrix4.rotationZ(0.5),
              ),
            ),
            Positioned(
              left: 60,
              bottom: 5,
              child: Container(
                width: 4,
                height: 10,
                color: Color(0xFF616161),
                transform: Matrix4.rotationZ(-0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Star {
  final double x;
  final double y;
  final double size;
  final double offset;
  final double brightness;

  Star(math.Random random)
      : x = random.nextDouble(),
        y = random.nextDouble(),
        size = random.nextDouble() * 2.5 + 0.5,
        offset = random.nextDouble(),
        brightness = random.nextDouble() * 0.5 + 0.5;
}

class Cloud {
  final double x;
  final double y;
  final double scale;
  final double opacity;

  Cloud(math.Random random)
      : x = random.nextDouble(),
        y = random.nextDouble() * 0.4,
        scale = random.nextDouble() * 0.5 + 0.8,
        opacity = random.nextDouble() * 0.3 + 0.7;
}

class Sheep {
  late double x;
  late double y;
  late AnimationController controller;
  late Animation<double> moveAnimation;
  late Animation<double> hopAnimation;
  final math.Random _random;
  final TickerProvider _vsync;
  
  Sheep(this._random, this._vsync)
      : x = _random.nextDouble() * 0.7 + 0.1,
        y = _random.nextDouble() * 0.7 {
    controller = AnimationController(
      duration: Duration(seconds: 5 + (_random.nextInt(5))),
      vsync: _vsync,
    );
    
    moveAnimation = Tween<double>(
      begin: -0.1,
      end: 0.1,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ),
    );
    
    hopAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(0.4, 0.6, curve: Curves.easeInOut),
      ),
    );
  }
  
  void startMoving() {
    controller.repeat(reverse: true);
  }
  
  void dispose() {
    controller.dispose();
  }
}