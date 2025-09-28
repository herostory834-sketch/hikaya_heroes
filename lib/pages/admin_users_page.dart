// pages/admin_users_page.dart
import 'package:flutter/material.dart';
import 'package:hikaya_heroes/models/user_model.dart';
import 'package:hikaya_heroes/services/firebase_service.dart';
import 'package:hikaya_heroes/utils/constants.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final FirebaseService _firebaseService = FirebaseService();
  List<UserModel> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() async {
    setState(() => _isLoading = true);
    List<UserModel> users = await _firebaseService.getAllUsers();
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المستخدمين'),
        centerTitle: true,
        backgroundColor: Constants.kPrimaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return Card(
            child: ListTile(
              title: Text(user.name ?? 'بدون اسم'),
              subtitle: Text(user.email ?? 'بدون بريد'),
              trailing: Text(
                user.isAdmin ? 'مسؤول' : 'مستخدم',
                style: TextStyle(
                  color: user.isAdmin ? Colors.green : Colors.blue,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}