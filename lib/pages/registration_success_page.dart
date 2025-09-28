import 'dart:math';

import 'package:flutter/material.dart';

import 'home_page.dart';

class SuccessRegistrationPage extends StatefulWidget {
  const SuccessRegistrationPage({super.key});

  @override
  State<SuccessRegistrationPage> createState() => _SuccessRegistrationPageState();
}

class _SuccessRegistrationPageState extends State<SuccessRegistrationPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<Color?> _gradientAnimation;
  late Animation<double> _particleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // FIXED: Use simple Tween instead of TweenSequence for scale animation
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _rotateAnimation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );

    _gradientAnimation = ColorTween(
      begin: const Color(0xFFFEC8D8),
      end: const Color(0xFFFFE9A7),
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
      ),
    );

    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );

    // Start animations after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToNext() {
    // Button press animation
    _animationController.reverse().then((_) {
      // Add your navigation logic here
       Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6EC),
      body: Stack(
        children: [
          // Animated background particles
          _buildParticles(),

          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Top celebration emoji with scale and rotation
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      // FIXED: Use separate scale animation without TweenSequence
                      final scaleValue = _scaleAnimation.value;
                      final rotateValue = _rotateAnimation.value * 0.5;

                      return Transform(
                        transform: Matrix4.identity()
                          ..scale(scaleValue)
                          ..rotateZ(rotateValue),
                        alignment: Alignment.center,
                        child: child,
                      );
                    },
                    child: const Text(
                      "🎉",
                      style: TextStyle(fontSize: 60),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Thumbs up emoji with bouncing animation - FIXED: Use simple scale
                  AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      // Add bounce effect manually
                      double scale = _scaleAnimation.value;
                      if (scale > 1.0) {
                        scale = 1.0 + (scale - 1.0) * 0.3; // Reduce overshoot
                      }

                      return Transform.scale(
                        scale: scale,
                        child: child,
                      );
                    },
                    child: const Text(
                      "👍✨",
                      style: TextStyle(fontSize: 80),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Success message with slide and fade animation
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.5),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: const Interval(0.4, 0.8, curve: Curves.easeOutBack),
                      ),
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: const Text(
                        "تم التسجيل بنجاح",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.deepPurple,
                          fontFamily: 'Tajawal',
                          shadows: [
                            Shadow(
                              blurRadius: 10.0,
                              color: Colors.black12,
                              offset: Offset(2.0, 2.0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Subtitle with animation
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.3),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: const Interval(0.5, 0.9, curve: Curves.easeOut),
                      ),
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: const Text(
                        "مبروك! أنت الآن جزء من عائلة حكايا الأبطال",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.deepPurple,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Animated follow button
                  ScaleTransition(
                    scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: const Interval(0.6, 1.0, curve: Curves.elasticOut),
                      ),
                    ),
                    child: FadeTransition(
                      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
                        ),
                      ),
                      child: _AnimatedGradientButton(
                        animation: _gradientAnimation,
                        onPressed: _navigateToNext,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Bottom celebration emoji with continuous animation
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      // FIXED: Use safe animation values
                      final scale = 1.0 + (_animationController.value * 0.1).clamp(0.0, 1.1);
                      final rotate = (_animationController.value * 0.2).clamp(-0.2, 0.2);

                      return Transform(
                        transform: Matrix4.identity()
                          ..scale(scale)
                          ..rotateZ(rotate),
                        alignment: Alignment.center,
                        child: child,
                      );
                    },
                    child: const Text(
                      "🎊",
                      style: TextStyle(fontSize: 50),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Floating confetti animation - FIXED: Use safe values
                  _buildConfetti(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticles() {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _particleAnimation,
        builder: (context, child) {
          return CustomPaint(
            painter: _ParticlesPainter(_particleAnimation),
            size: Size.infinite,
          );
        },
      ),
    );
  }

  Widget _buildConfetti() {
    return SizedBox(
      height: 100,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          // FIXED: Use clamped values to stay within safe range
          final animationValue = _animationController.value.clamp(0.0, 1.0);

          return Stack(
            children: [
              for (int i = 0; i < 5; i++)
                Positioned(
                  left: i * 70.0,
                  top: sin(animationValue * 2 * 3.14 + i) * 30,
                  child: Transform.rotate(
                    angle: animationValue * 2 * 3.14,
                    child: Text(
                      i % 2 == 0 ? "🎊" : "✨",
                      style: TextStyle(
                        fontSize: 24 + i * 2,
                        color: [
                          Colors.amber,
                          Colors.red,
                          Colors.green,
                          Colors.blue,
                          Colors.purple,
                        ][i].withOpacity(0.8),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AnimatedGradientButton extends StatelessWidget {
  final Animation<Color?> animation;
  final VoidCallback onPressed;

  const _AnimatedGradientButton({
    required this.animation,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        // FIXED: Add null check and fallback color
        final color = animation.value ?? const Color(0xFFFEC8D8);

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: 200,
            height: 55,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                colors: [
                  color,
                  const Color(0xFFFFE9A7),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 30),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_forward, color: Colors.black87, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "المُتابعة",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ParticlesPainter extends CustomPainter {
  final Animation<double> animation;

  _ParticlesPainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    // FIXED: Use clamped animation value
    final animValue = animation.value.clamp(0.0, 1.0);

    final paint = Paint()
      ..color = Colors.amber.withOpacity(0.1 * animValue)
      ..style= PaintingStyle.fill;

    // Draw floating particles around the Page
    for (int i = 0; i < 8; i++) {
    final x = size.width * 0.1 + (i * size.width * 0.12);
    final y = size.height * 0.2 + sin(animValue * 2 * 3.14 + i) * 40;
    canvas.drawCircle(Offset(x, y), 2 * animValue, paint);
    }

    // Draw more particles
    for (int i = 0; i < 6; i++) {
    final x = size.width * 0.15 + (i * size.width * 0.15);
    final y = size.height * 0.8 + cos(animValue * 2 * 3.14 + i) * 30;
    canvas.drawCircle(Offset(x, y), 1.5 * animValue, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}