import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedProfileAvatar extends StatefulWidget {
  final String imagePath;
  final double size;
  final bool isNetworkImage;

  const AnimatedProfileAvatar({
    Key? key,
    required this.imagePath,
    this.size = 100,
    this.isNetworkImage = false,
  }) : super(key: key);

  @override
  State<AnimatedProfileAvatar> createState() => _AnimatedProfileAvatarState();
}

class _AnimatedProfileAvatarState extends State<AnimatedProfileAvatar>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _particleController;
  final List<Particle> particles = [];
  final random = math.Random();

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _particleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    // Initialize particles
    for (int i = 0; i < 12; i++) {
      particles.add(Particle(random));
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipOval(
        child: SizedBox(
          width: widget.size * 1.8, // Adjust the size multiplier as needed
          height: widget.size * 1.8,
          child: Center(
            child: AnimatedBuilder(
              animation: Listenable.merge(
                  [_rotationController, _pulseController, _particleController]),
              builder: (context, child) {
                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Particle effects
                    ...particles.map((particle) {
                      final progress =
                          (_particleController.value + particle.offset) % 1.0;
                      final size = particle.size * (1 - progress);
                      final opacity = (1 - progress) * 0.6;
                      final angle =
                          2 * math.pi * progress + particle.initialAngle;
                      final radius = widget.size * (0.6 + progress * 0.8);

                      return Positioned(
                        left:
                            (widget.size * 1.8 / 2) + radius * math.cos(angle),
                        top: (widget.size * 1.8 / 2) + radius * math.sin(angle),
                        child: Transform.rotate(
                          angle: angle,
                          child: Container(
                            width: size,
                            height: size,
                            decoration: BoxDecoration(
                              color: Color(0xFF3498DB).withOpacity(opacity),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF3498DB)
                                      .withOpacity(opacity * 0.5),
                                  blurRadius: size,
                                  spreadRadius: size * 0.5,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),

                    // Rotating rings with adjusted positioning
                    ...List.generate(3, (index) {
                      return Center(
                        child: Transform.rotate(
                          angle: _rotationController.value *
                              2 *
                              math.pi *
                              (index % 2 == 0 ? 1 : -1),
                          child: Container(
                            width: widget.size + (index * 20),
                            height: widget.size + (index * 20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Color(0xFF3498DB)
                                    .withOpacity(0.2 - (index * 0.05)),
                                width: 2,
                              ),
                              gradient: SweepGradient(
                                colors: [
                                  Color(0xFF3498DB).withOpacity(0.1),
                                  Color(0xFF3498DB).withOpacity(0.3),
                                  Color(0xFF3498DB).withOpacity(0.1),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),

                    // Center profile image
                    Center(
                      child: Container(
                        width: widget.size,
                        height: widget.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              Color(0xFF3498DB),
                              Color(0xFF2980B9),
                              Color(0xFF3498DB),
                            ],
                            transform: GradientRotation(
                                _rotationController.value * 2 * math.pi),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF3498DB).withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(4),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(widget.size),
                          child: widget.isNetworkImage
                              ? Image.network(
                                  widget.imagePath,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    print(
                                        'Error loading network image: $error');
                                    return Image.asset(
                                      'assets/images/owner.png',
                                      fit: BoxFit.cover,
                                    );
                                  },
                                )
                              : Image.asset(
                                  widget.imagePath,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class Particle {
  final double offset;
  final double size;
  final double initialAngle;

  Particle(math.Random random)
      : offset = random.nextDouble(),
        size = random.nextDouble() * 8 + 4,
        initialAngle = random.nextDouble() * 2 * math.pi;
}
