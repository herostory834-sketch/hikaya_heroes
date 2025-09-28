// pages/login_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hikaya_heroes/pages/admin_dashboard.dart';
import 'package:hikaya_heroes/services/firebase_service.dart';
import 'package:hikaya_heroes/widgets/reusable_widgets.dart';
import 'package:hikaya_heroes/pages/home_page.dart';
import 'package:hikaya_heroes/pages/signup_page.dart';
import '../utils/constants.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<Offset> _titleSlideAnimation;
  late Animation<Color?> _buttonColorAnimation;

  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.1, 0.6, curve: Curves.elasticOut),
      ),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.bounceOut),
      ),
    );

    _titleSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _buttonColorAnimation = ColorTween(
      begin: Constants.kPrimaryColor.withOpacity(0.5),
      end: Constants.kPrimaryColor,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorSnackBar("الرجاء إدخال البريد الإلكتروني وكلمة المرور");
      return;
    }

    setState(() => _isLoading = true);

    // Button press animation
    await _animationController.reverse();
    await _animationController.forward();

    try {
      User? user= await _firebaseService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      // Success animation before navigation
      await _playSuccessAnimation();
      if (user != null) {
        bool isAdmin = await _firebaseService.isAdmin(user.uid);

        if (isAdmin) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const AdminDashboard(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 1.1, end: 1.0).animate(
                      CurvedAnimation(parent: animation, curve: Curves.easeOut),
                    ),
                    child: child,
                  ),
                );
              },
              transitionDuration: const Duration(milliseconds: 800),
            ),
          );

        } else {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const HomePage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 1.1, end: 1.0).animate(
                      CurvedAnimation(parent: animation, curve: Curves.easeOut),
                    ),
                    child: child,
                  ),
                );
              },
              transitionDuration: const Duration(milliseconds: 800),
            ),
          );

        }
      }
    } on FirebaseAuthException catch (e) {
      await _playErrorAnimation();
      _handleFirebaseError(e);
    } catch (e) {
      await _playErrorAnimation();
      _showErrorSnackBar("حدث خطأ غير متوقع: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _playSuccessAnimation() async {
    await _animationController.animateTo(0.8, duration: const Duration(milliseconds: 200));
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _playErrorAnimation() async {
    final shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    final shakeAnimation = Tween<double>(begin: 0, end: 15).animate(
      CurvedAnimation(parent: shakeController, curve: Curves.elasticInOut),
    );

    shakeController.addListener(() {
      setState(() {});
    });

    await shakeController.forward();
    await shakeController.reverse();
    shakeController.dispose();
  }

  void _handleFirebaseError(FirebaseAuthException e) {
    String errorMessage = "حدث خطأ في تسجيل الدخول";

    if (e.code == 'user-not-found') {
      errorMessage = "البريد الإلكتروني غير مسجل";
    } else if (e.code == 'wrong-password') {
      errorMessage = "كلمة المرور غير صحيحة";
    } else if (e.code == 'invalid-email') {
      errorMessage = "صيغة البريد الإلكتروني غير صحيحة";
    }

    _showErrorSnackBar(errorMessage);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontFamily: 'Tajawal'),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _navigateToSignUp() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const SignupPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 700),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 40),

              // Welcome title with animation
              SlideTransition(
                position: _titleSlideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'أهلا بعودتك!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal',
                      color: Colors.deepPurple[800],
                      shadows: [
                        Shadow(
                          blurRadius: 8.0,
                          color: Colors.black.withOpacity(0.1),
                          offset: const Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Logo with bounce animation
              ScaleTransition(
                scale: _logoScaleAnimation,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 3,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                      // Sparkle effect
                      Positioned(
                        top: 10,
                        right: 10,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _animationController,
                              curve: const Interval(0.4, 0.8, curve: Curves.elasticOut),
                            ),
                          ),
                          child: Icon(
                            Icons.star,
                            color: Colors.amber[600],
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Email field with animation
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(-0.5, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
                )),
                child: FadeTransition(
                  opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: const Interval(0.4, 0.8, curve: Curves.easeIn),
                    ),
                  ),
                  child: _AnimatedTextField(
                    label: "البريـد الإلكتـروني",
                    icon: Icons.email_outlined,
                    controller: _emailController,
                    animation: _animationController,
                    interval: const Interval(0.4, 0.8),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Password field with animation
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(-0.5, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.5, 0.9, curve: Curves.easeOut),
                )),
                child: FadeTransition(
                  opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: const Interval(0.5, 0.9, curve: Curves.easeIn),
                    ),
                  ),
                  child: _AnimatedPasswordField(
                    label: "كلمة المرور",
                    icon: Icons.lock_outlined,
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                    animation: _animationController,
                    interval: const Interval(0.5, 0.9),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Login button with animation
              ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _isLoading
                      ? _LoadingButton()
                      : _AnimatedLoginButton(
                    onPressed: _signIn,
                    animation: _buttonColorAnimation,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // Sign up link with animation
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.5),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
                )),
                child: FadeTransition(
                  opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
                    ),
                  ),
                  child: _SignUpLink(onPressed: _navigateToSignUp),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom animated text field widget
class _AnimatedTextField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final Animation<double> animation;
  final Interval interval;

  const _AnimatedTextField({
    required this.label,
    required this.icon,
    required this.controller,
    required this.animation,
    required this.interval,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final animValue = CurvedAnimation(parent: animation, curve: interval).value;
        return Transform.translate(
          offset: Offset((1.0 - animValue) * 20, 0),
          child: Opacity(
            opacity: animValue,
            child: Transform.scale(
              scale: 0.9 + (animValue * 0.1),
              child: child,
            ),
          ),
        );
      },
      child: reusableTextField(label, icon, controller),
    );
  }
}

// Custom animated password field widget
class _AnimatedPasswordField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback onToggle;
  final Animation<double> animation;
  final Interval interval;

  const _AnimatedPasswordField({
    required this.label,
    required this.icon,
    required this.controller,
    required this.obscureText,
    required this.onToggle,
    required this.animation,
    required this.interval,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final animValue = CurvedAnimation(parent: animation, curve: interval).value;
        return Transform.translate(
          offset: Offset((1.0 - animValue) * 20, 0),
          child: Opacity(
            opacity: animValue,
            child: Transform.scale(
              scale: 0.9 + (animValue * 0.1),
              child: child,
            ),
          ),
        );
      },
      child: reusableTextField(
        label,
        icon,
        controller,
        isPassword: true,
        obscureText: obscureText,
        toggleObscure: onToggle,
      ),
    );
  }
}

// Animated login button
class _AnimatedLoginButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Animation<Color?> animation;

  const _AnimatedLoginButton({
    required this.onPressed,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: animation.value,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 8,
                shadowColor: Constants.kPrimaryColor.withOpacity(0.3),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login_rounded, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'تسجيل الدخول',
                    style: TextStyle(
                      fontSize: 18,
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

// Loading button state
class _LoadingButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
      decoration: BoxDecoration(
        color: Constants.kPrimaryColor.withOpacity(0.7),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Constants.kPrimaryColor.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'جاري التسجيل...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }
}

// Sign up link widget
class _SignUpLink extends StatelessWidget {
  final VoidCallback onPressed;

  const _SignUpLink({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'ليس لديك حساب؟',
          style: TextStyle(
            color: Constants.kGray,
            fontSize: 16,
            fontFamily: 'Tajawal',
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onPressed,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: Colors.transparent,
              ),
              child: Text(
                'سجل الآن',
                style: TextStyle(
                  color: Constants.kPrimaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal',
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}