import 'package:flutter/material.dart';
import 'dart:math' as math;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'نظام ادارة الهواتف',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Cairo',
      ),
      home: const EntryPage(),
    );
  }
}

class EntryPage extends StatefulWidget {
  const EntryPage({Key? key}) : super(key: key);

  @override
  State<EntryPage> createState() => _EntryPageState();
}

class _EntryPageState extends State<EntryPage> with TickerProviderStateMixin {
  late AnimationController _sheepController;
  late AnimationController _cloudController;
  late AnimationController _crescentController;
  late AnimationController _buttonController;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _sheepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);

    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _crescentController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      _buttonController.forward();
    });
  }

  @override
  void dispose() {
    _sheepController.dispose();
    _cloudController.dispose();
    _crescentController.dispose();
    _buttonController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            // Festive background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0F2E40),
                    Color(0xFF1A3B50),
                    Color(0xFF24485D),
                  ],
                ),
              ),
            ),

            // Stars
            CustomPaint(
              painter: StarsPainter(),
              size: Size.infinite,
            ),

            // Animated clouds
            ...List.generate(3, (index) {
              return AnimatedBuilder(
                animation: _cloudController,
                builder: (context, child) {
                  double offset = index * 0.3;
                  double position = (_cloudController.value + offset) % 1.0;

                  return Positioned(
                    left: position * MediaQuery.of(context).size.width * 1.5 -
                        100,
                    top: 50 + (index * 80),
                    child: Opacity(
                      opacity: 0.7,
                      child: Container(
                        width: 120,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),

            // Animated crescent moon
            Positioned(
              right: 40,
              top: 40,
              child: AnimatedBuilder(
                animation: _crescentController,
                builder: (context, child) {
                  return Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.amber.shade100,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.shade100.withOpacity(
                              0.5 + (_crescentController.value * 0.3)),
                          blurRadius: 15 + (_crescentController.value * 10),
                          spreadRadius: 5 + (_crescentController.value * 5),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.amber.shade100,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 15 + (_crescentController.value * 3),
                          top: 0,
                          child: Container(
                            width: 55,
                            height: 55,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF0F2E40),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Animated sheep
            ...List.generate(4, (index) {
              return AnimatedBuilder(
                animation: _sheepController,
                builder: (context, child) {
                  double offset = index * 0.2;
                  double position = (_sheepController.value + offset) % 1.0;

                  return Positioned(
                    left:
                        position * MediaQuery.of(context).size.width * 1.3 - 80,
                    bottom: 100 +
                        (index * 15) -
                        (math.sin(position * math.pi * 2) * 5),
                    child: SheepWidget(size: 60 + (index * 5).toDouble()),
                  );
                },
              );
            }),

            // Main content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // App title with fancy effect
                        ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return const LinearGradient(
                              colors: [
                                Colors.green,
                                Colors.amber,
                                Colors.green
                              ],
                              stops: [0.0, 0.5, 1.0],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds);
                          },
                          child: const Text(
                            'نظام ادارة الهواتف',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Festival subtitle
                        Text(
                          'مهرجان العيد المبارك',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.amber.shade300,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Login form card
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 400),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.green.shade900.withOpacity(0.8),
                                Colors.green.shade800.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Center(
                                child: Text(
                                  'تسجيل الدخول',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 25),

                              // Username field
                              const Text(
                                'اسم المستخدم',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _usernameController,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.2),
                                  prefixIcon: const Icon(Icons.person,
                                      color: Colors.white70),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  hintText: 'أدخل اسم المستخدم',
                                  hintStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.7)),
                                ),
                                style: const TextStyle(color: Colors.white),
                              ),

                              const SizedBox(height: 20),

                              // Password field
                              const Text(
                                'كلمة المرور',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.2),
                                  prefixIcon: const Icon(Icons.lock,
                                      color: Colors.white70),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  hintText: 'أدخل كلمة المرور',
                                  hintStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.7)),
                                ),
                                style: const TextStyle(color: Colors.white),
                              ),

                              const SizedBox(height: 30),

                              // Login button with animation
                              Center(
                                child: AnimatedBuilder(
                                  animation: _buttonController,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale:
                                          0.5 + (_buttonController.value * 0.5),
                                      child: Opacity(
                                        opacity: _buttonController.value,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            // Add login logic
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.amber.shade600,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 40, vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                            ),
                                            elevation: 5,
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.login),
                                              SizedBox(width: 8),
                                              Text(
                                                'دخول',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              const SizedBox(height: 15),

                              // Forgot password
                              Center(
                                child: TextButton(
                                  onPressed: () {},
                                  child: Text(
                                    'نسيت كلمة المرور؟',
                                    style: TextStyle(
                                      color: Colors.amber.shade300,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Festival message
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade800.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.amber.shade600.withOpacity(0.5)),
                          ),
                          child: Text(
                            'عيد مبارك سعيد! 🌙✨',
                            style: TextStyle(
                              color: Colors.amber.shade300,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Sheep Widget
class SheepWidget extends StatelessWidget {
  final double size;

  const SheepWidget({Key? key, this.size = 60}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Changed Container to SizedBox
      width: size,
      height: size,
      child: Stack(
        children: [
          // Sheep body
          Positioned(
            left: size * 0.1,
            top: size * 0.3,
            child: Container(
              width: size * 0.8,
              height: size * 0.5,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(size * 0.25),
              ),
            ),
          ),

          // Sheep wool (fluffy parts)
          ...List.generate(8, (index) {
            final angle = index * (math.pi / 4);
            final xOffset = math.cos(angle) * (size * 0.2);
            final yOffset = math.sin(angle) * (size * 0.2);

            return Positioned(
              left: (size / 2 - size * 0.15) + xOffset,
              top: (size * 0.4 - size * 0.15) + yOffset,
              child: Container(
                width: size * 0.3,
                height: size * 0.3,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),

          // Head
          Positioned(
            left: size * 0.65,
            top: size * 0.2,
            child: Container(
              width: size * 0.25,
              height: size * 0.25,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(size * 0.125),
              ),
            ),
          ),

          // Eyes
          Positioned(
            left: size * 0.75,
            top: size * 0.25,
            child: Container(
              width: size * 0.05,
              height: size * 0.05,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Legs
          Positioned(
            left: size * 0.25,
            top: size * 0.8,
            child: Container(
              width: size * 0.1,
              height: size * 0.2,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(size * 0.05),
              ),
            ),
          ),
          Positioned(
            left: size * 0.65,
            top: size * 0.8,
            child: Container(
              width: size * 0.1,
              height: size * 0.2,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(size * 0.05),
              ),
            ),
          ),

          // Ears
          Positioned(
            left: size * 0.7,
            top: size * 0.15,
            child: Container(
              width: size * 0.12,
              height: size * 0.12,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(size * 0.06),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Stars Painter
class StarsPainter extends CustomPainter {
  final List<Star> stars = List.generate(100, (index) => Star());

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (final star in stars) {
      final starPath = Path();
      final centerX = star.x * size.width;
      final centerY = star.y * size.height;
      final outerRadius = star.size;
      final innerRadius = outerRadius * 0.4;

      for (int i = 0; i < 10; i++) {
        final angle = math.pi / 5 * i;
        final radius = i.isEven ? outerRadius : innerRadius;
        final x = centerX + math.cos(angle) * radius;
        final y = centerY + math.sin(angle) * radius;

        if (i == 0) {
          starPath.moveTo(x, y);
        } else {
          starPath.lineTo(x, y);
        }
      }

      starPath.close();
      canvas.drawPath(
          starPath, paint..color = Colors.white.withOpacity(star.opacity));
    }
  }

  @override
  bool shouldRepaint(StarsPainter oldDelegate) => false;
}

class Star {
  final double x = math.Random().nextDouble();
  final double y = math.Random().nextDouble();
  final double size = math.Random().nextDouble() * 2 + 1;
  final double opacity = math.Random().nextDouble() * 0.7 + 0.3;
}
