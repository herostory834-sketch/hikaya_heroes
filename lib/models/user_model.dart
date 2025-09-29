import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String gender;
  final List bookMarks;
  final bool isAdmin;
  final DateTime createdAt;
  final int totalStoriesRead;
  final int totalPoints;
  final String? profileImagePath; // New field for local profile image path

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.gender,
    required this.isAdmin,
    required this.createdAt,
     required this.bookMarks,
    this.totalStoriesRead = 0,
    this.totalPoints = 0,
    this.profileImagePath, // Optional field, null if no image
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      gender: data['gender'] ?? '',
      bookMarks: data['bookMarks'] ?? [],
      isAdmin: data['isAdmin'] ?? false,
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      totalStoriesRead: data['totalStoriesRead'] ?? 0,
      totalPoints: data['totalPoints'] ?? 0,
      profileImagePath: data['profileImagePath'], // May be null
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'gender': gender,
      'isAdmin': isAdmin,
      'bookMarks': bookMarks,
      'createdAt': createdAt,
      'totalStoriesRead': totalStoriesRead,
      'totalPoints': totalPoints,
      'profileImagePath': profileImagePath, // Include profile image path
    };
  }
}
