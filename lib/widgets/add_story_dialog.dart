// widgets/add_story_dialog.dart
import 'package:flutter/material.dart';
import 'package:hikaya_heroes/models/story.dart';
import 'package:hikaya_heroes/utils/constants.dart';
import 'package:hikaya_heroes/services/firebase_service.dart'; // Import for FirebaseService

class AddStoryDialog extends StatefulWidget {
  final Function(Story, {bool isEditing}) onAddStory;
  final Story? existingStory; // For editing existing stories

  const AddStoryDialog({
    super.key,
    required this.onAddStory,
    this.existingStory,
  });

  @override
  State<AddStoryDialog> createState() => _AddStoryDialogState();
}

class _AddStoryDialogState extends State<AddStoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedTheme = '';
  String _selectedDifficulty = '';
  bool _isEditing = false;
  bool _isGenerating = false; // To show loading during API call

  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    if (widget.existingStory != null) {
      _isEditing = true;
      _titleController.text = widget.existingStory!.title;
      _descriptionController.text = widget.existingStory!.description;
      _contentController.text = widget.existingStory!.content;
      _selectedTheme = widget.existingStory!.theme;
      _selectedDifficulty = widget.existingStory!.difficulty;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'تعديل القصة' : 'إضافة قصة جديدة'),
      content: _isGenerating
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'العنوان',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Constants.kLightGray,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال العنوان';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'الوصف',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Constants.kLightGray,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال الوصف';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'المحتوى',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Constants.kLightGray,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال المحتوى';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedTheme.isEmpty ? null : _selectedTheme,
                decoration: InputDecoration(
                  labelText: 'الفئة',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Constants.kLightGray,
                ),
                items: Constants.categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTheme = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء اختيار الفئة';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedDifficulty.isEmpty ? null : _selectedDifficulty,
                decoration: InputDecoration(
                  labelText: 'الصعوبة',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Constants.kLightGray,
                ),
                items: ['سهل', 'متوسط', 'صعب'].map((difficulty) {
                  return DropdownMenuItem(
                    value: difficulty,
                    child: Text(difficulty),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDifficulty = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء اختيار الصعوبة';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _isGenerating ? null : _handleSubmit,
          child: Text(_isEditing ? 'تحديث' : 'إضافة'),
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isGenerating = true;
      });

      try {
        final elements = await _firebaseService.generateStoryElements(_contentController.text);

        List<Question> questions = (elements['questions'] as List)
            .map((q) => Question(
          id: '', // ID can be generated later if needed
          text: q['text'],
          options: List<String>.from(q['options']),
          correctAnswer: q['correctAnswer'],
          explanation: q['explanation'],
        ))
            .toList();

        List<String> customizationQuestions = List<String>.from(elements['customizationQuestions']);

        Story story = Story(
          id: widget.existingStory?.id ?? '',
          title: _titleController.text,
          description: _descriptionController.text,
          content: _contentController.text,
          theme: _selectedTheme,
          photo: 'photo',
          aiBoy: 'aiBoy',
          aiGirl: 'aiGirl',
          content_for_boy: 'content_for_boy',
          illustrations: widget.existingStory?.illustrations ?? [],
          questions: questions,
          difficulty: _selectedDifficulty,
          views: widget.existingStory?.views ?? 0,
          createdAt: widget.existingStory?.createdAt ?? DateTime.now(),
          customizationQuestions: customizationQuestions,
        );

        widget.onAddStory(story, isEditing: _isEditing);

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في توليد العناصر: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }
}