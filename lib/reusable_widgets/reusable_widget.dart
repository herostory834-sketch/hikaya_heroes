import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Service {
  // Singleton → only one instance for the whole app
  Service._();
  static final Service instance = Service._();

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase Authentication
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore database

// Authentication methods

//send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
  // Register a new user(singup)
  Future<User?> createUser({
    required String email,
    required String password,
    required String confirmpassword,
    required String name,
    required String gender,
  }) async {
    try {
      // 1. Create account in FirebaseAuth
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = cred.user;
      if (user == null) throw Exception("Failed to create user");

      // 2. Save extra user data in Firestore
      await _firestore.collection("users").doc(user.uid).set({
        "name": name,
        "gender": gender,
        "email": email,
        "createdAt": FieldValue.serverTimestamp(), // server timestamp
      });

      return user;
    } on FirebaseAuthException catch (e) {
      // Pass Firebase errors to UI
      throw FirebaseAuthException(code: e.code, message: e.message);
    } catch (e) {
      throw Exception("Unexpected error: $e");
    }
  }

  // Sign in existing user
Future<User?> signInUser(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user;
}

  // Sign out the current user
  Future<void> signOutUser() async {
    await _auth.signOut();
  }

  // Firestore user data

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _firestore.collection("users").doc(uid).get();
    return doc.data();
  }

  // Update user data (e.g., name, gender)
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    await _firestore.collection("users").doc(uid).update(data);
  }

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current logged-in user
  User? get currentUser => _auth.currentUser;
}


/// Responsive logo widget: size changes based on screen width
/// so it looks good on phones and tablets
Widget logoWidget(BuildContext context, String imageName) {
  final screenWidth = MediaQuery.of(context).size.width;
  return Image.asset(
    imageName,
    fit: BoxFit.contain,
    width: screenWidth * 0.7,
    height: screenWidth * 0.7,
  );
}
/// Reusable text field with label on top, optional password eye toggle, and error text
Widget reusableTextField(
  String labelText,
  IconData icon,
  TextEditingController controller, {
  bool isPassword = false,
  bool obscureText = true,
  VoidCallback? toggleObscure,
  String? errorText,
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
          prefixIcon: Icon(icon, color: Colors.grey),
          filled: true,
          fillColor: const Color.fromARGB(92, 153, 149, 149),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
        keyboardType:
            isPassword ? TextInputType.visiblePassword : TextInputType.emailAddress,
      ),
      const SizedBox(height: 8), // مسافة بعد الحقل
    ],
  );
}


/// Sign in / Sign up button with optional loading indicator
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
        backgroundColor: Color.fromARGB(255, 213, 166, 72),
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