// models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String gender;
  final bool isAdmin;
  final DateTime createdAt;
  final int totalStoriesRead;
  final int totalPoints;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.gender,
    required this.isAdmin,
    required this.createdAt,
    this.totalStoriesRead = 0,
    this.totalPoints = 0,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      gender: data['gender'] ?? '',
      isAdmin: data['isAdmin'] ?? false,
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      totalStoriesRead: data['totalStoriesRead'] ?? 0,
      totalPoints: data['totalPoints'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'gender': gender,
      'isAdmin': isAdmin,
      'createdAt': createdAt,
      'totalStoriesRead': totalStoriesRead,
      'totalPoints': totalPoints,
    };
  }
}