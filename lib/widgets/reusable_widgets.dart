// widgets/reusable_widgets.dart
import 'package:flutter/material.dart';
import 'package:hikaya_heroes/utils/constants.dart';

// Reusable text field
Widget reusableTextField(
    String labelText,
    IconData icon,
    TextEditingController controller, {
      String? errorText,
      bool isPassword = false,
      bool obscureText = true,
      VoidCallback? toggleObscure,
    }) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text(
        labelText,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        obscureText: isPassword ? obscureText : false,
        enableSuggestions: !isPassword,
        autocorrect: !isPassword,
        textAlign: TextAlign.left,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Constants.kGray),
          filled: true,
          fillColor: Constants.kLightGray,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          errorText: errorText,
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_off : Icons.visibility,
            ),
            onPressed: toggleObscure,
          )
              : null,
        ),
        keyboardType: isPassword ? TextInputType.visiblePassword : TextInputType.emailAddress,
      ),
      const SizedBox(height: 8),
    ],
  );
}

// Sign in/Sign up button
Container signinsignupbutton(
    BuildContext context,
    bool isLogin,
    Future<void> Function() onTap, {
      bool loading = false,
    }) {
  return Container(
    width: MediaQuery.of(context).size.width,
    height: 50,
    margin: const EdgeInsets.fromLTRB(0, 10, 0, 20),
    child: ElevatedButton(
      onPressed: loading
          ? null
          : () async {
        await onTap();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Constants.kPrimaryColor,
        foregroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      child: loading
          ? const CircularProgressIndicator(
        color: Colors.white,
      )
          : Text(isLogin ? 'تسجيل الدخول' : 'تسجيل'),
    ),
  );
}