// pages/signup_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hikaya_heroes/pages/success_registration_page.dart';
import 'package:hikaya_heroes/services/firebase_service.dart';
import 'package:hikaya_heroes/widgets/reusable_widgets.dart';
import 'package:hikaya_heroes/pages/home_page.dart';
import '../utils/constants.dart';

enum Gender { male, female }

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> with TickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  Gender? selectedGender;
  bool isTermsAccepted = false;

  // Inline error messages
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _genderError;
  String? _termsError;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _loading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _backgroundColorAnimation;

  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
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

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.1, 0.6, curve: Curves.elasticOut),
      ),
    );

    _backgroundColorAnimation = ColorTween(
      begin: Constants.kPrimaryColor.withOpacity(0.8),
      end: const Color(0xFFFFFAF0),
    ).animate(_animationController);

    // Start animations after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Validate fields inline
  bool _validateFields() {
    bool valid = true;

    setState(() {
      _nameError = _nameController.text.isEmpty
          ? "الرجاء إدخال الاسم"
          : !RegExp(r'^[\u0600-\u06FF\s]+$').hasMatch(_nameController.text)
          ? "الاسم يجب أن يكون بالعربية فقط"
          : null;

      _emailError = _emailController.text.isEmpty
          ? "الرجاء إدخال البريد الإلكتروني"
          : !_emailController.text.contains('@')
          ? "البريد الإلكتروني غير صالح"
          : null;

      _passwordError = _passwordController.text.length < 6
          ? "كلمة المرور قصيرة جدًا"
          : null;

      _confirmPasswordError =
      _passwordController.text != _confirmPasswordController.text
          ? "كلمة المرور غير متطابقة"
          : null;

      _genderError = selectedGender == null ? "اختر الجنس" : null;

      _termsError = !isTermsAccepted ? "يجب الموافقة على الشروط والأحكام" : null;

      if (_nameError != null ||
          _emailError != null ||
          _passwordError != null ||
          _confirmPasswordError != null ||
          _genderError != null ||
          _termsError != null) valid = false;
    });

    return valid;
  }

  // SignUp action
  Future<void> _signUp() async {
    if (!_validateFields()) {
      await _playErrorAnimation();
      return;
    }

    setState(() => _loading = true);

    // Button press animation
    await _animationController.reverse();
    await _animationController.forward();

    try {
      await _firebaseService.createUser(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        gender: selectedGender == Gender.male ? "male" : "female",
      );

      if (!mounted) return;

      // Success animation before navigation
      await _playSuccessAnimation();

      _showSuccessSnackBar("✅ تم إنشاء الحساب بنجاح");

      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const SuccessRegistrationPage(),
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
    } on FirebaseAuthException catch (e) {
      await _playErrorAnimation();
      _handleFirebaseError(e);
    } catch (e) {
      await _playErrorAnimation();
      _showErrorSnackBar("حدث خطأ غير متوقع: $e");
    } finally {
      setState(() => _loading = false);
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
    setState(() {
      if (e.code == "email-already-in-use") _emailError = "البريد مستخدم مسبقًا";
      if (e.code == "invalid-email") _emailError = "صيغة البريد غير صحيحة";
      if (e.code == "weak-password") _passwordError = "كلمة المرور ضعيفة جدًا";
    });
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontFamily: 'Tajawal'),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 2),
      ),
    );
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFFFFAF0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),

              // Title with animation
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, -1.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
                )),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    "سجل وإبدأ مغامرتك السحرية!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
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

              // Form container with scale animation
              ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Name input with animation
                        _AnimatedFormField(
                          animation: _animationController,
                          interval: const Interval(0.2, 0.6),
                          child: reusableTextField(
                            "الأسـم باللغة العربية",
                            Icons.person_outline,
                            _nameController,
                            errorText: _nameError,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Email input with animation
                        _AnimatedFormField(
                          animation: _animationController,
                          interval: const Interval(0.3, 0.7),
                          child: reusableTextField(
                            "البريـد الإلكتـروني",
                            Icons.email_outlined,
                            _emailController,
                            errorText: _emailError,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Password input with animation
                        _AnimatedFormField(
                          animation: _animationController,
                          interval: const Interval(0.4, 0.8),
                          child: reusableTextField(
                            "كلمة المرور",
                            Icons.lock_outlined,
                            _passwordController,
                            isPassword: true,
                            obscureText: _obscurePassword,
                            toggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                            errorText: _passwordError,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Confirm password input with animation
                        _AnimatedFormField(
                          animation: _animationController,
                          interval: const Interval(0.5, 0.9),
                          child: reusableTextField(
                            "تأكيد كلمة المرور",
                            Icons.lock_outlined,
                            _confirmPasswordController,
                            isPassword: true,
                            obscureText: _obscureConfirmPassword,
                            toggleObscure: () =>
                                setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            errorText: _confirmPasswordError,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Gender section with animation
                        SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(-0.5, 0.0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _animationController,
                            curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
                          )),
                          child: FadeTransition(
                            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                              CurvedAnimation(
                                parent: _animationController,
                                curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
                              ),
                            ),
                            child: Column(
                              children: [
                                // Gender label
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    "الجنس",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      fontFamily: 'Tajawal',
                                      color: Colors.deepPurple[600],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Gender options
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _AnimatedGenderOption(
                                      animation: _animationController,
                                      interval: const Interval(0.65, 0.95),
                                      child: Row(
                                        children: [
                                          Radio<Gender>(
                                            value: Gender.male,
                                            groupValue: selectedGender,
                                            onChanged: (v) => setState(() => selectedGender = v),
                                            fillColor: MaterialStateProperty.resolveWith<Color>(
                                                  (Set<MaterialState> states) {
                                                return Constants.kPrimaryColor;
                                              },
                                            ),
                                          ),
                                          Text("ذكر", style: TextStyle(fontFamily: 'Tajawal')),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 25),
                                    _AnimatedGenderOption(
                                      animation: _animationController,
                                      interval: const Interval(0.7, 1.0),
                                      child: Row(
                                        children: [
                                          Radio<Gender>(
                                            value: Gender.female,
                                            groupValue: selectedGender,
                                            onChanged: (v) => setState(() => selectedGender = v),
                                            fillColor: MaterialStateProperty.resolveWith<Color>(
                                                  (Set<MaterialState> states) {
                                                return Constants.kPrimaryColor;
                                              },
                                            ),
                                          ),
                                          Text("أنثى", style: TextStyle(fontFamily: 'Tajawal')),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (_genderError != null)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      _genderError!,
                                      style: const TextStyle(color: Constants.kErrorColor, fontFamily: 'Tajawal'),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Terms & conditions with animation
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
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Checkbox(
                                      value: isTermsAccepted,
                                      onChanged: (v) => setState(() => isTermsAccepted = v ?? false),
                                      fillColor: MaterialStateProperty.resolveWith<Color>(
                                            (Set<MaterialState> states) {
                                          return Constants.kPrimaryColor;
                                        },
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        "أوافق على الشروط والأحكام",
                                        style: TextStyle(fontFamily: 'Tajawal'),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_termsError != null)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      _termsError!,
                                      style: const TextStyle(color: Constants.kErrorColor, fontFamily: 'Tajawal'),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Sign Up button with animation
                        ScaleTransition(
                          scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _animationController,
                              curve: const Interval(0.8, 1.0, curve: Curves.elasticOut),
                            ),
                          ),
                          child: FadeTransition(
                            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                              CurvedAnimation(
                                parent: _animationController,
                                curve: const Interval(0.8, 1.0, curve: Curves.easeIn),
                              ),
                            ),
                            child: _loading
                                ? _LoadingButton()
                                : _AnimatedSignUpButton(onPressed: _signUp),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom animated form field widget
class _AnimatedFormField extends StatelessWidget {
  final Animation<double> animation;
  final Interval interval;
  final Widget child;

  const _AnimatedFormField({
    required this.animation,
    required this.interval,
    required this.child,
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
      child: child,
    );
  }
}

// Custom animated gender option widget
class _AnimatedGenderOption extends StatelessWidget {
  final Animation<double> animation;
  final Interval interval;
  final Widget child;

  const _AnimatedGenderOption({
    required this.animation,
    required this.interval,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final animValue = CurvedAnimation(parent: animation, curve: interval).value;
        return Transform.scale(
          scale: 0.8 + (animValue * 0.2),
          child: Opacity(
            opacity: animValue,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

// Animated sign up button
class _AnimatedSignUpButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AnimatedSignUpButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Constants.kPrimaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            elevation: 8,
            shadowColor: Constants.kPrimaryColor.withOpacity(0.3),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_add_alt_1, size: 22),
              const SizedBox(width: 8),
              Text(
                'إنشاء حساب',
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
            'جاري إنشاء الحساب...',
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