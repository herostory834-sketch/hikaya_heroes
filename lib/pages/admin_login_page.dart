// pages/admin_login_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hikaya_heroes/services/firebase_service.dart';
import 'package:hikaya_heroes/widgets/reusable_widgets.dart';
import 'package:hikaya_heroes/pages/admin_dashboard.dart';

import '../utils/constants.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  final FirebaseService _firebaseService = FirebaseService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("الرجاء إدخال البريد الإلكتروني وكلمة المرور"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      User? user = await _firebaseService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user != null) {
        bool isAdmin = await _firebaseService.isAdmin(user.uid);

        if (isAdmin) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboard()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("ليس لديك صلاحيات للدخول كمسؤول"),
              backgroundColor: Colors.red,
            ),
          );
          await _firebaseService.signOut();
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "حدث خطأ في تسجيل الدخول";

      if (e.code == 'user-not-found') {
        errorMessage = "البريد الإلكتروني غير مسجل";
      } else if (e.code == 'wrong-password') {
        errorMessage = "كلمة المرور غير صحيحة";
      } else if (e.code == 'invalid-email') {
        errorMessage = "صيغة البريد الإلكتروني غير صحيحة";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("حدث خطأ غير متوقع: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Constants.kPrimaryColor,
        elevation: 0,
        title: const Text('تسجيل الدخول كمسؤول'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Email field
              reusableTextField(
                "البريـد الإلكتـروني",
                Icons.email_outlined,
                _emailController,
              ),

              // Password field
              reusableTextField(
                "كلمة المرور",
                Icons.lock_outlined,
                _passwordController,
                isPassword: true,
                obscureText: _obscurePassword,
                toggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
              ),

              const SizedBox(height: 20),

              // Login button
              _isLoading
                  ? const CircularProgressIndicator()
                  : signinsignupbutton(context, true, _signIn, loading: _isLoading),

              const SizedBox(height: 20),

              // Back to user login link
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'رجوع لتسجيل الدخول كعادي',
                  style: TextStyle(color: Constants.kPrimaryColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}