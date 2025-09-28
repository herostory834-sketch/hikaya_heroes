import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hikaya_heroes/reusable_widgets/reusable_widget.dart';
import 'package:hikaya_heroes/Screens/home_screen.dart';

enum Gender { male, female }

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
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

  @override
  void dispose() {
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
    if (!_validateFields()) return;

    setState(() => _loading = true);

    try {
      await Service.instance.createUser(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        confirmpassword: _confirmPasswordController.text,
        name: _nameController.text.trim(),
        gender: selectedGender == Gender.male ? "male" : "female",
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ تم إنشاء الحساب بنجاح"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == "email-already-in-use") _emailError = "البريد مستخدم مسبقًا";
        if (e.code == "invalid-email") _emailError = "صيغة البريد غير صحيحة";
        if (e.code == "weak-password") _passwordError = "كلمة المرور ضعيفة جدًا";
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("حدث خطأ غير متوقع: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 173, 125, 30),
        elevation: 0,
        title: const Text(
          "تسجيل حساب جديد",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Name input
              reusableTextField(
                "الأسـم باللغة العربية",
                Icons.person_outline,
                _nameController,
                errorText: _nameError,
              ),

              // Email input
              reusableTextField(
                "البريـد الإلكتـروني",
                Icons.email_outlined,
                _emailController,
                errorText: _emailError,
              ),

              // Password input
              reusableTextField(
                "كلمة المرور",
                Icons.lock_outlined,
                _passwordController,
                isPassword: true,
                obscureText: _obscurePassword,
                toggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                errorText: _passwordError,
              ),

              // Confirm password input
              reusableTextField(
                "تأكيد كلمة المرور",
                Icons.lock_outlined,
                _confirmPasswordController,
                isPassword: true,
                obscureText: _obscureConfirmPassword,
                toggleObscure: () =>
                    setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                errorText: _confirmPasswordError,
              ),

              const SizedBox(height: 16),

              // Gender label
              Align(
                alignment: Alignment.centerRight,
                child: const Text(
                  "الجنس",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
              const SizedBox(height: 8),

              // Gender options
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Radio<Gender>(
                    value: Gender.male,
                    groupValue: selectedGender,
                    onChanged: (v) => setState(() => selectedGender = v),
                  ),
                  const Text("ذكر"),
                  const SizedBox(width: 25),
                  Radio<Gender>(
                    value: Gender.female,
                    groupValue: selectedGender,
                    onChanged: (v) => setState(() => selectedGender = v),
                  ),
                  const Text("أنثى"),
                ],
              ),
              if (_genderError != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(_genderError!, style: const TextStyle(color: Colors.red)),
                ),

              // Terms & conditions
              Row(
                children: [
                  Checkbox(
                    value: isTermsAccepted,
                    onChanged: (v) => setState(() => isTermsAccepted = v ?? false),
                  ),
                  const Expanded(child: Text("أوافق على الشروط والأحكام")),
                ],
              ),
              if (_termsError != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(_termsError!, style: const TextStyle(color: Colors.red)),
                ),

              // Sign Up button
              signinsignupbutton(context, false, _signUp, loading: _loading),
            ],
          ),
        ),
      ),
    );
  }
}
