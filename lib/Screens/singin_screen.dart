import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hikaya_heroes/reusable_widgets/reusable_widget.dart';
import 'home_screen.dart';
import '../signup_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _loading = false;

  // Field errors
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validateFields() {
    bool valid = true;
    setState(() {
      _emailError = _emailController.text.isEmpty
          ? "الرجاء إدخال البريد الإلكتروني"
          : !_emailController.text.contains('@')
              ? "أدخل بريد إلكتروني صحيح"
              : null;

      _passwordError = _passwordController.text.isEmpty
          ? "كلمة المرور مطلوبة"
          : _passwordController.text.length < 6
              ? "كلمة المرور 6 أحرف على الأقل"
              : null;

      if (_emailError != null || _passwordError != null) valid = false;
    });
    return valid;
  }

  Future<void> _signIn() async {
    if (!_validateFields()) return;

    setState(() => _loading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'user-not-found':
            _emailError = 'البريد الإلكتروني غير مسجل';
            break;
          case 'wrong-password':
            _passwordError = 'كلمة المرور غير صحيحة';
            break;
          case 'invalid-email':
            _emailError = 'صيغة البريد الإلكتروني غير صحيحة';
            break;
          case 'user-disabled':
            _emailError = 'تم تعطيل الحساب';
            break;
          default:
            _passwordError = e.message ?? 'حدث خطأ غير معروف';
        }
      });
    } catch (e) {
      setState(() {
        _passwordError = 'خطأ غير متوقع: $e';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF0),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo
            Image.asset(
          '"assets/images/logo.png"',
          fit: BoxFit.contain,
          width: screenWidth * 0.7,
          height: screenWidth * 0.7,
        ),
              const SizedBox(height: 24),

              // Email field
              reusableTextField(
                "البريـد الإلكتـروني",
                Icons.email_outlined,
                _emailController,
                errorText: _emailError,
                isPassword: false,
                obscureText: false,
              ),

              // Password field
              reusableTextField(
                "كلمة المرور",
                Icons.lock_outlined,
                _passwordController,
                isPassword: true,
                obscureText: _obscurePassword,
                toggleObscure: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                errorText: _passwordError,
              ),

              // Sign In button
              signinsignupbutton(context, true, _signIn, loading: _loading),
// Sign Up navigation with reversed text
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    TextButton(
      onPressed: _loading
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SignUpScreen()),
              );
            },
          style: TextButton.styleFrom(
            foregroundColor: const Color.fromARGB(255, 212, 159, 52), // لون نص الزر
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          child: const Text("إنشاء حساب"),
        ),
        const Text(
          "ليس لديك حساب؟",
          style: TextStyle(fontSize: 16),
        ),
      ],
    ),


            ],
          ),
        ),
      ),
    );
  }
}
