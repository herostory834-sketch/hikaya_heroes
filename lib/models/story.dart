// models/story.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hikaya_heroes/utils/constants.dart';

class Story {
  final String id;
  final String title;
  final String description;
  final String content;
  final String content_for_boy;
  final String theme;
  final List<String> illustrations;
  final List<Question> questions;
  final String difficulty;
  final String aiBoy;
  final String aiGirl;
  final int views;
  final DateTime createdAt;
  final List<String> customizationQuestions;

  Story({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.theme,
    required this.illustrations,
    required this.questions,
    required this.aiBoy,
    required this.aiGirl,
    required this.difficulty,
    required this.views,
    required this.content_for_boy,
    required this.createdAt,
    required this.customizationQuestions,
  });

  factory Story.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Story(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      content: data['content'] ?? '',
      aiBoy: data['aiBoy'] ?? '',
      aiGirl: data['aiGirl'] ?? '',
      content_for_boy: data['content_for_boy'] ?? '',
      theme: data['theme'] ?? '',
      illustrations: List<String>.from(data['illustrations'] ?? []),
      questions: _parseQuestions(data['questions'] ?? []),
      difficulty: data['difficulty'] ?? 'medium',
      views: data['views'] ?? 0,
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      customizationQuestions: List<String>.from(data['customizationQuestions'] ?? Constants.customizationQuestions),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'content': content,
      'theme': theme,
      'illustrations': illustrations,//
      'aiBoy': aiBoy,
      'aiGirl': aiGirl,
      'content_for_boy': content_for_boy,
      'questions': questions.map((q) => q.toMap()).toList(),
      'difficulty': difficulty,
      'views': views,
      'createdAt': createdAt,
      'customizationQuestions': customizationQuestions,
    };
  }

  static List<Question> _parseQuestions(List<dynamic> questionsData) {
    return questionsData.map((q) => Question.fromMap(q)).toList();
  }
}

class Question {
  final String id;
  final String text;
  final List<String> options;
  final String correctAnswer;
  final String explanation;

  Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });

  factory Question.fromMap(Map<String, dynamic> data) {
    return Question(
      id: data['id'] ?? '',
      text: data['text'] ?? '',
      options: List<String>.from(data['options'] ?? []),
      correctAnswer: data['correctAnswer'] ?? '',
      explanation: data['explanation'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
    };
  }
}

class StoryCustomization {
  final String storyId;
   final String? childImage;
  final String? storyText;
  final String imageMode; // Add this field

  StoryCustomization({
    required this.storyId,
     this.childImage,
    this.storyText,
    this.imageMode = 'real', // Default to real mode
  });

  Map<String, dynamic> toMap() {
    return {
      'storyId': storyId,
       'childImage': childImage,
      'storyText': storyText,
      'imageMode': imageMode,
    };
  }

  factory StoryCustomization.fromMap(Map<String, dynamic> data) {
    return StoryCustomization(
      storyId: data['storyId'] ?? '',
       childImage: data['childImage'],
      storyText: data['storyText'],
      imageMode: data['imageMode'],
    );
  }
}