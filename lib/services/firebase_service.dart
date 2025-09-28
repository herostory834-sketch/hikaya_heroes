// services/firebase_service.dart
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hikaya_heroes/models/user_model.dart';
import 'package:hikaya_heroes/models/story.dart';
import 'package:http/http.dart' as http;

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create user with email and password
  Future<User?> createUser({
    required String name,
    required String email,
    required String password,
    required String gender,
  }) async {
    try {
      // Create user in Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user == null) return null;

      // Add user data to Firestore
      await _firestore.collection('users').doc(result.user!.uid).set({
        'name': name,
        'email': email,
        'gender': gender,
        'isAdmin': false,
        'createdAt': FieldValue.serverTimestamp(),
        'totalStoriesRead': 0,
        'totalPoints': 0,
      });

      return result.user;
    } catch (e) {
      print("Error creating user: $e");
      return null;
    }
  }

  // Sign in user
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print("Error signing in: $e");
      return null;
    }
  }

  // Check if user is admin
  Future<bool> isAdmin(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return (doc.data() as Map<String, dynamic>)['isAdmin'] ?? false;
      }
      return false;
    } catch (e) {
      print("Error checking admin status: $e");
      return false;
    }
  }

  // Set user as admin
  Future<void> setAdmin(String uid) async {
    await _firestore.collection('users').doc(uid).update({'isAdmin': true});
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print("Error getting user data: $e");
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('users').doc(uid).update(updates);
    } catch (e) {
      print("Error updating user profile: $e");
      rethrow;
    }
  }

  // Get all users (admin only)
  Future<List<UserModel>> getAllUsers() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('users').get();
      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      print("Error getting all users: $e");
      return [];
    }
  }

  // Add new story to Firestore
  Future<void> addStory(Story story) async {
    try {
      await _firestore.collection('stories').add(story.toMap());
    } catch (e) {
      print("Error adding story: $e");
      rethrow;
    }
  }

  // Update story in Firestore
  Future<void> updateStory(String storyId, Story story) async {
    try {
      await _firestore.collection('stories').doc(storyId).update(story.toMap());
    } catch (e) {
      print("Error updating story: $e");
      rethrow;
    }
  }

  // Get all stories from Firestore
  Future<List<Story>> getAllStories() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('stories')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => Story.fromFirestore(doc)).toList();
    } catch (e) {
      print("Error getting stories: $e");
      return [];
    }
  }

  // Get stories by category
  Future<List<Story>> getStoriesByCategory(String category) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('stories')
          .where('theme', isEqualTo: category)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => Story.fromFirestore(doc)).toList();
    } catch (e) {
      print("Error getting stories by category: $e");
      return [];
    }
  }

  // Get story by ID
  Future<Story?> getStoryById(String storyId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('stories').doc(storyId).get();
      if (doc.exists) {
        return Story.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print("Error getting story by ID: $e");
      return null;
    }
  }

  // Delete story from Firestore
  Future<void> deleteStory(String storyId) async {
    try {
      await _firestore.collection('stories').doc(storyId).delete();
    } catch (e) {
      print("Error deleting story: $e");
      rethrow;
    }
  }

  // Track story view and update user progress
  Future<void> trackStoryView(String storyId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Track view in storyViews collection
      await _firestore.collection('storyViews').add({
        'storyId': storyId,
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Increment story view count
      await _firestore.collection('stories').doc(storyId).update({
        'views': FieldValue.increment(1),
      });

      // Update user's reading progress
      await _updateUserReadingProgress(user.uid, storyId);
    } catch (e) {
      print("Error tracking story view: $e");
    }
  }

  // Update user's reading progress and points
  Future<void> _updateUserReadingProgress(String userId, String storyId) async {
    try {
      // Check if user has already read this story
      final progressDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('readingProgress')
          .doc(storyId)
          .get();

      if (!progressDoc.exists) {
        // First time reading this story - award points
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('readingProgress')
            .doc(storyId)
            .set({
          'storyId': storyId,
          'readAt': FieldValue.serverTimestamp(),
          'completed': false,
        });

        // Increment total stories read and add points
        await _firestore.collection('users').doc(userId).update({
          'totalStoriesRead': FieldValue.increment(1),
          'totalPoints': FieldValue.increment(10), // 10 points per story
        });
      }
    } catch (e) {
      print("Error updating reading progress: $e");
    }
  }

  // Bookmark methods
  Future<void> addBookmark(String storyId) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('bookmarks')
          .doc(storyId)
          .set({
        'storyId': storyId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> removeBookmark(String storyId) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('bookmarks')
          .doc(storyId)
          .delete();
    }
  }

  Future<List<Story>> getUserBookmarks() async {
    final user = _auth.currentUser;
    if (user != null) {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('bookmarks')
          .orderBy('timestamp', descending: true)
          .get();

      List<Story> bookmarks = [];
      for (var doc in querySnapshot.docs) {
        final storyId = doc['storyId'];
        if (storyId != null) {
          final story = await getStoryById(storyId);
          if (story != null) {
            bookmarks.add(story);
          }
        }
      }
      return bookmarks;
    }
    return [];
  }

  Future<bool> isStoryBookmarked(String storyId) async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('bookmarks')
          .doc(storyId)
          .get();
      return doc.exists;
    }
    return false;
  }

  // Save story customization

  // Get story customization

  // Analytics methods
  Future<Map<String, dynamic>> getAnalytics() async {
    try {
      // Get total users
      QuerySnapshot usersSnapshot = await _firestore.collection('users').get();
      int totalUsers = usersSnapshot.docs.length;

      // Get total stories
      QuerySnapshot storiesSnapshot = await _firestore.collection('stories').get();
      int totalStories = storiesSnapshot.docs.length;

      // Get total views
      final viewsSnapshot = await _firestore.collection('storyViews').get();
      int totalViews = viewsSnapshot.docs.length;

      // Get active users (last 7 days)
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      QuerySnapshot activeUsersSnapshot = await _firestore
          .collection('storyViews')
          .where('timestamp', isGreaterThanOrEqualTo: sevenDaysAgo)
          .get();

      // Get unique active users
      final activeUserIds = activeUsersSnapshot.docs
          .map((doc) => doc['userId'])
          .toSet()
          .length;

      // Get popular stories
      List<QueryDocumentSnapshot> stories = storiesSnapshot.docs;
      stories.sort((a, b) {
        final aViews = (a.data() as Map<String, dynamic>)['views'] ?? 0;
        final bViews = (b.data() as Map<String, dynamic>)['views'] ?? 0;
        return (bViews as int).compareTo(aViews as int);
      });

      List<Map<String, dynamic>> popularStories = stories.take(5).map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'views': data['views'] ?? 0,
        };
      }).toList();

      return {
        'totalUsers': totalUsers,
        'totalStories': totalStories,
        'totalViews': totalViews,
        'activeUsers': activeUserIds,
        'popularStories': popularStories,
      };
    } catch (e) {
      print("Error getting analytics: $e");
      return {
        'totalUsers': 0,
        'totalStories': 0,
        'totalViews': 0,
        'activeUsers': 0,
        'popularStories': [],
      };
    }
  }

  // Get user reading statistics
  Future<Map<String, dynamic>> getUserStatistics(String userId) async {
    try {
      // Get user document
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>?;

      // Get reading progress
      final progressSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('readingProgress')
          .get();

      // Get bookmarks count
      final bookmarksSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('bookmarks')
          .get();

      return {
        'totalStoriesRead': userData?['totalStoriesRead'] ?? 0,
        'totalPoints': userData?['totalPoints'] ?? 0,
        'storiesInProgress': progressSnapshot.docs.length,
        'totalBookmarks': bookmarksSnapshot.docs.length,
        'memberSince': (userData?['createdAt'] as Timestamp?)?.toDate(),
      };
    } catch (e) {
      print("Error getting user statistics: $e");
      return {
        'totalStoriesRead': 0,
        'totalPoints': 0,
        'storiesInProgress': 0,
        'totalBookmarks': 0,
        'memberSince': DateTime.now(),
      };
    }
  }

  Future<String?> sendToGeminiApi(String base64Image, String storyText, Map<String, dynamic> customization) async {
    const apiKey = 'AIzaSyASsM1qJIaNWF80P-8ZtKz_kWZOX-78iuY';
    const url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image-preview:generateContent';


      final response = await http.post(
        Uri.parse(url),
        headers: {
          'x-goog-api-key': apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': 'Convert the image to cartoon style and incorporate the following story details: '
                      'Grandmother: ${customization['grandmotherName']}, '
                      'Best Friend: ${customization['bestFriendName']}, '
                      'Friend Gender: ${customization['friendGender']}, '
                      'Favorite Color: ${customization['favoriteColor']}. '
                      'Story Text: $storyText'
                },
                {
                  'inline_data': {
                    'mime_type': 'image/png',
                    'data': base64Image,
                  }
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 1,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final base64Result = data['candidates']?[0]['content']['parts']?[1]['inlineData']?['data'];
        if (base64Result != null) {
          return base64Result;
        } else {
          throw Exception('No base64 image data in response');
        }
      } else {
        throw Exception('API request failed with status: ${response.statusCode}');
      }

  }


  Future<Map<String, dynamic>> generateStoryElements(String content) async {
    const String apiKey = 'AIzaSyASsM1qJIaNWF80P-8ZtKz_kWZOX-78iuY'; // ضع مفتاحك هنا (ويفضل تخزينه في env أو Firebase)
    final Uri endpoint = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent',
    );

    // ✅ الـ prompt المعدل حسب طلبك
    final String prompt = '''
From the following story text, generate 5 quiz questions. Each question should be in JSON format with fields: "text" (the question), "options" (array of 4 strings), "correctAnswer" (exact string matching one of the options), "explanation" (brief explanation). Do not include an 'id' field.

Output the questions as an array of objects.

Also, generate a list of 4 customization questions for personalizing the story, like asking for names of characters that can be replaced in the story (e.g., "What is your grandmother's name?" if there's a grandmother character). Make them relevant to the story's content.

The entire output should be a valid JSON object: { "questions": [...], "customizationQuestions": [...] }

Do not include any additional text outside the JSON.

Story text: $content
''';

    final headers = {
      'x-goog-api-key': apiKey,
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": prompt}
          ]
        }
      ]
    });

    try {
      final request = http.Request('POST', endpoint);
      request.body = body;
      request.headers.addAll(headers);

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final Map<String, dynamic> data = jsonDecode(responseBody);

        String rawText =
            data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"] ?? "";

        // تنظيف من Markdown
        rawText = rawText.trim();
        if (rawText.startsWith("```")) {
          rawText = rawText.replaceAll(RegExp(r"^```(json)?"), "");
          rawText = rawText.replaceAll("```", "");
          rawText = rawText.trim();
        }

        final Map<String, dynamic> elements = jsonDecode(rawText);

        return elements;
      }
      else {
        throw Exception(
            'API request failed with status ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error generating story elements: $e');
      rethrow;
    }
  }
}